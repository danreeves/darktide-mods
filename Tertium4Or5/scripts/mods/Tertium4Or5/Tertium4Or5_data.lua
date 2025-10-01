local mod = get_mod("Tertium4Or5")

mod.character_options = {
	{
		text = "None",
		value = "none",
	},
	{
		text = "None",
		value = "none2",
	},
}

local sub_widgets = {}

for i = 1, 4 do
	sub_widgets[#sub_widgets + 1] = {
		setting_id = "character_" .. i,
		type = "dropdown",
		default_value = "none",
		options = mod.character_options,
	}
end

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "four_bots",
				type = "checkbox",
				default_value = false,
			},
			{
				setting_id = "bots",
				type = "group",
				sub_widgets = sub_widgets,
			},
		},
	},
}
