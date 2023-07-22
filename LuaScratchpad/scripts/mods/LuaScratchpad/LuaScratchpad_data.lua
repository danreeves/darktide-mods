local mod = get_mod("LuaScratchpad")

return {
	name = mod:localize("mod_name"),
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
			{
				setting_id = "ui_scale",
				type = "numeric",
				default_value = 1.5,
				range = { 1, 5 },
				decimals_number = 1,
			},
		},
	},
}
