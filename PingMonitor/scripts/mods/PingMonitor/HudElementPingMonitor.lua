local mod = get_mod("PingMonitor")

local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local HudElementPingMonitor = class("HudElementPingMonitor", "HudElementBase")

-- Created once at load, the renderer only reads it
local NO_DATA_COLOR = Color.white(255, true)

local scenegraph_definition = {
	screen = UIWorkspaceSettings.screen,
	ping_panel = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = { 75, 25 },
		position = { 0, 12, 1001 },
	},
}

local widget_definitions = {
	ping_monitor = UIWidget.create_definition({
		{
			pass_type = "texture",
			value = "content/ui/materials/symbols/new_item_indicator",
			style_id = "ping_icon",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "left",
				color = Color.online_green(255, true),
				offset = { -40, 0, 0 },
				size = { 100, 100 },
			},
		},
		{
			pass_type = "text",
			value_id = "ping_text",
			style_id = "ping_text",
			style = {
				vertical_alignment = "center",
				text_vertical_alignment = "center",
				horizontal_alignment = "left",
				text_horizontal_alignment = "left",
				offset = { 30, 0, 0 },
				size = { 100, 100 },
				text_color = Color.online_green(255, true),
			},
		},
	}, "ping_panel"),
}

HudElementPingMonitor.init = function(self, parent, draw_layer, start_scale)
	HudElementPingMonitor.super.init(self, parent, draw_layer, start_scale, {
		scenegraph_definition = scenegraph_definition,
		widget_definitions = widget_definitions,
	})
end

HudElementPingMonitor.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementPingMonitor.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	local ping = mod.ping
	local ping_widget = self._widgets_by_name.ping_monitor
	local color
	-- No valid sample since the last game state change, e.g. local-hosted games never take one
	if ping then
		color = mod.ping_color(mod.jitter, ping)
		ping_widget.content.ping_text = ping
	else
		color = NO_DATA_COLOR
		ping_widget.content.ping_text = ""
	end
	ping_widget.style.ping_text.text_color = color
	ping_widget.style.ping_icon.color = color
	ping_widget.dirty = true
end

return HudElementPingMonitor
