local Breeds = require("scripts/settings/breed/breeds")

local localizations = {
	mod_description = {
		en = "Deduplicate feed items and filter by breed",
		["zh-cn"] = "击杀面板消息去重，以及按敌人类型筛选",
	},
	include_breeds = {
		en = "Show in killfeed",
		["zh-cn"] = "在击杀面板显示",
	},
	enable_in_psykanium = {
		en = "Enable in Psykanium",
		["zh-cn"] = "在灵能室启用",
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
