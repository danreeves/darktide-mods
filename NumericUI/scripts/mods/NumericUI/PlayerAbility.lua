local mod = get_mod("NumericUI")
local HudElementPlayerAbilitySettings =
	require("scripts/ui/hud/elements/player_ability/hud_element_player_ability_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local math_floor = math.floor
local string_format = string.format
local table_clone = table.clone

local style = table_clone(UIFontSettings.hud_body)
style.text_horizontal_alignment = "center"
style.text_vertical_alignment = "center"

style.font_size = mod:get("ability_cooldown_font_size")

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

local function _update_cooldown_text(self)
	local text_widget = self._widgets_by_name.cooldown_timer

	if not text_widget then
		return
	end

	local content = text_widget.content
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

mod:hook_safe("HudElementPlayerAbility", "_set_progress", function(self)
	local progress = self._ability_progress

	if mod.setting("disable_ability_background_progress") and progress < 1.0 then
		self._widgets_by_name.ability.content.duration_progress = 0.0
	end

	_update_cooldown_text(self)
end)

mod:hook_safe("HudElementPlayerAbility", "_set_widget_state_colors", function(self)
	_update_cooldown_text(self)
end)
