local mod = get_mod("ProfilePictures")

return {
	name = "ProfilePictures",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
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
}
