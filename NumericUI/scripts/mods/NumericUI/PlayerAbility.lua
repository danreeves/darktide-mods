local mod = get_mod("NumericUI")
local HudElementPlayerAbilitySettings =
	require("scripts/ui/hud/elements/player_ability/hud_element_player_ability_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local style = table.clone(UIFontSettings.hud_body)
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

mod:hook_safe("HudElementPlayerAbility", "update", function(self)
	local widgets_by_name = self._widgets_by_name
	local ability_widget = widgets_by_name.ability
	local text_widget = widgets_by_name.cooldown_timer
	local ability_cooldown_format = mod:get("ability_cooldown_format")

	local progress = self._ability_progress
	local on_cooldown = self._on_cooldown

	if text_widget then
		local percent = progress * 100
		if not on_cooldown or progress >= 1 then
			text_widget.content.text = " "
		else
			if ability_cooldown_format == "percent" then
				text_widget.content.text = string.format("%d%%", percent)
			elseif ability_cooldown_format == "time" then
				local player = self._data.player
				local player_unit = player.player_unit
				local unit_data_extension = ScriptUnit.extension(player_unit, "unit_data_system")
				local ability_state_component = unit_data_extension:read_component("combat_ability")
				local time = Managers.time:time("gameplay")
				local time_remaining = ability_state_component.cooldown - time
				if time_remaining <= 1 then
					text_widget.content.text = string.format("%.1f", time_remaining)
				else
					text_widget.content.text = string.format("%d", time_remaining)
				end
			else
				text_widget.content.text = " "
			end
		end
		text_widget.dirty = true
	end

	if mod:get("disable_ability_background_progress") then
		if progress < 1.0 then
			ability_widget.content.duration_progress = 0.0
		end
	end
end)
