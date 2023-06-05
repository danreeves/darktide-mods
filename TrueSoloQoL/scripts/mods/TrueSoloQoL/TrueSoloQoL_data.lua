local mod = get_mod("TrueSoloQoL")

return {
	name = "TrueSoloQoL",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "disable_bots",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "auto_restart",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "skip_cutscene",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "toggle_pause",
				type = "keybind",
				default_value = {},
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "toggle_pause",
			},
			{
				setting_id = "restart_level",
				type = "keybind",
				default_value = {},
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "restart_level",
			},
			{
				setting_id = "teleport_to_cursor",
				type = "keybind",
				default_value = {},
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "teleport_to_cursor",
			},
		},
	},
}
