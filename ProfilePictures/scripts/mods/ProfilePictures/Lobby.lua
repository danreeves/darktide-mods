local mod = get_mod("ProfilePictures")

-- The lobby portrait is a render target fed into the frame material's icon slot, so the picture goes into that same slot instead of being drawn over the panel. The equipped frame keeps rendering around it.
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

mod:hook_safe("LobbyView", "_assign_player_to_slot", function(_self, player, slot)
	local unique_id = slot.unique_id
	local player_info = mod.player_info_for_player(player)

	mod.load_profile_image(player_info, function(texture)
		-- Slots get reset and reassigned, so a late callback may belong to a player who left
		if slot.unique_id ~= unique_id then
			return
		end

		slot.profile_picture_texture = texture

		_apply_profile_image(slot.panel_widget, texture)
	end)
end)

-- Vanilla replaces the icon slot with the character render target once it finishes loading
mod:hook_safe("LobbyView", "_cb_set_player_icon", function(_self, slot)
	local texture = slot.profile_picture_texture

	if texture then
		_apply_profile_image(slot.panel_widget, texture)
	end
end)

-- Runs at the start of every portrait load, so a reused slot never keeps the previous player's picture
mod:hook_safe("LobbyView", "_unload_portrait_icon", function(_self, slot)
	slot.profile_picture_texture = nil
end)
