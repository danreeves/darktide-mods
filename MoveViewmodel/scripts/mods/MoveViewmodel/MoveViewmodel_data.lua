local mod = get_mod("MoveViewmodel")

return {
	name = "MoveViewmodel",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "open_editor",
				type = "keybind",
				default_value = {},
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "toggle_editor",
			},
		},
	},
}
