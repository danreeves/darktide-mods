require("scripts/foundation/utilities/color")

local ScriptGui = require("scripts/foundation/utilities/script_gui")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local HudElementLuaGCInfo = class("HudElementLuaGCInfo", "HudElementBase")

local fps = GameParameters.tick_rate or 60
local time_window = 5

local size = { 200, 600 }
local scenegraph_definition = {
	screen = UIWorkspaceSettings.screen,
	container = {
		parent = "screen",
		scale = "fit",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = size,
		position = {
			0,
			0,
			10,
		},
	},
}
local widget_definitions = {
	gc_info = UIWidget.create_definition({
		{
			value_id = "memory_total",
			style_id = "memory_total",
			pass_type = "text",
			style = {
				text_color = Color.white(255, true),
				line_spacing = 1.1,
				font_size = 25,
				drop_shadow = true,
				font_type = "arial",
				size = { 20000, 25 },
				text_horizontal_alignment = "left",
				text_vertical_alignment = "top",
				horizontal_alignment = "left",
				vertical_alignment = "top",
				offset = { 5, 5, 0 },
			},
		},
	}, "container"),
}

HudElementLuaGCInfo.init = function(self, parent, draw_layer, start_scale)
	HudElementLuaGCInfo.super.init(self, parent, draw_layer, start_scale, {
		scenegraph_definition = scenegraph_definition,
		widget_definitions = widget_definitions,
	})
	self._memory_over_time = {}
	self._garbage_over_time = {}
	self._max_memory = 0
end

local function scale_between(unscaledNum, minAllowed, maxAllowed, min, max)
	return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed
end

local graph_height = 155
local margin_top = 10
local margin_right = 5
local graph_font_size = 10
HudElementLuaGCInfo.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementLuaGCInfo.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	local current_memory, estimated_garbage, percent_garbage, estimated_collection_time, total_gc_time, gc_cycle_total_time =
		Profiler.lua_stats()

	self._widgets_by_name.gc_info.content.memory_total = string.format(
		"Memory: %d KB\nGarbage: %d KB\nPercent garbage: %.2f%%\nEstimated GC time: %.2f ms\nActual GC time: %.2f ms\nFull GC cycle: %.2f ms",
		current_memory,
		estimated_garbage,
		percent_garbage,
		estimated_collection_time,
		total_gc_time,
		gc_cycle_total_time
	)

	table.insert(self._memory_over_time, 1, current_memory)
	table.remove(self._memory_over_time, fps * time_window + 1)
	table.insert(self._garbage_over_time, 1, estimated_garbage)
	table.remove(self._garbage_over_time, fps * time_window + 1)

	self._max_memory = math.max(self._max_memory, current_memory)
	-- local max_memory = get_max(self._memory_over_time)
	local gui = ui_renderer.gui

	-- for i = #self._memory_over_time, 1, -1 do
	for i = 1, #self._memory_over_time do
		local start_val = self._memory_over_time[i]
		local end_val = self._memory_over_time[i - 1]
		if start_val and end_val then
			local start_scaled = scale_between(start_val, 0, graph_height, 0, self._max_memory)
			local end_scaled = scale_between(end_val, 0, graph_height, 0, self._max_memory)
			local start_pos = Vector3(350 - i + fps * time_window, graph_height + margin_top - start_scaled, 1)
			local end_pos = Vector3(350 - i + 1 + fps * time_window, graph_height + margin_top - end_scaled, 1)
			ScriptGui.hud_line(gui, start_pos, end_pos, 1000, 1, Color.online_green())
			if i == 2 then
				ScriptGui.text(
					gui,
					string.format("%d KB", start_val),
					"content/ui/fonts/arial",
					graph_font_size,
					Vector3(
						350 + fps * time_window + margin_right,
						graph_height + margin_top - start_scaled - graph_font_size / 2,
						0
					),
					Color.online_green(),
					Color.black()
				)
			end
		end
	end

	-- for i = #self._garbage_over_time, 1, -1 do
	for i = 1, #self._garbage_over_time do
		local start_val = self._garbage_over_time[i]
		local end_val = self._garbage_over_time[i - 1]
		if start_val and end_val then
			local start_scaled = scale_between(start_val, 0, graph_height, 0, self._max_memory)
			local end_scaled = scale_between(end_val, 0, graph_height, 0, self._max_memory)
			local start_pos = Vector3(350 - i + fps * time_window, graph_height + margin_top - start_scaled, 1)
			local end_pos = Vector3(350 - i + 1 + fps * time_window, graph_height + margin_top - end_scaled, 1)
			ScriptGui.hud_line(gui, start_pos, end_pos, 1000, 1, Color.ui_interaction_critical())
			if i == 2 then
				ScriptGui.text(
					gui,
					string.format("%d KB", start_val),
					"content/ui/fonts/arial",
					graph_font_size,
					Vector3(
						350 + fps * time_window + margin_right,
						graph_height + margin_top - start_scaled - graph_font_size / 2,
						0
					),
					Color.ui_interaction_critical(),
					Color.black()
				)
			end
		end
	end

	ScriptGui.hud_line(
		gui,
		Vector3(350, margin_top, 0),
		Vector3(350 + fps * time_window, margin_top, 0),
		1000,
		1,
		Color.white()
	)
	ScriptGui.text(
		gui,
		string.format("%d KB", self._max_memory),
		"content/ui/fonts/arial",
		graph_font_size,
		Vector3(350 + fps * time_window + margin_right, margin_top - graph_font_size / 2, 0),
		Color.white()
	)

	ScriptGui.hud_line(
		gui,
		Vector3(350, graph_height + margin_top, 0),
		Vector3(350 + fps * time_window, graph_height + margin_top, 0),
		1000,
		1,
		Color.white()
	)
end

return HudElementLuaGCInfo
