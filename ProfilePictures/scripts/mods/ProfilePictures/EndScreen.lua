local mod = get_mod("ProfilePictures")

-- The end of mission portrait is a render target fed into the frame material's icon slot, so the picture goes into that same slot instead of being drawn over the panel. The equipped frame keeps rendering around it.
local function _apply_profile_image(widget, texture)
	local style = widget and widget.style.character_portrait

	if not style then
		return
	end

	local material_values = style.material_values

	material_values.use_placeholder_texture = 0
	material_values.rows = 1
	material_values.columns = 1
	material_values.grid_index = 0
	material_values.texture_icon = texture
	widget.dirty = true
end

mod:hook_safe("EndView", "_load_portrait_icon", function(_self, widget, _profile)
	local widget_content = widget.content
	local player_info = widget_content.player_info

	mod.load_profile_image(player_info, function(texture)
		-- Panels are rebuilt when the slots are reassigned, so a late callback may belong to another player
		if widget_content.player_info ~= player_info then
			return
		end

		widget_content.profile_picture_texture = texture

		_apply_profile_image(widget, texture)
	end)
end)

-- Vanilla replaces the icon slot with the character render target once it finishes loading
mod:hook_safe("EndView", "_cb_set_player_icon", function(_self, widget)
	local texture = widget.content.profile_picture_texture

	if texture then
		_apply_profile_image(widget, texture)
	end
end)

-- Runs when a panel drops its portrait, so a rebuilt panel never keeps the previous player's picture
mod:hook_safe("EndView", "_unload_portrait_icon", function(_self, widget)
	widget.content.profile_picture_texture = nil
end)
