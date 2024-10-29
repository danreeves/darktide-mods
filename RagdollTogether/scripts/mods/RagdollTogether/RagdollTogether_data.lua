local mod = get_mod("RagdollTogether")

return {
	name = "RagdollTogether",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "ragdoll_toggle",
				type = "keybind",
				default_value = {},
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "ragdoll_toggle", -- required, if (keybind_type == "function_call")
			},
		},
	},
}
