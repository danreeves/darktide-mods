local mod = get_mod("ProfilePictures")

local _apply_profile_image = mod.apply_profile_image

local function _load_profile_image(widget, player_info)
	local widget_content = widget.content

	-- A widget kept for another player must not re-apply the previous picture when vanilla writes its render target
	if widget_content.profile_picture_player_info ~= player_info then
		widget_content.profile_picture_texture = nil
	end

	widget_content.profile_picture_player_info = player_info

	mod.load_profile_image(player_info, function(texture)
		-- Widgets are reused, so a late callback may belong to a player this widget no longer shows, or to a plaque the popup has torn down since
		if widget_content.profile_picture_player_info ~= player_info then
			return
		end

		widget_content.profile_picture_texture = texture

		_apply_profile_image(widget, "portrait", texture)
	end)
end

mod:hook_safe("SocialMenuRosterView", "_load_widget_portrait", function(_self, widget, _profile)
	_load_profile_image(widget, widget.content.player_info)
end)

-- Vanilla replaces the icon slot with the character render target once it finishes loading
mod:hook_safe("SocialMenuRosterView", "_cb_set_player_icon", function(_self, widget)
	local texture = widget.content.profile_picture_texture

	if texture then
		_apply_profile_image(widget, "portrait", texture)
	end
end)

-- Runs at the start of every portrait load, so a recycled widget never keeps the previous player's picture
mod:hook_safe("SocialMenuRosterView", "_unload_widget_portrait", function(_self, widget)
	widget.content.profile_picture_texture = nil
end)

mod:hook_require("scripts/ui/views/social_menu_roster_view/social_menu_roster_view_blueprints", function(instance)
	mod:hook_safe(
		instance.player_plaque,
		"init",
		function(_parent, widget, player_info, _callback_name, _secondary_callback_name, _ui_renderer)
			_load_profile_image(widget, player_info)
		end
	)
end)

-- The popup draws its header portrait itself instead of going through the roster view, both for a roster entry and for the Find Player search
mod:hook_safe("ViewElementPlayerSocialPopup", "_set_player_info", function(self, _parent, player_info)
	_load_profile_image(self._widgets_by_name.player_header, player_info)
end)

-- Runs when the shown player's profile changes
mod:hook_safe("ViewElementPlayerSocialPopup", "_update_portrait", function(self)
	_load_profile_image(self._widgets_by_name.player_header, self._player_info)
end)

-- Vanilla replaces the icon slot with the character render target once it finishes loading
mod:hook_safe("ViewElementPlayerSocialPopup", "_cb_set_player_icon", function(_self, widget)
	local texture = widget.content.profile_picture_texture

	if texture then
		_apply_profile_image(widget, "portrait", texture)
	end
end)

mod:hook_safe("ViewElementPlayerSocialPopup", "_cb_unset_player_icon", function(_self, widget)
	widget.content.profile_picture_texture = nil
end)

-- One plaque serves every search, and the result only arrives once the friend code request comes back, so drop what the previous search was loading
mod:hook_safe("ViewElementPlayerSocialPopup", "_search_for_player", function(self)
	local widget = self._widgets_by_name.player_plaque

	if not widget then
		return
	end

	local widget_content = widget.content

	widget_content.profile_picture_player_info = nil
	widget_content.profile_picture_texture = nil
end)

-- The popup can go away with a request still in flight, so stop it from reaching the widgets it was started for
mod:hook_safe("ViewElementPlayerSocialPopup", "destroy", function(self)
	local widgets_by_name = self._widgets_by_name

	if not widgets_by_name then
		return
	end

	local header = widgets_by_name.player_header

	if header then
		header.content.profile_picture_player_info = nil
	end

	local plaque = widgets_by_name.player_plaque

	if plaque then
		plaque.content.profile_picture_player_info = nil
	end
end)

mod:hook_require(
	"scripts/ui/view_elements/view_element_player_social_popup/view_element_player_social_popup_blueprints",
	function(instance)
		mod:hook_safe(instance.player_plaque, "update", function(_parent, widget)
			local widget_content = widget.content
			local player_info = widget_content.player_info

			-- The search result is assigned asynchronously, and vanilla only loads a portrait for it when the account resolves to a character profile
			if widget_content.profile_picture_player_info ~= player_info then
				_load_profile_image(widget, player_info)
			end
		end)
	end
)
