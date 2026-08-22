local mod = get_mod("ProfilePictures")

local _apply_profile_image = mod.apply_profile_image

-- The view owns a single portrait widget, and neither vanilla callback passes it, so resolve it here
local function _apply_view_profile_image(self, texture)
	local widgets_by_name = self._widgets_by_name

	_apply_profile_image(widgets_by_name and widgets_by_name.character_portrait, "texture_portrait", texture)
end

mod:hook_safe("InventoryBackgroundView", "_load_portrait_icon", function(self)
	local player = self._preview_player
	local player_info = player and mod.player_info_for_player(player)

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
