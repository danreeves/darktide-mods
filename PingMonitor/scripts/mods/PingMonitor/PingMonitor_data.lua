local mod = get_mod("PingMonitor")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "always_visible",
				type = "checkbox",
				default_value = false,
				tooltip = "always_visible_tooltip",
			},
		},
	},
}
