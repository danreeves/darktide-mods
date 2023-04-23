local mod = get_mod("Healthbars")
local Breeds = require("scripts/settings/breed/breeds")

local breed_widgets = {}

for breed_name, breed in pairs(Breeds) do
	if breed_name ~= "chaos_spawn" and breed_name ~= "chaos_plague_ogryn_sprayer" then
		if breed.tags.minion then
			local default_value = false
			if breed.tags.elite or breed.tags.special then
				default_value = true
			end
			breed_widgets[#breed_widgets + 1] = {
				setting_id = breed_name,
				type = "checkbox",
				default_value = default_value,
			}
		end
	end
end

local widgets = {
	{
		setting_id = "feature_toggles",
		type = "group",
		sub_widgets = {
			{
				setting_id = "show_bar",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_damage_numbers",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_dps",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_armour_type",
				type = "checkbox",
				default_value = true,
			},
		},
	},
	{
		setting_id = "toggle_breeds",
		type = "group",
		sub_widgets = breed_widgets,
	},
}

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = widgets,
	},
}
