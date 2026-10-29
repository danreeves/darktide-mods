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
			{
				setting_id = "averaging_samples",
				type = "numeric",
				default_value = 30,
				range = { 1, 120 },
				decimals_number = 0,
				tooltip = "averaging_samples_tooltip",
			},
		},
	},
}
