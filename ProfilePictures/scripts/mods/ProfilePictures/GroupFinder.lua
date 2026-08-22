local mod = get_mod("ProfilePictures")

local _apply_profile_image = mod.apply_profile_image
local location_enabled = mod.location_enabled

local TEAM_MEMBER_WIDGET_NAMES = {
	"team_member_1",
	"team_member_2",
	"team_member_3",
	"team_member_4",
}

-- Both Party Finder surfaces carry an account id rather than a PlayerInfo, so that is what the picture is keyed to
local function _load_profile_image(widget, account_id)
	local widget_content = widget.content

	-- A widget kept for another player must not re-apply the previous picture when vanilla writes its render target
	if widget_content.profile_picture_account_id ~= account_id then
		widget_content.profile_picture_texture = nil
	end

	widget_content.profile_picture_account_id = account_id

	if not account_id then
		return
	end

	-- Assigned above either way, so the recycled entries and party slots stop asking while the location is off
	if not location_enabled.party_finder then
		return
	end

	local social_service_manager = Managers.data_service.social
	local player_info = social_service_manager and social_service_manager:get_player_info_by_account_id(account_id)

	mod.load_profile_image(player_info, function(texture)
		-- Grid entries are recycled and party slots reassigned, so a late callback may belong to a player this widget no longer shows
		if widget_content.profile_picture_account_id ~= account_id then
			return
		end

		widget_content.profile_picture_texture = texture

		_apply_profile_image(widget, "character_portrait", texture)
	end)
end

-- Dropping the account id is what keeps a request in flight from reaching the widget it was started for
local function _clear_profile_image(widget)
	local widget_content = widget.content

	widget_content.profile_picture_texture = nil
	widget_content.profile_picture_account_id = nil
end

-- The previewed group's members and the incoming join requests both render through this blueprint
mod:hook_require("scripts/ui/views/group_finder_view/group_finder_view_definitions", function(instance)
	local grid_blueprints = instance.grid_blueprints
	local blueprint = grid_blueprints and grid_blueprints.player_request_entry

	if not blueprint then
		return
	end

	mod:hook_safe(blueprint, "load_icon", function(_parent, widget, element)
		local account_id = element and element.account_id

		-- The grid re-runs this every frame while it scrolls, so only act once the entry changed player
		if widget.content.profile_picture_account_id ~= account_id then
			_load_profile_image(widget, account_id)
		end
	end)

	-- Vanilla loads the portrait through a closure instead of a named method, so the entry's own update is the only place its render target landing in the icon slot is observable
	mod:hook_safe(blueprint, "update", function(_parent, widget)
		local texture = widget.content.profile_picture_texture

		if not texture then
			return
		end

		local style = widget.style.character_portrait

		if style and style.material_values.texture_icon ~= texture then
			_apply_profile_image(widget, "character_portrait", texture)
		end
	end)

	-- Runs when an entry scrolls out of view
	mod:hook_safe(blueprint, "unload_icon", function(_parent, widget)
		_clear_profile_image(widget)
	end)

	-- Runs for every entry when the layout is rebuilt, which is what previewing another group does
	mod:hook_safe(blueprint, "destroy", function(_parent, widget)
		_clear_profile_image(widget)
	end)
end)

-- The own party slots are filled here, and the account ids land on the listed group's members in the same pass
mod:hook_safe("GroupFinderView", "_update_listed_group", function(self)
	local widgets_by_name = self._widgets_by_name

	if not widgets_by_name then
		return
	end

	local own_group_visualization = self._own_group_visualization
	local members = own_group_visualization and own_group_visualization.members

	for i = 1, 4 do
		local widget = widgets_by_name[TEAM_MEMBER_WIDGET_NAMES[i]]

		if widget then
			local member = members and members[i]
			local account_id = member and member.account_id

			-- Also runs while a party member's profile is still resolving, so only act once the slot changed player
			if widget.content.profile_picture_account_id ~= account_id then
				_load_profile_image(widget, account_id)
			end
		end
	end
end)

-- Vanilla replaces the icon slot with the character render target once it finishes loading
mod:hook_safe("GroupFinderView", "_cb_set_player_icon", function(_self, widget)
	local texture = widget.content.profile_picture_texture

	if texture then
		_apply_profile_image(widget, "character_portrait", texture)
	end
end)

mod:hook_safe("GroupFinderView", "_cb_unset_player_icon", function(_self, widget)
	widget.content.profile_picture_texture = nil
end)

-- Runs before every refill and when the view closes, so a reused slot never keeps the previous player's picture
mod:hook_safe("GroupFinderView", "_unload_portrait_icon", function(_self, widget)
	_clear_profile_image(widget)
end)
