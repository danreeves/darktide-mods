require("scripts/foundation/utilities/color")

local mod = get_mod("Clock")
local UISettings = require("scripts/settings/ui/ui_settings")

local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local HudElementClock = class("HudElementClock", "HudElementBase")

local size = { 85, 25 }
local scenegraph_definition = {
	screen = UIWorkspaceSettings.screen,
	container = {
		parent = "screen",
		scale = "fit",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = size,
		position = {
			(UIWorkspaceSettings.screen.size[1] / 2) - size[1],
			(UIWorkspaceSettings.screen.size[2] / 2) - size[2],
			10,
		},
	},
}
local widget_definitions = {
	clock = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			style = {
				text_color = Color[mod:get("color")](255, true),
				line_spacing = 1.2,
				font_size = mod:get("font_size") or 25,
				drop_shadow = true,
				font_type = mod:get("font") or "machine_medium",
				size = { 20000, 25 },
				text_horizontal_alignment = "left",
				text_vertical_alignment = "center",
				horizontal_alignment = "left",
				vertical_alignment = "middle",
			},
		},
	}, "container"),
}

HudElementClock.init = function(self, parent, draw_layer, start_scale)
	HudElementClock.super.init(self, parent, draw_layer, start_scale, {
		scenegraph_definition = scenegraph_definition,
		widget_definitions = widget_definitions,
	})
end

HudElementClock.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementClock.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	local hours = mod:get("twentyfour_hour") and "H" or "I"
	local time = os.date("%" .. hours .. ":%M:%S")
	local symbols_text = ""

	for c in time:gmatch(".") do
		local number = tonumber(c)
		local symbol = UISettings.digital_clock_numbers[number]
		if symbol then
			symbols_text = symbols_text .. symbol
		else
			symbols_text = symbols_text .. ":"
		end
	end

	self._widgets_by_name.clock.style.text.font_size = mod:get("font_size") or 25
	self._widgets_by_name.clock.style.text_color = Color[mod:get("color")](255, true)
	self._widgets_by_name.clock.style.font_type = mod:get("font") or "machine_medium"
	self._widgets_by_name.clock.content.text = mod:get("digital_clock") and symbols_text or time
end

return HudElementClock
