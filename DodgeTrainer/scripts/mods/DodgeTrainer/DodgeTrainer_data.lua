local mod = get_mod("DodgeTrainer")

return {
	name = "DodgeTrainer",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "min_time",
				type = "numeric",
				default_value = 1 / 5,
				range = { 0.0, 1.0 },
				decimals_number = 2,
			},
			{
				setting_id = "max_time",
				type = "numeric",
				default_value = 1 / 2,
				range = { 0.0, 1.0 },
				decimals_number = 2,
			},
			{
				setting_id = "max_cutoff",
				type = "numeric",
				default_value = 1,
				range = { 0.0, 5.0 },
				decimals_number = 2,
			},
			{
				setting_id = "include_sprinting",
				type = "checkbox",
				default_value = false,
			},
		},
	},
}
