local mod = get_mod("ProfilePictures")

local _apply_profile_image = mod.apply_profile_image
local location_enabled = mod.location_enabled

mod:hook_safe("LobbyView", "_assign_player_to_slot", function(_self, player, slot)
	if not location_enabled.lobby then
		return
	end

	local unique_id = slot.unique_id
	local player_info = mod.player_info_for_player(player)

	mod.load_profile_image(player_info, function(texture)
		-- Slots get reset and reassigned, so a late callback may belong to a player who left
		if slot.unique_id ~= unique_id then
			return
		end

		slot.profile_picture_texture = texture

		_apply_profile_image(slot.panel_widget, "character_portrait", texture)
	end)
end)

-- Vanilla replaces the icon slot with the character render target once it finishes loading
mod:hook_safe("LobbyView", "_cb_set_player_icon", function(_self, slot)
	local texture = slot.profile_picture_texture

	if texture then
		_apply_profile_image(slot.panel_widget, "character_portrait", texture)
	end
end)

-- Runs at the start of every portrait load, so a reused slot never keeps the previous player's picture
mod:hook_safe("LobbyView", "_unload_portrait_icon", function(_self, slot)
	slot.profile_picture_texture = nil
end)
