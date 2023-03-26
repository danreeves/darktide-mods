local mod = get_mod("Healthbars")
local Breeds = require("scripts/settings/breed/breeds")

local localization = {
	mod_description = {
		en = "Show healthbars from the Psykanium in regular game modes",
		["zh-cn"] = "在常规游戏模式中也显示灵能室的血条",
		ru = "Показывает полоски здоровья из Псайканиума в обычных режимах игры",
	},
}

local tags = {
	horde = {
		en = "horde",
		["zh-cn"] = "群怪",
		ru = "орда",
	},
	roamer = {
		en = "roamer",
		["zh-cn"] = "游荡",
		ru = "бродяга",
	},
	elite = {
		en = "elite",
		["zh-cn"] = "精英",
		ru = "элита",
	},
	special = {
		en = "special",
		["zh-cn"] = "专家",
		ru = "специалист",
	},
	captain = {
		en = "captain",
		["zh-cn"] = "连长",
		ru = "капитан",
	},
	monster = {
		en = "monster",
		["zh-cn"] = "怪物",
		ru = "монстр",
	},
}

for _, value in pairs(tags) do
	setmetatable(value, {
		__index = function()
			return value.en
		end,
	})
end

local function get_tag(breed, locale)
	return breed.tags.horde and tags.horde[locale]
		or breed.tags.roamer and tags.roamer[locale]
		or breed.tags.elite and tags.elite[locale]
		or breed.tags.special and tags.special[locale]
		or breed.tags.captain and tags.captain[locale]
		or breed.tags.monster and tags.monster[locale]
		or ""
end

for breed_name, breed in pairs(Breeds) do
	if breed.tags.minion then
		local display_name = Localize(breed.display_name)
		localization[breed_name] = {
			en = "[" .. get_tag(breed, "en") .. "] Show " .. display_name .. " health",
			["zh-cn"] = "[" .. get_tag(breed, "zh-cn") .. "] 显示" .. display_name .. "的血量",
			ru = "[" .. get_tag(breed, "ru") .. "] Показать здоровье: " .. display_name,
		}
	end
end

return localization
