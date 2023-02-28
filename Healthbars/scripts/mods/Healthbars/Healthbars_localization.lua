local mod = get_mod("Healthbars")
local Breeds = require("scripts/settings/breed/breeds")

local localization = {
	mod_description = {
		en = "Show healthbars from the Psykanium in regular game modes",
	},
}

for breed_name, breed in pairs(Breeds) do
	if breed.tags.minion then
		local display_name = Localize(breed.display_name)
		local tag = breed.tags.horde and "horde"
			or breed.tags.roamer and "roamer"
			or breed.tags.elite and "elite"
			or breed.tags.special and "special"
			or breed.tags.captain and "captain"
			or breed.tags.monster and "monster"
			or ""
		local label = "[" .. tag .. "] Show " .. display_name .. " health"
		localization[breed_name] = {
			en = label,
		}
	end
end

return localization
