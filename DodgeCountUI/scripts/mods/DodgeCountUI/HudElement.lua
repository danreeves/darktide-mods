local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local scenegraph_definition = {
	screen = UIWorkspaceSettings.screen,
}

local widget_definitions = {
	dodge_count = UIWidget.create_definition(
		{ {
			value_id = "text",
			pass_type = "text",
			style = table.clone(UIFontSettings.hud_body),
		} },
		"screen"
	),
}

local DodgeCountUI = class("DodgeCountUI", "HudElementBase")

DodgeCountUI.init = function(self, parent, draw_layer, start_scale, definitions)
	mod:echo("init")
	DodgeCountUI.super.init(self, parent, draw_layer, start_scale, {
		scenegraph_definition = scenegraph_definition,
		widget_definitions = widget_definitions,
	})

	local player_manager = Managers.player
	local player = player_manager:local_player(1)
	local player_unit = player.player_unit
	self._player_unit = player_unit
end

DodgeCountUI.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	DodgeCountUI.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	mod:echo("update")
	local unit_data_extension = ScriptUnit.extension(self._player_unit, "unit_data_system")
	local dodge_state_component = unit_data_extension:read_component("dodge_character_state")
	self._widgets_by_name.dodge_count.content.text = string.format(
		"dodge: %d",
		dodge_state_component.consecutive_dodges or 1
	)
end

mod:echo("ui required")
return DodgeCountUI
