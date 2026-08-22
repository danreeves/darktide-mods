local mod = get_mod("ProfilePictures")

local _apply_profile_image = mod.apply_profile_image
local location_enabled = mod.location_enabled

mod:hook_safe("EndView", "_load_portrait_icon", function(_self, widget, _profile)
	if not location_enabled.end_screen then
		return
	end

	local widget_content = widget.content
	local player_info = widget_content.player_info

	mod.load_profile_image(player_info, function(texture)
		-- Panels are rebuilt when the slots are reassigned, so a late callback may belong to another player
		if widget_content.player_info ~= player_info then
			return
		end

		widget_content.profile_picture_texture = texture

		_apply_profile_image(widget, "character_portrait", texture)
	end)
end)

-- Vanilla replaces the icon slot with the character render target once it finishes loading
mod:hook_safe("EndView", "_cb_set_player_icon", function(_self, widget)
	local texture = widget.content.profile_picture_texture

	if texture then
		_apply_profile_image(widget, "character_portrait", texture)
	end
end)

-- Runs when a panel drops its portrait, so a rebuilt panel never keeps the previous player's picture
mod:hook_safe("EndView", "_unload_portrait_icon", function(_self, widget)
	widget.content.profile_picture_texture = nil
end)
