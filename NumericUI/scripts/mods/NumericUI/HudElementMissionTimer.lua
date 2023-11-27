local mod = get_mod("NumericUI")

local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local font_size = 24
local size = { 60, font_size }
local scenegraph_definition = {
	screen = UIWorkspaceSettings.screen,
	container = {
		parent = "screen",
		scale = "fit",
		vertical_alignment = "bottom",
		horizontal_alignment = "right",
		size = size,
		position = { 0, 0, 200 },
	},
}

local style = {
	line_spacing = 1.2,
	font_size = font_size,
	drop_shadow = true,
	font_type = "machine_medium",
	text_color = Color.terminal_text_header(255, true),
	size = size,
	text_horizontal_alignment = "center",
	text_vertical_alignment = "center",
}
local widget_definitions = {
	timer = UIWidget.create_definition(
		{ {
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			style = style,
		} },
		"container"
	),
}

local HudElementMissionTimer = class("HudElementMissionTimer", "HudElementBase")

HudElementMissionTimer.init = function(self, parent, draw_layer, start_scale)
	HudElementMissionTimer.super.init(self, parent, draw_layer, start_scale, {
		scenegraph_definition = scenegraph_definition,
		widget_definitions = widget_definitions,
	})

	self._is_in_hub = mod._is_in_hub()
end

HudElementMissionTimer._disp_time = function(time)
	local minutes = math.floor(math.fmod(time, 3600) / 60)
	local seconds = math.floor(math.fmod(time, 60))
	return string.format("%02d:%02d", minutes, seconds)
end

HudElementMissionTimer.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementMissionTimer.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	local enabled = mod:get("show_mission_timer")
	local active = not mod:get("mission_timer_in_overlay")
	local content = self._widgets_by_name.timer.content
	local gameplay_input_service = Managers.input:get_input_service("Ingame")

	if gameplay_input_service:get("tactical_overlay_hold") then
		active = true
	end

	if enabled and active and not self._is_in_hub then
		content.text = self._disp_time(Managers.time:time("gameplay"))
	else
		content.text = ""
	end
end

return HudElementMissionTimer
