local Breeds = require("scripts/settings/breed/breeds")

local localizations = {mod_name = {
		en = "Killfeed Improvements",
		ru = "Улучшение ленты убийств",
	},
	mod_description = {
		en = "Deduplicate feed items and filter by breed",
		ru = "Убирает из ленты убийств дубликаты сообщений и фильтрует по происхождению.",
	},
	include_breeds = {
		en = "Show in killfeed",
		ru = "Показывать в ленте убийств",
	},
	enable_in_psykanium = {
		en = "Enable in Psykanium",
		ru = "Включить в Псайканиуме",
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
