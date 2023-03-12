local Breeds = require("scripts/settings/breed/breeds")

local localizations = {
	mod_description = {
		en = "Deduplicate feed items and filter by breed",
	},
	include_breeds = {
		en = "Show in killfeed",
	},
	enable_in_psykanium = {
		en = "Enable in Psykanium",
	},
}

for name, breed in pairs(Breeds) do
	local tags = breed.tags
	if tags and (tags.monster or tags.special or tags.elite) then
		localizations[name] = {
			en = Localize(breed.display_name),
		}
	end
end

return localizations
