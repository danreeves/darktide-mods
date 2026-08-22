local mod = get_mod("ProfilePictures")

return {
	name = "ProfilePictures",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "locations",
				type = "group",
				title = "locations",
				sub_widgets = {
					{
						setting_id = "location_player_hud",
						type = "checkbox",
						title = "location_player_hud",
						tooltip = "location_player_hud_tooltip",
						default_value = true,
					},
					{
						setting_id = "location_social_menu",
						type = "checkbox",
						title = "location_social_menu",
						tooltip = "location_social_menu_tooltip",
						default_value = true,
					},
					{
						setting_id = "location_lobby",
						type = "checkbox",
						title = "location_lobby",
						tooltip = "location_lobby_tooltip",
						default_value = true,
					},
					{
						setting_id = "location_end_screen",
						type = "checkbox",
						title = "location_end_screen",
						tooltip = "location_end_screen_tooltip",
						default_value = true,
					},
					{
						setting_id = "location_party_finder",
						type = "checkbox",
						title = "location_party_finder",
						tooltip = "location_party_finder_tooltip",
						default_value = true,
					},
					{
						setting_id = "location_inventory",
						type = "checkbox",
						title = "location_inventory",
						tooltip = "location_inventory_tooltip",
						default_value = true,
					},
				},
			},
			{
				setting_id = "advanced",
				type = "group",
				title = "advanced",
				sub_widgets = {
					{
						setting_id = "image_proxy_url",
						type = "text",
						title = "image_proxy_url",
						tooltip = "image_proxy_url_tooltip",
						placeholder_text = "image_proxy_url_placeholder",
						default_value = "",
					},
				},
			},
		},
	},
}
