local Breeds = require("scripts/settings/breed/breeds")

local localizations = {
	mod_name = {
		en = "Killfeed Improvements",
		ru = "Улучшение ленты убийств",
		["zh-cn"] = "击杀消息优化",
	},
	mod_description = {
		en = "Deduplicate feed items and filter by breed",
		["zh-cn"] = "击杀面板消息去重，以及按敌人类型筛选",
		ru = "Убирает из ленты убийств дубликаты сообщений и фильтрует по происхождению.",
	},
	include_breeds = {
		en = "Show in killfeed",
		["zh-cn"] = "在击杀面板显示",
		ru = "Показывать в ленте убийств",
	},
	merge_kills = {
		en = "Merge kills",
	},
	enable_in_psykanium = {
		en = "Enable in Psykanium",
	},
	alignment = {
		en = "Alignment",
	},
	left = {
		en = "Left",
	},
	center = {
		en = "Center",
	},
	right = {
		en = "Right",
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
