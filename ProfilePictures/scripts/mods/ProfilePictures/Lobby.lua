local mod = get_mod("ProfilePictures")

local _apply_profile_image = mod.apply_profile_image
local location_enabled = mod.location_enabled

-- Runs for every portrait load: when a player takes a slot, and again whenever vanilla reloads the portrait, which a profile re-sync triggers because the loadout check compares items by table. The unload before it clears the picture, so it has to be loaded here each time; a reload is served from the texture cache.
mod:hook_safe("LobbyView", "_load_portrait_icon", function(_self, slot)
	local player = slot.player

	if not (location_enabled.lobby and player) then
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
