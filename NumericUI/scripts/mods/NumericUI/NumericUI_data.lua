local mod = get_mod("NumericUI")

return {
	name = "Numeric UI",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "health_text",
				type = "checkbox",
				default_value = true,
			},

			{
				setting_id = "toughness_text",
				type = "checkbox",
				default_value = true,
			},

			{
				setting_id = "level",
				type = "checkbox",
				default_value = true,
			},

			{
				setting_id = "ammo_text",
				type = "checkbox",
				default_value = true,
			},
		},
	},
}
