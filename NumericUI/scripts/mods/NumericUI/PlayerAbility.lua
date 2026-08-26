local mod = get_mod("NumericUI")
local HudElementPlayerAbilitySettings =
	require("scripts/ui/hud/elements/player_ability/hud_element_player_ability_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local math_floor = math.floor
local math_huge = math.huge
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

local function _remaining_cooldown(self)
	local parent = self._parent
	local player = self._data and self._data.player

	if not parent or not player then
		return
	end

	local ability_extension = parent:get_player_extension(player, "ability_system")

	if not ability_extension then
		return
	end

	local remaining = ability_extension:remaining_ability_cooldown(self._ability_id)

	if not remaining or remaining == math_huge then
		return
	end

	return remaining
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
