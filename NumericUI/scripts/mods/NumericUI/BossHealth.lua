local mod = get_mod("NumericUI")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")

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

local health_text_style = table.merge_recursive(table.clone(text_style), {
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

local toughness_text_style = table.merge_recursive(table.clone(text_style), {
	text_color = UIHudSettings.color_tint_secondary_1,
	offset = {
		[2] = -2,
	},
})

local left_health_text_style = table.merge_recursive(table.clone(health_text_style), {
	horizontal_alignment = "left",
	text_horizontal_alignment = "right",
	offset = { [1] = -(text_width + padding) },
})

local left_toughness_text_style = table.merge_recursive(table.clone(toughness_text_style), {
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

function _get_network_values(game_session, game_object_id)
	local toughness_damage = GameSession.game_object_field(game_session, game_object_id, "toughness_damage")
	local max_toughness = GameSession.game_object_field(game_session, game_object_id, "toughness")

	return toughness_damage, max_toughness
end

mod:hook_safe("HudElementBossHealth", "update", function(self)
	if mod:get("show_boss_health_numbers") then
		local widget_groups = self._widget_groups
		local active_targets_array = self._active_targets_array
		local num_active_targets = #active_targets_array

		for i = 1, num_active_targets do
			local widget_group_index = num_active_targets > 1 and i + 1 or i
			local widget_group = widget_groups[widget_group_index]
			local target = active_targets_array[i]
			local unit = target.unit

			widget_group.health_text.content.text = ""
			widget_group.toughness_text.content.text = ""

			if ALIVE[unit] then
				local health_extension = target.health_extension
				local current_health = health_extension:current_health()

				widget_group.health_text.content.text = math.round(current_health)

				local toughness_extension = target.toughness_extension
				local current_toughness = 0
				if toughness_extension then
					if toughness_extension.max_toughness then
						-- MinionToughnessExtension
						local max_toughness = toughness_extension:max_toughness()
						local toughness_damage = toughness_extension:toughness_damage()
						current_toughness = max_toughness - toughness_damage
					else
						-- MinionToughnessHuskExtension
						local toughness_damage, max_toughness = _get_network_values(
							toughness_extension._game_session,
							toughness_extension._game_object_id
						)
						current_toughness = max_toughness - toughness_damage
					end
					widget_group.toughness_text.content.text = math.round(current_toughness)
				end
			end
		end
	end
end)
