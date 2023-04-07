local mod = get_mod("DodgeTrainer")

local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local size = { 75, 35 }
local scenegraph_definition = {
	screen = UIWorkspaceSettings.screen,
	container = {
		parent = "screen",
		scale = "fit",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = size,
		position = { 150, 150, 10 },
	},
}

local text_style = {
	line_spacing = 1.2,
	font_size = 25,
	drop_shadow = true,
	font_type = "calibri",
	font_type = "proxima_nova_bold",
	text_color = Color.white(255, true),
	size = size,
	text_horizontal_alignment = "center",
	text_vertical_alignment = "center",
}
local widget_definitions = {
	time_between = UIWidget.create_definition(
		{ {
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			style = text_style,
		} },
		"container"
	),
}

local HudElementDodgeTrainer = class("HudElementDodgeTrainer", "HudElementBase")

HudElementDodgeTrainer.init = function(self, parent, draw_layer, start_scale)
	HudElementDodgeTrainer.super.init(self, parent, draw_layer, start_scale, {
		scenegraph_definition = scenegraph_definition,
		widget_definitions = widget_definitions,
	})
end

HudElementDodgeTrainer.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementDodgeTrainer.super.update(self, dt, t, ui_renderer, render_settings, input_service)

	-- local unit_data_extension = self._unit_data_extension
	local style = self._widgets_by_name.time_between.style
	local content = self._widgets_by_name.time_between.content

	-- Reset to empty in case we can't fill it in
	content.text = ""

	local min = mod:get("min_time")
	local max = mod:get("max_time")
	local max_cutoff = mod:get("max_cutoff")
	local time_between = mod.time_between
	local p = math.clamp(math.ilerp(min, max, time_between), 0, 1)
	local color = Color.lerp(Color.ui_green_light(), Color.ui_red_light(), p)
	local _, r, g, b = Quaternion.to_elements(color)

	if time_between and time_between <= max_cutoff and p <= 1 and p >= 0 then
		content.text = string.format("%.2fs", mod.time_between)
		style.text.text_color[2] = r
		style.text.text_color[3] = g
		style.text.text_color[4] = b
	end
end

mod.time_between = 0
mod.exit_time = 0

local function on_enter(_self, _unit, _dt, t, _previous_state, _params)
	mod.time_between = t - mod.exit_time
	mod.exit_time = 0
end

local function on_exit(_self, _unit, t, _next_state)
	mod.exit_time = t
end

mod:hook_safe("PlayerCharacterStateDodging", "on_enter", on_enter)
mod:hook_safe("PlayerCharacterStateDodging", "on_exit", on_exit)

mod:hook_safe("PlayerCharacterStateSliding", "on_enter", on_enter)
mod:hook_safe("PlayerCharacterStateSliding", "on_exit", on_exit)

mod:hook_safe("PlayerCharacterStateSprinting", "on_enter", function(...)
	if mod:get("include_sprinting") then
		on_enter(...)
	end
end)
mod:hook_safe("PlayerCharacterStateSprinting", "on_exit", function(...)
	if mod:get("include_sprinting") then
		on_exit(...)
	end
end)

return HudElementDodgeTrainer
