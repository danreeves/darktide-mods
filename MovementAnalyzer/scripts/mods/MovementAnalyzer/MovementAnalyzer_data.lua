local mod = get_mod("MovementAnalyzer")

return {
	name = "MovementAnalyzer",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "show_dodge",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_slide",
				type = "checkbox",
				default_value = true,
			},
		},
	},
}
