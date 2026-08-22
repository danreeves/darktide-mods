local mod = get_mod("ProfilePictures")

-- The plaque portrait is a render target fed into the frame material's icon slot, so the picture goes into that same slot instead of being drawn over the plaque. The equipped frame keeps rendering around it.
local function _apply_profile_image(widget, texture)
	local style = widget.style.portrait

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

local function _load_profile_image(widget, player_info)
	mod.load_profile_image(player_info, function(texture)
		-- Roster widgets are recycled, so a late callback may belong to a player this widget no longer shows
		if widget.content.player_info ~= player_info then
			return
		end

		widget.content.profile_picture_texture = texture

		_apply_profile_image(widget, texture)
	end)
end

mod:hook_safe("SocialMenuRosterView", "_load_widget_portrait", function(_self, widget, _profile)
	_load_profile_image(widget, widget.content.player_info)
end)

-- Vanilla replaces the icon slot with the character render target once it finishes loading
mod:hook_safe("SocialMenuRosterView", "_cb_set_player_icon", function(_self, widget)
	local texture = widget.content.profile_picture_texture

	if texture then
		_apply_profile_image(widget, texture)
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
