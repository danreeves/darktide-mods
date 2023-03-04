local mod = get_mod("Healthbars")
local Breeds = require("scripts/settings/breed/breeds")

local widgets = {}

for breed_name, breed in pairs(Breeds) do
	if breed_name ~= "chaos_spawn" and breed_name ~= "chaos_plague_ogryn_sprayer" then
		if breed.tags.minion then
			local default_value = false
			if breed.tags.elite or breed.tags.special then
				default_value = true
			end
			widgets[#widgets + 1] = {
				setting_id = breed_name,
				type = "checkbox",
				default_value = default_value,
			}
		end
	end
end

return {
	name = "Healthbars",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = widgets,
	},
}
