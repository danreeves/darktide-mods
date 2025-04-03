local Breeds = require("scripts/settings/breed/breeds")

local localization = {
	mod_name = {
		en = "Healthbars",
		["zh-cn"] = "敌人血条",
		ru = "Полоски здоровья",
	},
	mod_description = {
		en = "Show healthbars from the Psykanium in regular game modes",
		["zh-cn"] = "在常规游戏模式中也显示灵能室的血条",
		ru = "Показывает полоски здоровья из Псайканиума в обычных режимах игры",
	},
	feature_toggles = {
		en = "Toggle features",
		["zh-cn"] = "开关功能",
		ru = "Выключение функций",
	},
	show_bar = {
		en = "Show health bar",
		["zh-cn"] = "显示血条",
		ru = "Полоски здоровья",
	},
	show_damage_numbers = {
		en = "Show damage numbers",
		["zh-cn"] = "显示伤害数字",
		ru = "Цифры урона",
	},
	show_dps = {
		en = "Show DPS report",
		["zh-cn"] = "显示 DPS 报告",
		ru = "Отчёт Урон в секунду",
	},
	show_armour_type = {
		en = "Show armour type hit",
		["zh-cn"] = "显示命中护甲类型",
		ru = "Тип поражённой брони",
	},
	horde_breeds = {
		en = "Horde/Roamer",
		["zh-cn"] = "群怪/游荡",
		ru = "Орда/бродяга",
	},
	elite_breeds = {
		en = "Elite",
		["zh-cn"] = "精英",
		ru = "Элита",
	},
	special_breeds = {
		en = "Special",
		["zh-cn"] = "专家",
		ru = "Специалист",
	},
	monster_breeds = {
		en = "Monster/Captain",
		["zh-cn"] = "怪物/连长",
		ru = "Монстр/капитан",
	},
	bleed = {
		en = "Show bleed stacks",
		["zh-cn"] = "显示流血层数",
		ru = "Заряды кровотечения",
	},
	burn = {
		en = "Show burn stacks",
		["zh-cn"] = "显示燃烧层数",
		ru = "Заряды горения",
	},
}

for breed_name, breed in pairs(Breeds) do
	if breed.tags.minion then
		local display_name = Localize(breed.display_name)
		localization[breed_name] = {
			en = "Show " .. display_name .. " health",
			["zh-cn"] = "显示" .. display_name .. "的血量",
			ru = "Показать здоровье:\n" .. display_name,
		}
	end
end

return localization
