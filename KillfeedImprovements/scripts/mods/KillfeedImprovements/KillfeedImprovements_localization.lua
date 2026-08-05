local Breeds = require("scripts/settings/breed/breeds")

local localizations = {
	mod_name = {
		en = "Killfeed Improvements",
		ru = "Улучшение ленты убийств",
		["zh-cn"] = "击杀消息优化",
		["zh-tw"] = "擊殺資訊優化",
	},
	mod_description = {
		en = "Deduplicate feed items and filter by breed",
		["zh-cn"] = "击杀面板消息去重，以及按敌人类型筛选",
		["zh-tw"] = "去除重複的擊殺訊息，並依敵人類型篩選",
		ru = "Убирает из ленты убийств дубликаты сообщений и фильтрует по происхождению.",
	},
	include_breeds = {
		en = "Show in killfeed",
		["zh-cn"] = "在击杀面板显示",
		["zh-tw"] = "在擊殺訊息欄顯示",
		ru = "Показывать в ленте убийств",
	},
	merge_kills = {
		en = "Merge kills",
		["zh-tw"] = "合併擊殺訊息",
	},
	filter_teammate_kills = {
		en = "Hide teammate kills",
		["zh-tw"] = "隱藏隊友擊殺訊息",
	},
	enable_in_psykanium = {
		en = "Enable in Psykanium",
		["zh-tw"] = "在靈能室中啟用",
	},
	alignment = {
		en = "Alignment",
		["zh-tw"] = "對齊方式",
	},
	left = {
		en = "Left",
		["zh-tw"] = "靠左",
	},
	center = {
		en = "Center",
		["zh-tw"] = "置中",
	},
	right = {
		en = "Right",
		["zh-tw"] = "靠右",
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
