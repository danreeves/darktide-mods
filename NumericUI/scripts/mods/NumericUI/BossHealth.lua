local mod = get_mod("NumericUI")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")

local math_min = math.min
local math_round = math.round
local table_clone = table.clone
local table_merge_recursive = table.merge_recursive
local tostring = tostring

local text_size = 20
local text_width = 100
local padding = 10

local text_style = {
	horizontal_alignment = "right",
	vertical_alignment = "center",
	text_horizontal_alignment = "left",
	text_vertical_alignment = "center",
	size = { text_width, text_size },
	font_size = text_size,
	font_type = "machine_medium",
	offset = { text_width + padding, 0, 100 },
	-- debug_draw_box = true,
}

local health_text_style = table_merge_recursive(table_clone(text_style), {
	text_color = {
		255,
		255,
		0,
		0,
	},
	offset = {
		[2] = -13,
	},
})

local toughness_text_style = table_merge_recursive(table_clone(text_style), {
	text_color = UIHudSettings.color_tint_secondary_1,
	offset = {
		[2] = -2,
	},
})

local left_health_text_style = table_merge_recursive(table_clone(health_text_style), {
	horizontal_alignment = "left",
	text_horizontal_alignment = "right",
	offset = { [1] = -(text_width + padding) },
})

local left_toughness_text_style = table_merge_recursive(table_clone(toughness_text_style), {
	horizontal_alignment = "left",
	text_horizontal_alignment = "right",
	offset = { [1] = -(text_width + padding) },
})

mod:hook_require("scripts/ui/hud/elements/boss_health/hud_element_boss_health_definitions", function(instance)
	instance.single_target_widget_definitions.health_text = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			value = "",
			style = health_text_style,
		},
	}, "health_bar")
	instance.single_target_widget_definitions.toughness_text = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			value = "",
			style = toughness_text_style,
		},
	}, "toughness_bar")

	instance.right_double_target_widget_definitions.health_text = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			value = "",
			style = health_text_style,
		},
	}, "health_bar")
	instance.right_double_target_widget_definitions.toughness_text = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			value = "",
			style = toughness_text_style,
		},
	}, "toughness_bar")

	instance.left_double_target_widget_definitions.health_text = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			value = "",
			style = left_health_text_style,
		},
	}, "health_bar")
	instance.left_double_target_widget_definitions.toughness_text = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			value = "",
			style = left_toughness_text_style,
		},
	}, "toughness_bar")
end)

local function _get_network_values(game_session, game_object_id)
	local toughness_damage = GameSession.game_object_field(game_session, game_object_id, "toughness_damage")
	local max_toughness = GameSession.game_object_field(game_session, game_object_id, "toughness")

	return toughness_damage, max_toughness
end

local function _set_number(widget, value)
	local content = widget.content

	if content._numericui_value ~= value then
		content._numericui_value = value
		content.text = value and tostring(value) or ""
		widget.dirty = true
	end
end

mod:hook_safe("HudElementBossHealth", "update", function(self)
	if not mod.setting("show_boss_health_numbers") then
		return
	end

	local widget_groups = self._widget_groups
	local active_targets_array = self._active_targets_array
	local num_active_targets = math_min(#widget_groups - 1, #active_targets_array)

	for i = 1, num_active_targets do
		local widget_group_index = num_active_targets > 1 and i + 1 or i
		local widget_group = widget_groups[widget_group_index]
		local target = active_targets_array[i]
		local unit = target.unit

		if ALIVE[unit] then
			local health_extension = target.health_extension

			_set_number(widget_group.health_text, math_round(health_extension:current_health()))

			local toughness_extension = target.toughness_extension

			if toughness_extension then
				local current_toughness

				if toughness_extension.max_toughness then
					-- MinionToughnessExtension
					local max_toughness = toughness_extension:max_toughness()
					local toughness_damage = toughness_extension:toughness_damage()
					current_toughness = max_toughness - toughness_damage
				else
					-- MinionToughnessHuskExtension
					local toughness_damage, max_toughness =
						_get_network_values(toughness_extension._game_session, toughness_extension._game_object_id)
					current_toughness = max_toughness - toughness_damage
				end

				_set_number(widget_group.toughness_text, math_round(current_toughness))
			else
				_set_number(widget_group.toughness_text, nil)
			end
		else
			_set_number(widget_group.health_text, nil)
			_set_number(widget_group.toughness_text, nil)
		end
	end
end)
