local mod = get_mod("ProfilePictures")

local _apply_profile_image = mod.apply_profile_image
local location_enabled = mod.location_enabled

-- Vanilla renders the portrait into the icon slot of the notification's frame material, so the picture goes into that same slot
mod:hook_safe(
	"ConstantElementNotificationFeed",
	"_create_notification_entry",
	function(self, notification_data, notification_id)
		if not location_enabled.player_hud then
			return
		end

		local player = notification_data.use_player_portrait and notification_data.player

		if not player then
			return
		end

		-- The entry is inserted before this returns, and the definition's init has already replaced the icon material values
		local notification = self:_notification_by_id(notification_id)

		if not notification then
			return
		end

		-- Cleared when the notification is removed, so a request still in flight never reaches a destroyed widget
		notification.profile_picture_player = player

		local player_info = mod.player_info_for_player(player)

		mod.load_profile_image(player_info, function(texture)
			if notification.profile_picture_player ~= player then
				return
			end

			notification.profile_picture_texture = texture

			_apply_profile_image(notification.widget, "icon", texture)
		end)
	end
)

-- Vanilla replaces the icon slot with the character render target once it finishes loading
mod:hook_safe("ConstantElementNotificationFeed", "_on_player_portrait_loaded", function(_self, notification)
	local texture = notification.profile_picture_texture

	if texture then
		_apply_profile_image(notification.widget, "icon", texture)
	end
end)

-- Notifications time out and take their widget with them
mod:hook_safe("ConstantElementNotificationFeed", "_remove_notification", function(_self, notification)
	notification.profile_picture_player = nil
	notification.profile_picture_texture = nil
end)
