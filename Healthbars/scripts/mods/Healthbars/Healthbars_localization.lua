local Breeds = require("scripts/settings/breed/breeds")

local localization = {
	mod_name = {
		en = "Healthbars",
		["zh-cn"] = "敌人血条",
		["zh-tw"] = "敵人血條",
		ru = "Полоски здоровья",
		fr = "Barres de santé",
	},
	mod_description = {
		en = "Show healthbars from the Psykanium in regular game modes",
		["zh-cn"] = "在常规游戏模式中也显示灵能室的血条",
		["zh-tw"] = "在一般遊戲模式中顯示靈能室的血條",
		ru = "Показывает полоски здоровья из Псайканиума в обычных режимах игры",
		fr = "Affiche les barres de santé du Psykhanium dans les modes de jeu normaux",
	},
	feature_toggles = {
		en = "Toggle features",
		["zh-cn"] = "开关功能",
		["zh-tw"] = "切換功能",
		ru = "Выключение функций",
		fr = "Fonctionnalités",
	},
	show_bar = {
		en = "Show health bar",
		["zh-cn"] = "显示血条",
		["zh-tw"] = "顯示血條",
		ru = "Полоски здоровья",
		fr = "Affiche les barres de santé",
	},
	show_damage_numbers = {
		en = "Show damage numbers",
		["zh-cn"] = "显示伤害数字",
		["zh-tw"] = "顯示傷害數字",
		ru = "Цифры урона",
		fr = "Affiche les points de dégâts",
	},
	show_dps = {
		en = "Show DPS report",
		["zh-cn"] = "显示 DPS 报告",
		["zh-tw"] = "顯示 DPS 報告",
		ru = "Отчёт Урон в секунду",
		fr = "Affiche les DPS",
	},
	post_kill_display_duration = {
		en = "Post-kill display duration (s)",
		["zh-cn"] = "击杀后显示时长（秒）",
		["zh-tw"] = "擊殺後顯示時長（秒）",
		ru = "Длительность после убийства (с)",
		fr = "Durée d'affichage après élimination (s)",
	},
	post_kill_display_duration_tooltip = {
		en = "Controls how long the healthbar, info label, and DPS report remain visible after an enemy dies. If the enemy body is removed sooner, the marker disappears with it.",
		["zh-cn"] = "控制敌人死亡后血条、信息标签和 DPS 报告保持显示的时长。如果敌人尸体更早被移除，标记也会随之消失。",
		["zh-tw"] = "控制敵人死亡後血條、資訊標籤和 DPS 報告保持顯示的時長。如果敵人屍體更早被移除，標記也會隨之消失。",
		ru = "Управляет тем, как долго после смерти врага видны полоска здоровья, информационная метка и отчёт DPS. Если тело врага исчезнет раньше, маркер исчезнет вместе с ним.",
		fr = "Contrôle la durée pendant laquelle la barre de santé, l'étiquette d'information et le rapport DPS restent visibles après la mort d'un ennemi. Si le corps disparaît plus tôt, le marqueur disparaît avec lui.",
	},
	show_armour_type = {
		en = "Show info label",
		["zh-cn"] = "显示信息标签",
		["zh-tw"] = "顯示資訊標籤",
		ru = "Показывать информационную метку",
		fr = "Afficher l'étiquette d'information",
	},
	show_armour_type_display = {
		en = "Label text",
		["zh-cn"] = "标签文字",
		["zh-tw"] = "標籤文字",
		ru = "Текст метки",
		fr = "Texte de l'étiquette",
	},
	display_armour_type = {
		en = "Armour type",
		["zh-cn"] = "护甲类型",
		["zh-tw"] = "護甲類型",
		ru = "Тип брони",
		fr = "Type d'armure",
	},
	display_enemy_name = {
		en = "Enemy name",
		["zh-cn"] = "敌人名称",
		["zh-tw"] = "敵人名稱",
		ru = "Название врага",
		fr = "Nom de l'ennemi",
	},
	horde_breeds = {
		en = "Horde/Roamer",
		["zh-cn"] = "群怪/游荡",
		["zh-tw"] = "群怪/遊蕩",
		ru = "Орда/бродяга",
		fr = "Horde/Rôdeur",
	},
	elite_breeds = {
		en = "Elite",
		["zh-cn"] = "精英",
		["zh-tw"] = "菁英",
		ru = "Элита",
		fr = "Élite",
	},
	special_breeds = {
		en = "Special",
		["zh-cn"] = "专家",
		["zh-tw"] = "專家",
		ru = "Специалист",
		fr = "Spécial",
	},
	monster_breeds = {
		en = "Monster/Captain",
		["zh-cn"] = "怪物/连长",
		["zh-tw"] = "怪物/連長",
		ru = "Монстр/капитан",
		fr = "Monstre/Capitaine",
	},
	ritualist_breeds = {
		en = "Ritualist",
		["zh-cn"] = "仪式师",
		["zh-tw"] = "儀式師",
		ru = "Ритуалист",
		fr = "Ritualiste",
	},
	bleed = {
		en = "Show bleed stacks",
		["zh-cn"] = "显示流血层数",
		["zh-tw"] = "顯示流血層數",
		ru = "Заряды кровотечения",
		fr = "Affiche les saignements",
	},
	burn = {
		en = "Show burn stacks",
		["zh-cn"] = "显示燃烧层数",
		["zh-tw"] = "顯示燃燒層數",
		ru = "Заряды горения",
		fr = "Affiche les brûlures",
	},
	warpfire = {
	en = "Show warpfire (Soulblaze) stacks",
	["zh-cn"] = "显示亚空间火焰（魂火）层数",
	["zh-tw"] = "顯示亞空間火焰（魂火）層數",
	ru = "Показывать стаки варп-огня (Soulblaze)",
	fr = "Afficher les cumuls de feu du Warp (Soulblaze)",
	},
	warpfire_color_option = {
		en = "Choose warpfire color",
		["zh-cn"] = "选择亚空间火焰颜色",
		["zh-tw"] = "選擇亞空間火焰顏色",
		ru = "Выбрать цвет варп-огня",
		fr = "Choisir la couleur du feu du Warp",
	},
	warpfire_color_option_one = {
		en = "Warp-Core",
		["zh-cn"] = "亚空间核心",
		["zh-tw"] = "亞空間核心",
		ru = "Варп-ядро",
		fr = "Cœur Warp",
	},
	warpfire_color_option_two = {
		en = "Soulblaze Cyan",
		["zh-cn"] = "魂火青色",
		["zh-tw"] = "魂火青色",
		ru = "Циан Soulblaze",
		fr = "Cyan Soulblaze",
	},
	warpfire_color_option_three = {
		en = "Sanctified Cerulean",
		["zh-cn"] = "圣化天蓝",
		["zh-tw"] = "聖化天藍",
		ru = "Освящённая лазурь",
		fr = "Céruléen sanctifié",
	},
	warpfire_color_option_four = {
		en = "Ethereal Blue",
		["zh-cn"] = "以太蓝",
		["zh-tw"] = "以太藍",
		ru = "Эфирный синий",
		fr = "Bleu éthéré",
	},
	warpfire_color_option_five = {
		en = "Peril Purple",
		["zh-cn"] = "危机紫",
		["zh-tw"] = "危機紫",
		ru = "Фиолетовая опасность",
		fr = "Violet péril",
	},
	toxin = {
		en = "Show toxin stacks",
		["zh-cn"] = "显示毒素层数",
		["zh-tw"] = "顯示毒素層數",
		ru = "Показывать стаки токсина",
		fr = "Afficher les cumuls de toxine",
	},
	dot_text_font_size = {
		en = "DOT stack number size",
		["zh-cn"] = "持续伤害层数字号",
		["zh-tw"] = "持續傷害層數字號",
		ru = "Размер числа стаков урона со временем",
		fr = "Taille du nombre de cumuls de dégâts sur la durée",
	},
	debuff_text_font_size = {
		en = "Debuff stack/time text size",
		["zh-cn"] = "减益层数/时间文字大小",
		["zh-tw"] = "減益層數/時間文字大小",
		ru = "Размер текста стаков/времени ослаблений",
		fr = "Taille du texte des cumuls/durées des affaiblissements",
	},
	dot_numbers_only = {
		en = "Show DOT numbers only",
		["zh-cn"] = "仅显示持续伤害数字",
		["zh-tw"] = "僅顯示持續傷害數字",
		ru = "Показывать только числа урона со временем",
		fr = "Afficher uniquement les nombres de dégâts sur la durée",
	},
	electrocuted = {
		en = "Show electrocution debuff",
		["zh-cn"] = "显示电击减益",
		["zh-tw"] = "顯示電擊減益",
		ru = "Показывать ослабление от поражения током",
		fr = "Afficher l'affaiblissement d'électrocution",
	},
	brittleness_indicator = {
		en = "Show brittleness indicator",
		["zh-cn"] = "显示脆弱指示器",
		["zh-tw"] = "顯示脆弱指示器",
		ru = "Показывать индикатор хрупкости",
		fr = "Afficher l'indicateur de fragilité",
	},
	brittleness_indicator_display = {
		en = "Brittleness display",
		["zh-cn"] = "脆弱显示方式",
		["zh-tw"] = "脆弱顯示方式",
		ru = "Отображение хрупкости",
		fr = "Affichage de la fragilité",
	},
	display_icon_text = {
		en = "Icon + text %%",
		["zh-cn"] = "图标 + 文字 %%",
		["zh-tw"] = "圖示 + 文字 %%",
		ru = "Значок + текст %%",
		fr = "Icône + texte %%",
	},
	skullcrusher = {
		en = "Show Skullcrusher debuff",
		["zh-cn"] = "显示碎颅者减益",
		["zh-tw"] = "顯示碎顱者減益",
		ru = "Показывать ослабление Skullcrusher",
		fr = "Afficher l'affaiblissement Skullcrusher",
	},
	skullcrusher_display = {
		en = "Skullcrusher display",
		["zh-cn"] = "碎颅者显示方式",
		["zh-tw"] = "碎顱者顯示方式",
		ru = "Отображение Skullcrusher",
		fr = "Affichage de Skullcrusher",
	},
	display_stacks = {
		en = "Stacks",
		["zh-cn"] = "层数",
		["zh-tw"] = "層數",
		ru = "Стаки",
		fr = "Cumuls",
	},
	display_percent = {
		en = "Percent %%",
		["zh-cn"] = "百分比 %%",
		["zh-tw"] = "百分比 %%",
		ru = "Процент %%",
		fr = "Pourcentage %%",
	},
	display_time = {
		en = "Time (s)",
		["zh-cn"] = "时间（秒）",
		["zh-tw"] = "時間（秒）",
		ru = "Время (с)",
		fr = "Temps (s)",
	},
	display_icon_only = {
		en = "Icon only",
		["zh-cn"] = "仅图标",
		["zh-tw"] = "僅圖示",
		ru = "Только значок",
		fr = "Icône uniquement",
	},
	thunderstrike = {
		en = "Show Thunderstrike debuff",
		["zh-cn"] = "显示雷击减益",
		["zh-tw"] = "顯示雷擊減益",
		ru = "Показывать ослабление Thunderstrike",
		fr = "Afficher l'affaiblissement Thunderstrike",
	},
	thunderstrike_display = {
		en = "Thunderstrike display",
		["zh-cn"] = "雷击显示方式",
		["zh-tw"] = "雷擊顯示方式",
		ru = "Отображение Thunderstrike",
		fr = "Affichage de Thunderstrike",
	},
	melee_damage_taken = {
		en = "Show Melee damage taken debuff",
		["zh-cn"] = "显示受到近战伤害提高减益",
		["zh-tw"] = "顯示受到近戰傷害提高減益",
		ru = "Показывать ослабление получаемого урона в ближнем бою",
		fr = "Afficher l'affaiblissement de dégâts de mêlée subis",
	},
	melee_damage_taken_display = {
		en = "Melee damage taken display",
		["zh-cn"] = "受到近战伤害显示方式",
		["zh-tw"] = "受到近戰傷害顯示方式",
		ru = "Отображение получаемого урона в ближнем бою",
		fr = "Affichage des dégâts de mêlée subis",
	},
	damage_taken = {
		en = "Show Increased damage taken debuff",
		["zh-cn"] = "显示受到伤害提高减益",
		["zh-tw"] = "顯示受到傷害提高減益",
		ru = "Показывать ослабление повышенного получаемого урона",
		fr = "Afficher l'affaiblissement de dégâts subis accrus",
	},
	damage_taken_display = {
		en = "Increased damage taken display",
		["zh-cn"] = "受到伤害提高显示方式",
		["zh-tw"] = "受到傷害提高顯示方式",
		ru = "Отображение повышенного получаемого урона",
		fr = "Affichage des dégâts subis accrus",
	},
	empyric_shock = {
		en = "Show Empyric Shock debuff",
		["zh-cn"] = "显示亚空间震击减益",
		["zh-tw"] = "顯示亞空間震擊減益",
		ru = "Показывать ослабление Empyric Shock",
		fr = "Afficher l'affaiblissement Empyric Shock",
	},
	empyric_shock_display = {
		en = "Empyric Shock display",
		["zh-cn"] = "亚空间震击显示方式",
		["zh-tw"] = "亞空間震擊顯示方式",
		ru = "Отображение Empyric Shock",
		fr = "Affichage d'Empyric Shock",
	},
}

local unlocalized_breeds = {
	chaos_lesser_mutated_poxwalker = {
		en = "Show Lesser mutated poxwalker health",
		["zh-cn"] = "显示变异瘟疫行者的血量",
		ru = "Показывать здоровье малого мутировавшего чумного ходока",
		fr = "Affiche la santé des scrofuleux inférieures muté",
	},
	chaos_mutated_poxwalker = {
		en = "Show Mutated poxwalker health",
		["zh-cn"] = "显示完全变异瘟疫行者的血量",
		ru = "Показывать здоровье мутировавшего чумного ходока",
		fr = "Affiche la santé des scrofuleux muté",
	},
}

for breed_name, breed in pairs(Breeds) do
	if breed.tags and breed.tags.minion then
		local display_name = Localize(breed.display_name)

		if string.find(display_name, "<unlocalized") then
			if unlocalized_breeds[breed_name] then
				localization[breed_name] = unlocalized_breeds[breed_name]
			else
				localization[breed_name] = {
					en = "Show " .. breed_name .. " health",
					["zh-cn"] = "显示" .. breed_name .. "的血量",
					["zh-tw"] = "顯示" .. breed_name .. "的血量",
					ru = "Показать здоровье:\n" .. breed_name,
					fr = "Affiche la santé de " .. breed_name,
				}
			end
		else
			localization[breed_name] = {
				en = "Show " .. display_name .. " health",
				["zh-cn"] = "显示" .. display_name .. "的血量",
				["zh-tw"] = "顯示" .. display_name .. "的血量",
				ru = "Показать здоровье:\n" .. display_name,
				fr = "Affiche la santé de " .. display_name,
			}
		end
	end
end

return localization
