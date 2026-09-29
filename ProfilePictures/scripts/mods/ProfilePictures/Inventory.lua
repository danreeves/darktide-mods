local mod = get_mod("ProfilePictures")

local _apply_profile_image = mod.apply_profile_image
local location_enabled = mod.location_enabled

-- The view owns a single portrait widget, and neither vanilla callback passes it, so resolve it here
local function _apply_view_profile_image(self, texture)
	local widgets_by_name = self._widgets_by_name

	_apply_profile_image(widgets_by_name and widgets_by_name.character_portrait, "texture_portrait", texture)
end

-- Vanilla always opens the view with a Player, but the mods that add an inspect button to Party Finder and the social menu pass whatever they hold for the inspected account instead
local function _preview_player_info(player)
	if not player then
		return
	end

	-- Every Player class defines this and PlayerInfo does not
	if player.is_human_controlled then
		return mod.player_info_for_player(player)
	end

	-- A PlayerInfo, or a clone of one, is already what the loader wants
	if type(player.platform) == "function" then
		return player
	end

	local account_id = player.account_id

	-- A Party Finder grid entry carries the account id as a field, a Player-shaped object as a method
	if type(account_id) == "function" then
		account_id = player:account_id()
	end

	if account_id then
		local social_service = Managers.data_service.social

		return social_service and social_service:get_player_info_by_account_id(account_id)
	end
end

mod:hook_safe("InventoryBackgroundView", "_load_portrait_icon", function(self)
	if not location_enabled.inventory then
		return
	end

	local player = self._preview_player
	local player_info = _preview_player_info(player)

	mod.load_profile_image(player_info, function(texture)
		-- The view can go away with the request still in flight
		if self._destroyed or self._preview_player ~= player then
			return
		end

		self._profile_picture_texture = texture

		_apply_view_profile_image(self, texture)
	end)
end)

-- Vanilla replaces the icon slot with the character render target once it finishes loading
mod:hook_safe("InventoryBackgroundView", "_cb_set_player_icon", function(self)
	local texture = self._profile_picture_texture

	if texture then
		_apply_view_profile_image(self, texture)
	end
end)

-- Vanilla swaps in a frame material without an icon slot here, so the picture has to go with it
mod:hook_safe("InventoryBackgroundView", "_cb_unset_player_icon", function(self)
	self._profile_picture_texture = nil
end)
