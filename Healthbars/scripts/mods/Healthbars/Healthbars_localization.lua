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
	ritualist_breeds = {
		en = "Ritualist",
		["zh-cn"] = "仪式师",
		ru = "Ритуалист",
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

-- for breed_name, breed in pairs(Breeds) do
	-- if breed.tags.minion then
		-- local display_name = Localize(breed.display_name)
		-- localization[breed_name] = {
			-- en = "Show " .. display_name .. " health",
			-- ["zh-cn"] = "显示" .. display_name .. "的血量",
			-- ru = "Показать здоровье:\n" .. display_name,
		-- }
	-- end
-- end

local manual_translations = {
  -- chaos_beast_of_nurgle = { zh = "纳垢兽", en = "Beast of Nurgle" },
  -- chaos_beast_of_nurgle_wk = { zh = "虚弱纳垢兽", en = "Beast of Nurgle (Weakened)" },
  -- chaos_daemonhost = { zh = "恶魔宿主", en = "Daemonhost" },
  -- chaos_hound = { zh = "瘟疫猎犬", en = "Pox Hound" },
  chaos_hound_mutator = { zh = "虚弱瘟疫猎犬", en = "Pox Hound Mutator" },
  chaos_lesser_mutated_poxwalker = { zh = "无甲行尸（更少的触手）", en = "Lesser Mutated Poxwalker" },
  chaos_mutated_poxwalker = { zh = "无甲行尸（触手）", en = "Mutated Poxwalker" },
  chaos_mutator_ritualist = { zh = "渣滓仪式师（浩劫宿主）", en = "Dreg Ritualist (Havoc)" },
  chaos_newly_infected = { zh = "感染行尸", en = "Groaner" },
  chaos_armored_infected = { zh = "莫比亚21团", en = "Armored Groaner" },
  chaos_ogryn_bulwark = { zh = "盾卫", en = "Bulwark" },
  chaos_ogryn_executor = { zh = "粉碎者", en = "Crusher" },
  chaos_ogryn_gunner = { zh = "收割者", en = "Reaper" },
  chaos_plague_ogryn = { zh = "瘟疫欧格林", en = "Plague Ogryn" },
  -- chaos_plague_ogryn_wk = { zh = "虚弱瘟疫欧格林", en = "Plague Ogryn (Weakened)" },
  -- chaos_plague_ogryn_sprayer = { zh = "喷雾欧格林", en = "Plague Ogryn Sprayer" },
  chaos_poxwalker = { zh = "无甲行尸", en = "Poxwalker" },
  chaos_poxwalker_bomber = { zh = "瘟疫爆破手", en = "Poxburster" },
  chaos_spawn = { zh = "混沌魔物", en = "Chaos Spawn" },
  -- chaos_spawn_wk = { zh = "虚弱混沌魔物", en = "Chaos Spawn (Weakened)" },
  cultist_assault = { zh = "渣滓枪兵", en = "Dreg Stalker" },
  -- cultist_berzerker = { zh = "渣滓狂暴者", en = "Dreg Rager" },
  cultist_captain = { zh = "渣滓连长", en = "Admonition Champion" },
  -- cultist_flamer = { zh = "渣滓剧毒火焰兵", en = "Dreg Tox Flamer" },
  -- cultist_grenadier = { zh = "渣滓剧毒轰炸者", en = "Dreg Tox Bomber" },
  -- cultist_gunner = { zh = "渣滓炮手", en = "Dreg Gunner" },
  cultist_melee = { zh = "渣滓暴徒", en = "Dreg Bruiser" },
  -- cultist_mutant = { zh = "变种人", en = "Mutant" },
  cultist_mutant_mutator = { zh = "虚弱变种人", en = "Mutant Mutator" },
  cultist_ritualist = { zh = "渣滓仪式师（黑暗传教团）", en = "Dreg Ritualist (Dark Communion)" },
  -- cultist_shocktrooper = { zh = "渣滓霰弹枪手", en = "Dreg Shotgunner" },
  renegade_assault = { zh = "血痂枪兵", en = "Scab Stalker" },
  -- renegade_berzerker = { zh = "血痂狂暴者", en = "Scab Rager" },
  renegade_captain = { zh = "血痂连长", en = "Scab Captain" },
  renegade_twin_captain = { zh = "远程双子罗丹", en = "Rodin Karnak" },
  renegade_twin_captain_two = { zh = "近战双子琳达", en = "Rinda Karnak" },
  -- renegade_executor = { zh = "血痂重锤兵", en = "Scab Mauler" },
  -- renegade_flamer = { zh = "血痂火焰兵", en = "Scab Flamer" },
  renegade_flamer_mutator = { zh = "活动血痂火焰兵", en = "Scab Flamer Mutator" },
  -- renegade_grenadier = { zh = "血痂轰炸者", en = "Scab Bomber" },
  -- renegade_gunner = { zh = "血痂炮手", en = "Scab Gunner" },
  renegade_radio_operator = { zh = "血痂电台操作员", en = "Scab Radio Operator" },
  renegade_melee = { zh = "血痂暴徒", en = "Scab Bruiser" },
  renegade_netgunner = { zh = "血痂陷阱手", en = "Scab Trapper" },
  renegade_rifleman = { zh = "血痂射手", en = "Scab Shooter" },
  renegade_shocktrooper = { zh = "血痂霰弹枪手", en = "Scab Shotgunner" },
  renegade_sniper = { zh = "血痂狙击手", en = "Scab Sniper" },
}


for breed_name, breed in pairs(Breeds) do
	if breed.tags and breed.tags.minion and not manual_translations[breed_name] then
		local display_name = Localize(breed.display_name or "")
		localization[breed_name] = {
			en = "Show " .. display_name .. " health",
			["zh-cn"] = "显示" .. display_name .. "的血量",
			ru = "Показать здоровье:\n" .. display_name,
		}
	end
end

for breed_name, names in pairs(manual_translations) do
	localization[breed_name] = {
		en = "Show " .. names.en .. " health",
		["zh-cn"] = "显示" .. names.zh .. "的血量",
		ru = "Показать здоровье:\n" .. names.en,
	}
end

return localization
