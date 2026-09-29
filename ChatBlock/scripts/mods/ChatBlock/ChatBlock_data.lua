local mod = get_mod("ChatBlock")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "auto_melee_swap",
				type = "checkbox",
				default_value = false,
			},
		},
	},
}
