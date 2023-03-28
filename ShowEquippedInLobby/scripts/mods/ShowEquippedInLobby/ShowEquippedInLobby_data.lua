local mod = get_mod("ShowEquippedInLobby")

return {
	name = "Show Equipped In Lobby",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "default_slot",
				type = "dropdown",
				default_value = "slot_primary",
				options = {
					{ text = "slot_primary", value = "slot_primary" },
					{ text = "slot_secondary", value = "slot_secondary" },
				},
			},
		},
	},
}
