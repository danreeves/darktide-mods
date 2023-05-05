local mod = get_mod("HUDTweaker")

return {
	name = "HUD Tweaker",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "toggle_hud_tweaker",
				type = "keybind",
				default_value = {},
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "toggle_hud_tweaker",
			},
		},
	},
}
