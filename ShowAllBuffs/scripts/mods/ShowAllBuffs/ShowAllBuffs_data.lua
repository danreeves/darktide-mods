local mod = get_mod("ShowAllBuffs")

return {
	name = "Show All Buffs",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
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
