local mod = get_mod("LogMeIn")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = false,
	options = {
		widgets = {
			{
				setting_id = "auto_character_select",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "cancel_auto_character_select",
				type = "keybind",
				default_value = { "space" },
				keybind_global = true,
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "cancel_auto_character_select",
			},
		},
	},
}
