local mod = get_mod("Tertium4Or5")
local Archetypes = require("scripts/settings/archetype/archetypes")

mod.max_bots = table.size(Archetypes)

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

for i = 1, mod.max_bots do
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
				setting_id = "num_bots",
				type = "numeric",
				default_value = 3,
				range = { 3, mod.max_bots },
			},
			{
				setting_id = "bots",
				type = "group",
				sub_widgets = sub_widgets,
			},
		},
	},
}
