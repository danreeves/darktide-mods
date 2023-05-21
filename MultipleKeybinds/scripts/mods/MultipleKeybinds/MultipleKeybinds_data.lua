local mod = get_mod("MultipleKeybinds")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "unset_on_rightclick",
				type = "checkbox",
				default_value = false,
			},
		},
	},
}
