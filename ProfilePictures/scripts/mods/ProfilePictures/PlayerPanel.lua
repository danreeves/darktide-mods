local mod = get_mod("ProfilePictures")
local UIWidget = require("scripts/managers/ui/ui_widget")

local function _load_portrait_icon(self)
	local player = self._player
	local player_info = mod.player_info_for_player(player)
	mod.load_profile_image(player_info, function(texture)
		local widget = self._widgets_by_name.player_icon
		if widget then
			local style = widget.style.profile
			if style then
				local material_values = style.material_values
				material_values.texture_map = texture
				widget.dirty = true
			end
		end
	end)
end

local hud_types = {
	"PersonalPlayerPanel",
	"PersonalPlayerPanelHub",
	"TeamPlayerPanel",
	"TeamPlayerPanelHub",
}

for _, hud_type in ipairs(hud_types) do
	mod:hook_safe("HudElement" .. hud_type, "_load_portrait_icon", _load_portrait_icon)
end

local function _cb_set_player_frame(self, item)
	if self.__deleted then
		return
	end

	local icon = nil

	if item.icon then
		icon = item.icon
	else
		icon = "content/ui/textures/nameplates/portrait_frames/default"
	end

	local widget = self._widgets_by_name.player_icon
	if widget.style.frame then
		local material_values = widget.style.frame.material_values
		material_values.texture_map = icon
		widget.dirty = true
	end
end

for _, hud_type in ipairs(hud_types) do
	mod:hook_safe("HudElement" .. hud_type, "_cb_set_player_frame", _cb_set_player_frame)
end

local function modify_player_icon_widget(instance)
	local scenegraph_definition = instance.scenegraph_definition
	local panel_size = scenegraph_definition.player_icon.size
	local size = {
		panel_size[1] - 20,
		panel_size[2] - 20,
	}
	if not instance.widget_definitions.player_icon.content.frame then
		UIWidget.add_definition_pass(instance.widget_definitions.player_icon, {
			style_id = "frame",
			value_id = "frame",
			pass_type = "texture",
			style = {
				material_values = {
					use_placeholder_texture = 0,
					texture_map = "content/ui/textures/nameplates/portrait_frames/default",
				},
				color = {
					255,
					255,
					255,
					255,
				},
				offset = {
					0,
					0,
					10,
				},
			},
			visibility_function = function(_content, style)
				if style.material_values.texture_map then
					return true
				end

				return false
			end,
		})
		UIWidget.add_definition_pass(instance.widget_definitions.player_icon, {
			style_id = "profile",
			value_id = "profile",
			pass_type = "texture",
			style = {
				material_values = {
					use_placeholder_texture = 0,
				},
				color = {
					255,
					255,
					255,
					255,
				},
				offset = {
					10,
					10,
					1,
				},
				size = size,
			},
			visibility_function = function(_content, style)
				if style.material_values.texture_map then
					return true
				end

				return false
			end,
		})
	end
end

local definitions = {
	"scripts/ui/hud/elements/personal_player_panel_hub/hud_element_personal_player_panel_definitions",
	"scripts/ui/hud/elements/personal_player_panel_hub/hud_element_personal_player_panel_hub_definitions",
	"scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions",
	"scripts/ui/hud/elements/team_player_panel_hub/hud_element_team_player_panel_hub_definitions",
}

for _, definition in ipairs(definitions) do
	mod:hook_require(definition, modify_player_icon_widget)
end
