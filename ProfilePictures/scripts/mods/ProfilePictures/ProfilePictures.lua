local mod = get_mod("ProfilePictures")
local UIWidget = require("scripts/managers/ui/ui_widget")

local hud_types = {
	"PersonalPlayerPanel",
	"PersonalPlayerPanelHub",
	"TeamPlayerPanel",
	"TeamPlayerPanelHub",
}

local function _load_portrait_icon(self)
	local player = self._player
	local player_info = Managers.data_service.social:_get_player_info_for_player(player)
	local platform = player_info:platform()
	mod:echo(platform)
	if platform == "steam" then
		local xuid = Steam.id_hex_to_dec(player_info:platform_user_id())
		local url = "https://steam-profile-json.deno.dev/" .. xuid
		Managers.backend:url_request(url):next(function(profile_request)
			Managers.url_loader
				:load_texture(profile_request.body.profile.avatarFull)
				:next(function(data)
					self._profile_picture_texture = data.texture

					local widget = self._widgets_by_name.player_icon
					local material_values = widget.style.profile.material_values
					material_values.texture_map = data.texture
					widget.dirty = true
				end)
				:catch(function(error)
					-- mod:echo(cjson.encode(error))
				end)
		end)
	end

	if platform == "xbox" then
		local xuid = Steam.id_hex_to_dec(player_info:platform_user_id())
		local url = "https://xboxapi-workers.dnrvs.workers.dev/profiles/" .. xuid
		Managers.backend:url_request(url):next(function(profile_request)
			Managers.url_loader
				:load_texture(profile_request.body.gamerpic)
				:next(function(data)
					self._profile_picture_texture = data.texture

					local widget = self._widgets_by_name.player_icon
					local material_values = widget.style.profile.material_values
					material_values.texture_map = data.texture
					widget.dirty = true
				end)
				:catch(function(error)
					-- mod:echo(cjson.encode(error))
				end)
		end)
	end
end

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
	local material_values = widget.style.frame.material_values
	material_values.texture_map = icon
	widget.dirty = true
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
