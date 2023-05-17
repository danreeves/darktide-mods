local mod = get_mod("BuffHUDImprovements")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "open_buff_settings",
				type = "keybind",
				default_value = {},
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "open_buff_settings",
			},
			{
				setting_id = "custom_buffs",
				type = "group",
				sub_widgets = {
					{
						setting_id = "custom_toughness_broken_buff",
						type = "checkbox",
						default_value = false,
					},
				},
			},
		},
	},
}
