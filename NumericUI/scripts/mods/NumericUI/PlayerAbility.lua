local mod = get_mod("NumericUI")
local HudElementPlayerAbilitySettings =
	require("scripts/ui/hud/elements/player_ability/hud_element_player_ability_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local FixedFrame = require("scripts/utilities/fixed_frame")
local ProjectileTemplates = require("scripts/settings/projectile/projectile_templates")
local StimmFieldCrateUnitTemplate =
	require("scripts/extension_systems/unit_templates/broker_stimm_field_crate_deployable_unit_template")
local TalentSettings = require("scripts/settings/talent/talent_settings")

local math_floor = math.floor
local next = next
local pairs = pairs
local rawget = rawget
local string_format = string.format
local table_clone = table.clone
local type = type

local ABILITY_COOLDOWN_FONT_SIZE_DEFAULT = 30
local ACTIVE_BUFF_SCAN_INTERVAL = 0.1
local CHORUS_ACTION_NAME = "action_zealot_channel"

-- Combat abilities whose action code adds their timed buff, so the ability settings don't name it. Only the buff
-- names live here; the remaining time is always read from the live buff. The Skitarius' Chordclaw is left out on
-- purpose: its 10 s buff only caps how long the claw can stay out, it is no lingering effect.
local ACTIVE_BUFFS_BY_ABILITY = {
	veteran_combat_ability_stance = {
		"veteran_combat_ability_stance_master",
		"veteran_combat_ability_stance_master_increased_duration",
	},
	veteran_combat_ability_stance_improved = {
		"veteran_combat_ability_stance_master",
		"veteran_combat_ability_stance_master_increased_duration",
	},
	veteran_combat_ability_stealth = { "veteran_invisibility" },
}

local style = table_clone(UIFontSettings.hud_body)
style.text_horizontal_alignment = "center"
style.text_vertical_alignment = "center"

style.font_size = mod:get("ability_cooldown_font_size") or ABILITY_COOLDOWN_FONT_SIZE_DEFAULT

-- selene: allow(global_usage)
mod:hook(_G, "dofile", function(func, path)
	local instance = func(path)
	if path == "scripts/ui/hud/elements/player_ability/hud_element_player_ability_vertical_definitions" then
		instance.scenegraph_definition.cooldown = {
			parent = "slot",
			vertical_alignment = "center",
			horizontal_alignment = "center",
			size = HudElementPlayerAbilitySettings.ability_size,
			position = {
				0,
				0,
				10,
			},
		}
		instance.widget_definitions.cooldown_timer = UIWidget.create_definition({
			{
				value_id = "text",
				style_id = "text",
				pass_type = "text",
				style = style,
			},
		}, "cooldown")
	end
	return instance
end)

local function _player_extension(self, system_name)
	local parent = self._parent
	local player = self._data and self._data.player

	if not parent or not player then
		return
	end

	return parent:get_player_extension(player, system_name)
end

local function _remaining_cooldown(self)
	local ability_extension = _player_extension(self, "ability_system")

	if not ability_extension then
		return
	end

	local buff_extension = _player_extension(self, "buff_system")

	return mod.ability_charge_time_remaining(ability_extension, buff_extension, self._ability_type)
end

-- regen progress of the next charge, or nil while regen is paused
local function _recharging_charge_progress(self)
	local ability_extension = _player_extension(self, "ability_system")
	local regen_progress_func = ability_extension and ability_extension.get_ability_resource_regen_progress
	local ability_type = self._ability_type

	if not regen_progress_func or ability_extension:is_ability_resource_regen_paused(ability_type) then
		return
	end

	return regen_progress_func(ability_extension, ability_type)
end

-- per ability name: the set of buff template names that carry its active effect, or false when it has none
local active_buff_names_by_ability = {}

local function _active_buff_names(ability)
	local ability_name = ability.name
	local buff_names = active_buff_names_by_ability[ability_name]

	if buff_names ~= nil then
		return buff_names
	end

	buff_names = {}

	-- the buff a stance-like ability applies, and the buff whose duration vanilla's own ability HUD tracks
	local tweak_data = ability.ability_template_tweak_data
	local buff_to_add = tweak_data and tweak_data.buff_to_add

	if buff_to_add then
		buff_names[buff_to_add] = true
	end

	local pause_cooldown_settings = ability.pause_cooldown_settings
	local duration_tracking_buff = pause_cooldown_settings and pause_cooldown_settings.duration_tracking_buff

	if type(duration_tracking_buff) == "table" then
		for i = 1, #duration_tracking_buff do
			buff_names[duration_tracking_buff[i]] = true
		end
	elseif duration_tracking_buff then
		buff_names[duration_tracking_buff] = true
	end

	local extra_buff_names = ACTIVE_BUFFS_BY_ABILITY[ability_name]

	if extra_buff_names then
		for i = 1, #extra_buff_names do
			buff_names[extra_buff_names[i]] = true
		end
	end

	if next(buff_names) == nil then
		buff_names = false
	end

	active_buff_names_by_ability[ability_name] = buff_names

	return buff_names
end

local function _find_active_buff(self)
	local buff_extension = _player_extension(self, "buff_system")

	if not buff_extension then
		return
	end

	local buff_names = self._numericui_active_buff_names
	local buffs = buff_extension:buffs()

	for i = 1, #buffs do
		local buff = buffs[i]

		if buff_names[buff:template_name()] then
			return buff
		end
	end
end

-- Read from the ability's live buff, so duration talents, extensions and early ends count exactly as the game counts
-- them
local function _buff_time_remaining(self, t)
	local buff = self._numericui_active_buff

	-- a deleted buff ended early or was replaced by a recast, so look for its successor straight away
	if buff and rawget(buff, "__deleted") then
		buff = nil
		self._numericui_active_buff = nil
		self._numericui_active_buff_scan_t = nil
	end

	if not buff then
		local scan_t = self._numericui_active_buff_scan_t

		if scan_t and t < scan_t then
			return
		end

		buff = _find_active_buff(self)
		self._numericui_active_buff = buff
		self._numericui_active_buff_scan_t = t + ACTIVE_BUFF_SCAN_INTERVAL

		if not buff then
			return
		end
	end

	-- Scrier's Gaze and Precision Stance have no duration; they end on peril or when their resource runs out
	local duration = buff:duration()

	if duration then
		return buff:start_time() + duration - t
	end
end

-- Chorus is a channel action, whose end time already includes any action speed change. Cancelling it ends it.
local function _chorus_time_remaining(self, t)
	local unit_data_extension = _player_extension(self, "unit_data_system")
	local weapon_action_component = unit_data_extension and unit_data_extension:read_component("weapon_action")

	if weapon_action_component and weapon_action_component.current_action_name == CHORUS_ACTION_NAME then
		return weapon_action_component.end_t - t
	end
end

-- Every Telekine Shield keeps its remaining duration on its own extension, synced to clients by the server. With
-- two up, the one deployed first runs out first.
local function _telekine_shield_time_remaining(self)
	local extension_manager = Managers.state.extension
	local force_field_system = extension_manager and extension_manager:system("force_field_system")
	local player = self._data.player
	local player_unit = player and player.player_unit

	if not force_field_system or not player_unit then
		return
	end

	local remaining

	for _, extension in pairs(force_field_system:unit_to_extension_map()) do
		if extension.owner_unit == player_unit then
			local shield_remaining = extension:remaining_duration()

			if shield_remaining and shield_remaining > 0 and (not remaining or shield_remaining < remaining) then
				remaining = shield_remaining
			end
		end
	end

	return remaining
end

-- The local player's Nuncio-Aquila drones and Stimm Field crates by unit, with the fixed time each one's lifetime
-- ends. Both lifetimes run on the server only, so the clock is started where the server starts it: when the drone
-- deploys and when the crate spawns. A client sees both slightly later than the server, so its timer is an estimate.
local drone_end_times = {}
local stimm_field_end_times = {}

local function _local_player_owner_unit(unit)
	local owner = Managers.state.player_unit_spawn:owner(unit)

	if owner and owner == Managers.player:local_player(1) then
		return owner.player_unit
	end
end

-- Seconds until the first of the tracked units runs out. A unit stays tracked while the local player owns it: the
-- game releases the ownership when the unit is destroyed, and every mission starts with a new spawn manager, so an
-- end time left over from an earlier mission's clock is dropped as well.
local function _tracked_time_remaining(end_times, t)
	local player_unit_spawn_manager = Managers.state.player_unit_spawn
	local local_player = Managers.player:local_player(1)
	local remaining

	for unit, end_t in pairs(end_times) do
		local unit_remaining = end_t - t

		if
			unit_remaining <= 0
			or not player_unit_spawn_manager
			or player_unit_spawn_manager:owner(unit) ~= local_player
		then
			end_times[unit] = nil
		elseif not remaining or unit_remaining < remaining then
			remaining = unit_remaining
		end
	end

	return remaining
end

local function _drone_time_remaining(_self, t)
	return _tracked_time_remaining(drone_end_times, t)
end

local function _stimm_field_time_remaining(_self, t)
	return _tracked_time_remaining(stimm_field_end_times, t)
end

local area_buff_drone = ProjectileTemplates.area_buff_drone
local area_buff_drone_deployable = area_buff_drone and area_buff_drone.deployable

if area_buff_drone_deployable and area_buff_drone_deployable.deploy_func then
	-- the server registers the drone's lifetime job here, and clients run the same function when they see it deploy
	mod:hook_safe(area_buff_drone_deployable, "deploy_func", function(_world, _physics_world, unit)
		if mod.setting("show_ability_active_timer") and _local_player_owner_unit(unit) then
			drone_end_times[unit] = FixedFrame.get_latest_fixed_time()
				+ TalentSettings.adamant.blitz_ability.drone.duration
		end
	end)
end

local function _track_stimm_field(unit)
	if not mod.setting("show_ability_active_timer") then
		return
	end

	local owner_unit = _local_player_owner_unit(unit)

	if not owner_unit then
		return
	end

	-- the life time ProximityBrokerStimmField.init picks
	local settings = TalentSettings.broker.combat_ability.stimm_field
	local talent_extension = ScriptUnit.has_extension(owner_unit, "talent_system")
	local life_time = talent_extension
			and talent_extension:has_special_rule("broker_stimm_field_linger")
			and settings.sub_1_life_time
		or settings.life_time

	stimm_field_end_times[unit] = FixedFrame.get_latest_fixed_time() + life_time
end

-- As the server, which registers the field's lifetime job when the crate has spawned
mod:hook_safe(StimmFieldCrateUnitTemplate, "local_unit_spawned", _track_stimm_field)

-- As a client
mod:hook_safe(StimmFieldCrateUnitTemplate, "husk_init", _track_stimm_field)

-- Combat abilities whose effect is no buff on the player
local ACTIVE_TIME_FUNCS = {
	zealot_relic = _chorus_time_remaining,
	psyker_force_field = _telekine_shield_time_remaining,
	psyker_force_field_improved = _telekine_shield_time_remaining,
	psyker_force_field_dome = _telekine_shield_time_remaining,
	adamant_area_buff_drone = _drone_time_remaining,
	broker_ability_stimm_field = _stimm_field_time_remaining,
}

-- How the equipped ability's active time is read. It is cached on the element, which the ability handler recreates
-- when the ability changes. Nil until the ability extension is ready, false for abilities without a timed effect.
local function _active_time_func(self)
	local time_func = self._numericui_active_time_func

	if time_func ~= nil then
		return time_func
	end

	local ability_extension = _player_extension(self, "ability_system")
	local ability = ability_extension and ability_extension:ability_is_equipped(self._ability_type)

	if not ability then
		return
	end

	time_func = ACTIVE_TIME_FUNCS[ability.name]

	if not time_func then
		local buff_names = _active_buff_names(ability)

		self._numericui_active_buff_names = buff_names
		time_func = buff_names and _buff_time_remaining or false
	end

	self._numericui_active_time_func = time_func

	return time_func
end

-- Seconds left on the combat ability's active effect, or nil when nothing is running
local function _active_time_remaining(self)
	local time_func = _active_time_func(self)
	local remaining = time_func and time_func(self, FixedFrame.get_latest_fixed_time())

	if remaining and remaining > 0 then
		return remaining
	end
end

local function _is_regen_paused(self)
	local ability_extension = _player_extension(self, "ability_system")

	return ability_extension ~= nil and ability_extension:is_ability_resource_regen_paused(self._ability_type)
end

local function _update_cooldown_text(self)
	local text_widget = self._widgets_by_name.cooldown_timer

	if not text_widget then
		return
	end

	-- the definition above reads the font size only when this file loads, so a changed setting is applied to the
	-- live widget here
	local font_size = mod.setting("ability_cooldown_font_size") or ABILITY_COOLDOWN_FONT_SIZE_DEFAULT
	local text_style = text_widget.style.text

	if text_style._numericui_font_size ~= font_size then
		text_style._numericui_font_size = font_size
		text_style.font_size = font_size
		text_widget.dirty = true
	end

	local content = text_widget.content

	if mod.setting("show_ability_active_timer") then
		local active_time_remaining = _active_time_remaining(self)
		local time_func = self._numericui_active_time_func
		local needs_update_tick

		-- Vanilla only calls _set_progress while its progress moves. It stands still once the ability is ready, as
		-- when kills keep extending Volley Fire, and while regen is paused, as during Chorus or a Stimm Field, so
		-- mod.update keeps a running timer counting then. It also waits out a pause for an effect that isn't a buff,
		-- like a Stimm Field crate that a client only sees after the pause began.
		if active_time_remaining then
			needs_update_tick = (self._ability_progress or 0) >= 1 or _is_regen_paused(self)
		else
			needs_update_tick = time_func and time_func ~= _buff_time_remaining and _is_regen_paused(self)
		end

		if needs_update_tick then
			mod._ability_active_timer_element = self
		elseif mod._ability_active_timer_element == self then
			mod._ability_active_timer_element = nil
		end

		if active_time_remaining then
			-- tenths of a second, so a running ability reads differently from the whole-second cooldown after it
			local tenths = math_floor(active_time_remaining * 10)

			-- the cooldown text below must be rebuilt once the ability ends
			content._numericui_last_value = nil

			if content._numericui_last_active_value ~= tenths then
				content._numericui_last_active_value = tenths
				content.text = string_format("%.1f", tenths / 10)
				text_widget.dirty = true
			end

			return
		end

		content._numericui_last_active_value = nil
	end

	local progress = self._ability_progress
	local on_cooldown = self._on_cooldown
	-- new_text stays nil while the displayed value is unchanged, so the
	-- retained widget is only re-rendered when the text actually changes
	local new_text

	-- since Darktide 1.13.0 vanilla reports a multi-charge ability as ready while it has a
	-- charge left, so read the progress of the recharging charge from the ability itself
	if not on_cooldown and self._has_more_than_one_charge and self._has_charges_left then
		progress = _recharging_charge_progress(self)
		on_cooldown = progress ~= nil
	end

	if not on_cooldown or not progress or progress >= 1 then
		content._numericui_last_value = nil
		new_text = " "
	else
		local ability_cooldown_format = mod.setting("ability_cooldown_format")

		if ability_cooldown_format == "percent" then
			local percent = math_floor(progress * 100)
			if content._numericui_last_value ~= percent then
				content._numericui_last_value = percent
				new_text = string_format("%d%%", percent)
			end
		elseif ability_cooldown_format == "time" then
			local time_remaining = _remaining_cooldown(self)

			if not time_remaining then
				content._numericui_last_value = nil
				new_text = " "
			elseif time_remaining <= 1 then
				content._numericui_last_value = nil
				new_text = string_format("%.1f", time_remaining)
			else
				local seconds = math_floor(time_remaining)
				if content._numericui_last_value ~= seconds then
					content._numericui_last_value = seconds
					new_text = string_format("%d", seconds)
				end
			end
		else
			content._numericui_last_value = nil
			new_text = " "
		end
	end

	if new_text and content.text ~= new_text then
		content.text = new_text
		text_widget.dirty = true
	end
end

-- Called from mod.update while _update_cooldown_text has registered an element whose progress stands still
mod.update_ability_active_timer = function()
	local element = mod._ability_active_timer_element

	if rawget(element, "destroyed") or not mod.setting("show_ability_active_timer") then
		mod._ability_active_timer_element = nil

		return
	end

	_update_cooldown_text(element)
end

-- While regen is paused vanilla draws the ability as empty, even when a charge is ready again, as when Practiced
-- Deployment refunds the Stimm Supply while a Stimm Field still stands. Show the icon as ready then. Vanilla only
-- rewrites the progress when it changes, so this is re-checked whenever the ready state changes as well.
local function _update_paused_ready_progress(self)
	if self._ability_progress ~= 0 then
		return
	end

	local widget = self._widgets_by_name.ability
	local content = widget.content
	local duration_progress = not self._on_cooldown and _is_regen_paused(self) and 1 or 0

	if content.duration_progress ~= duration_progress then
		content.duration_progress = duration_progress
		widget.dirty = true
	end
end

mod:hook_safe("HudElementPlayerAbility", "_set_progress", function(self)
	local progress = self._ability_progress

	if mod.setting("disable_ability_background_progress") and progress < 1.0 then
		self._widgets_by_name.ability.content.duration_progress = 0.0
	end

	_update_paused_ready_progress(self)
	_update_cooldown_text(self)
end)

mod:hook_safe("HudElementPlayerAbility", "_set_widget_state_colors", function(self)
	_update_paused_ready_progress(self)
	_update_cooldown_text(self)
end)
