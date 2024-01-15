-- This doesn't work because the lobby doesn't recieve any social information about the players.

local mod = get_mod("ProfilePictures")
local UIWidget = require("scripts/managers/ui/ui_widget")

mod:hook_safe("LobbyView", "_assign_player_to_slot", function(_self, player, slot)
	local player_info = mod.player_info_for_player(player)
	local widget = slot.panel_widget
	mod.load_profile_image(player_info, function(texture)
		widget.style.profile.material_values.texture_map = texture
		widget.dirty = true
	end)
end)

mod:hook_safe("LobbyView", "_cb_set_player_frame", function(_self, widget, item)
	widget.style.frame.material_values.texture_map = item.icon
end)

mod:hook_require("scripts/ui/views/lobby_view/lobby_view_definitions", function(instance)
	local panel_definition = instance.panel_definition

	-- if not panel_definition.content.frame then
	local original_size = panel_definition.style.character_portrait.size
	local size = { original_size[1] - 20, original_size[2] - 20 }

	UIWidget.add_definition_pass(panel_definition, {
		style_id = "frame",
		value_id = "frame",
		pass_type = "texture",
		style = {
			material_values = {
				use_placeholder_texture = 0,
				texture_map = "content/ui/textures/nameplates/portrait_frames/default",
			},
			horizontal_alignment = "center",
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
			size = original_size,
		},
		visibility_function = function(_content, style)
			if style.material_values.texture_map then
				return true
			end

			return false
		end,
	})
	UIWidget.add_definition_pass(panel_definition, {
		style_id = "profile",
		value_id = "profile",
		pass_type = "texture",
		style = {
			material_values = {
				use_placeholder_texture = 0,
			},
			horizontal_alignment = "center",
			color = {
				255,
				255,
				255,
				255,
			},
			offset = {
				0,
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
	-- end
end)
