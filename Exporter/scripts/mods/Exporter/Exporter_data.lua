local mod = get_mod("Exporter")

return {
	name = "Exporter",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "open_dmf_options",
				type = "keybind",
				default_value = { "f5" },
				keybind_trigger = "pressed",
				keybind_type = "view_toggle",
				view_name = "item_preview_view",
			},
		},
	},
}
