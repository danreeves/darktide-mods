local mod = get_mod("MinionStatus")

local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local template = {}
local size = {
	400,
	1,
}
template.size = size
template.name = "minion_status"
-- template.unit_node = "j_head"
template.unit_node = "root_node"
template.position_offset = {
	0,
	0,
	2.2,
}
template.check_line_of_sight = false
template.max_distance = math.huge
template.screen_clamp = false

template.create_widget_defintion = function(template, scenegraph_id)
	local size = template.size
	local header_font_setting_name = "hud_body"
	local header_font_settings = UIFontSettings[header_font_setting_name]
	local header_font_color = Color.white(255, true)

	return UIWidget.create_definition({
		{
			style_id = "header_text",
			pass_type = "text",
			value_id = "header_text",
			value = "<header_text>",
			style = {
				horizontal_alignment = "center",
				text_vertical_alignment = "center",
				text_horizontal_alignment = "left",
				vertical_alignment = "center",
				offset = {
					0,
					0,
					2,
				},
				font_type = header_font_settings.font_type,
				font_size = header_font_settings.font_size,
				default_font_size = header_font_settings.font_size,
				text_color = header_font_color,
				default_text_color = header_font_color,
				size = size,
			},
		},
	}, scenegraph_id)
end

template.on_enter = function(widget, marker)
	local content = widget.content

	content.header_text = "this is debug text yay"

	marker.draw = true
	marker.update = true
end

template.update_function = function(parent, ui_renderer, widget, marker, template, dt, t)
	local unit = marker.unit
	local content = widget.content

	marker.draw = true
	marker.update = true

	if not HEALTH_ALIVE[unit] then
		marker.remove = true
		return
	end

	local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
	local breed = unit_data_extension:breed()

	local suppression_extension = ScriptUnit.extension(unit, "suppression_system")
	local suppression = 0
	if suppression_extension then
		suppression = suppression_extension._suppression_component.suppress_value
	end

	local blackboard = BLACKBOARDS[unit]
	local behavior_component = blackboard.behavior
	local combat_range = behavior_component.combat_range
	local stagger_component = blackboard.stagger
	local stagger_count = stagger_component.count

	local behavior_system = ScriptUnit.extension(unit, "behavior_system")
	local brain = behavior_system._brain
	local running_action = brain:running_action()

	content.header_text = string.format(
		"unit: %s\nsuppression: %d\ncombat_range: %s\nstagger: %d\naction: %s",
		breed.name,
		suppression,
		combat_range,
		stagger_count,
		running_action
	)
end

return template
