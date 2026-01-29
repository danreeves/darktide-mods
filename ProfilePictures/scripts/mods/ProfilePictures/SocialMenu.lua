local mod = get_mod("ProfilePictures")

mod:hook_safe("SocialMenuRosterView", "_load_widget_portrait", function(_self, widget, _profile)
	local content = widget.content
	local player_info = content.player_info
	mod.load_profile_image(player_info, function(texture)
		local material_values = widget.style.profile.material_values
		material_values.texture_map = texture
		widget.dirty = true
	end)
end)

-- Reuse the frame texture when it gets loaded
mod:hook_safe("SocialMenuRosterView", "_cb_set_player_frame", function(_self, widget, item)
	local widget_content = widget.content
	local profile = widget_content.player_info:profile()
	local loadout = profile and profile.loadout
	local frame_item = loadout and loadout.slot_portrait_frame
	local frame_item_gear_id = frame_item and frame_item.gear_id
	local icon = nil

	if frame_item_gear_id == item.gear_id then
		icon = item.icon
	end

	if not icon then
		return
	end

	local portrait_style = widget.style.frame
	portrait_style.material_values.texture_map = icon
	widget.dirty = true
end)

-- Stop using the frame texture before it gets unloaded
mod:hook("SocialMenuRosterView", "_queue_icons_for_unload", function(func, self, widget)
    local portrait_style = widget.style.frame
    if portrait_style then
        portrait_style.material_values.texture_map = nil
    end
    return func(self, widget)
end)

mod:hook_require("scripts/ui/views/social_menu_roster_view/social_menu_roster_view_blueprints", function(instance)
	local blueprint = instance.player_plaque

	if not table.find_by_key(blueprint.pass_template, "style_id", "profile") then
		table.insert(blueprint.pass_template, {
			style_id = "frame",
			value_id = "frame",
			pass_type = "texture",
			visibility_function = function(_content, style)
				if style.material_values.texture_map then
					return true
				end

				return false
			end,
		})

		table.insert(blueprint.pass_template, {
			style_id = "profile",
			value_id = "profile",
			pass_type = "texture",
			visibility_function = function(_content, style)
				if style.material_values.texture_map then
					return true
				end

				return false
			end,
		})
	end

	mod:hook_safe(
		blueprint,
		"init",
		function(_parent, widget, player_info, _callback_name, _secondary_callback_name, _ui_renderer)
			mod.load_profile_image(player_info, function(texture)
				local material_values = widget.style.profile.material_values
				material_values.texture_map = texture
				widget.dirty = true
			end)
		end
	)

	local orig_size = blueprint.style.portrait.size
	local size = { orig_size[1] - 20, orig_size[2] - 20 }

	table.merge_recursive(blueprint.style, {
		frame = {
			material_values = {
				use_placeholder_texture = 0,
				texture_map = "content/ui/textures/nameplates/portrait_frames/default",
			},
			color = {
				255,
				255,
				255,
				255,
			},
			offset = {
				0,
				0,
				10,
			},
			size = orig_size,
		},
		profile = {
			material_values = {
				use_placeholder_texture = 0,
			},
			color = {
				255,
				255,
				255,
				255,
			},
			offset = {
				10,
				10,
				1,
			},
			size = size,
		},
	})
end)
