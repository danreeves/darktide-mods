-- Show ammo amount from packs and tins
-- Description: Display numeric amount of ammo gained by ammo pack/tin, as well as amount lost due to overfill.
-- Author: groundskeeper Willie, raindish
local mod = get_mod("NumericUI")

local Pickups = require("scripts/settings/pickup/pickups")
local Ammo = require("scripts/utilities/ammo")

local string_format = string.format
local pairs = pairs

local small_clip_data = Pickups.by_name["small_clip"]
local large_clip_data = Pickups.by_name["large_clip"]

local SMALL_CLIP_DESCRIPTION = "loc_pickup_consumable_small_clip_01"
local LARGE_CLIP_DESCRIPTION = "loc_pickup_consumable_large_clip_01"

local function _havoc_ammo_modifier()
	local cached = mod._havoc_ammo_modifier

	if cached then
		return cached
	end

	local modifier = 1
	local game_mode_manager = Managers.state.game_mode
	local game_mode = game_mode_manager and game_mode_manager:game_mode()
	local havoc_extension = game_mode and game_mode.extension and game_mode:extension("havoc")

	if havoc_extension then
		modifier = havoc_extension:get_modifier_value("ammo_pickup_modifier") or 1
	end

	mod._havoc_ammo_modifier = modifier

	return modifier
end

local function _weapon_ammo_totals(player_unit)
	local unit_data_extension = ScriptUnit.has_extension(player_unit, "unit_data_system")
	local visual_loadout_extension = ScriptUnit.has_extension(player_unit, "visual_loadout_system")

	if not unit_data_extension or not visual_loadout_extension then
		return
	end

	local weapon_slot_configuration = visual_loadout_extension:slot_configuration_by_type("weapon")

	for slot_name in pairs(weapon_slot_configuration) do
		local wieldable_component = unit_data_extension:read_component(slot_name)

		if wieldable_component and wieldable_component.max_ammunition_reserve > 0 then
			return Ammo.current_ammo_in_reserve(wieldable_component),
				Ammo.max_ammo_in_reserve(wieldable_component),
				Ammo.current_ammo_in_clips(wieldable_component),
				Ammo.max_ammo_in_clips(wieldable_component)
		end
	end
end

local function _pickup_gain(pickup_data, max_ammo_reserve, max_ammo_clip, ammo_modifier)
	local previous_modifier = pickup_data.modifier

	pickup_data.modifier = ammo_modifier

	local gain = pickup_data.ammo_amount_func(max_ammo_reserve, max_ammo_clip, pickup_data)

	pickup_data.modifier = previous_modifier

	return gain
end

local function _update_pickup_description(self, interactor_extension)
	local description_widget = self._widgets_by_name.description_text
	local base_text = self._numericui_pickup_base_text
	local hud_description = self._numericui_pickup_hud_description

	if not description_widget or not base_text then
		return
	end

	if hud_description ~= SMALL_CLIP_DESCRIPTION and hud_description ~= LARGE_CLIP_DESCRIPTION then
		return
	end

	local player = Managers.player:local_player(1)
	local player_unit = player and player.player_unit

	if not player_unit then
		return
	end

	local ammo_reserve, max_ammo_reserve, ammo_clip, max_ammo_clip = _weapon_ammo_totals(player_unit)

	if not ammo_reserve then
		return
	end

	local ammo_modifier = _havoc_ammo_modifier()
	local pickup_data = hud_description == SMALL_CLIP_DESCRIPTION and small_clip_data or large_clip_data
	local clip_gain = _pickup_gain(pickup_data, max_ammo_reserve, max_ammo_clip, ammo_modifier)

	local max_ammo = max_ammo_reserve + max_ammo_clip
	local current_ammo = ammo_clip + ammo_reserve
	local missing_ammo = max_ammo - current_ammo
	local ammo_gain = 0
	local ammo_wasted = 0

	if missing_ammo >= clip_gain then
		ammo_gain = clip_gain
	elseif missing_ammo > 0 then
		ammo_gain = missing_ammo
		ammo_wasted = clip_gain - missing_ammo
	end

	local show_ammo_gain = ammo_gain > 0
	local show_ammo_wasted = ammo_wasted > 0

	local desc_str = show_ammo_gain
			and show_ammo_wasted
			and "%s {#color(0,255,0,200);}(+%d) {#color(255,0,0,200);}(%d)"
		or show_ammo_gain and not show_ammo_wasted and "%s {#color(0,255,0,200);}(+%d)"
		or "%s"

	local text = string_format(desc_str, base_text, ammo_gain, ammo_wasted)

	if description_widget.content.text ~= text then
		description_widget.content.text = text
		description_widget.dirty = true
	end
end

mod:hook_safe(
	"HudElementInteraction",
	"_setup_interaction_information",
	function(self, _interactee_unit, _interactee_extension, interactor_extension, use_minimal_presentation)
	self._numericui_pickup_base_text = nil
	self._numericui_pickup_hud_description = nil

	if use_minimal_presentation or not mod.setting("show_ammo_amount_from_packs") then
		return
	end

	local hud_description = interactor_extension:hud_description()

	if hud_description ~= SMALL_CLIP_DESCRIPTION and hud_description ~= LARGE_CLIP_DESCRIPTION then
		return
	end

	local description_widget = self._widgets_by_name.description_text

	self._numericui_pickup_hud_description = hud_description
	self._numericui_pickup_base_text = description_widget and description_widget.content.text

	_update_pickup_description(self, interactor_extension)
	mod._pickup_preview_dirty = false
end)

mod:hook_safe("HudElementInteraction", "update", function(self)
	if not mod._pickup_preview_dirty then
		return
	end

	mod._pickup_preview_dirty = false

	local active_presentation_data = self._active_presentation_data

	if not active_presentation_data then
		return
	end

	_update_pickup_description(self, active_presentation_data.interactor_extension)
end)
