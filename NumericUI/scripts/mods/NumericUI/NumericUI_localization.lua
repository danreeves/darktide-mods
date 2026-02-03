local InputUtils = require("scripts/managers/input/input_utils")

local function readable(text)
	local readable_string = ""
	local tokens = string.split(text, "_")
	for _, token in ipairs(tokens) do
		local first_letter = string.sub(token, 1, 1)
		token = string.format("%s%s", string.upper(first_letter), string.sub(token, 2))
		readable_string = string.trim(string.format("%s %s", readable_string, token))
	end

	return readable_string
end

local loc = {
	mod_name = {
		en = "Numeric UI",
		ru = "Числовой интерфейс",
		["zh-cn"] = "数显界面",
		["zh-tw"] = "數位化介面",
		fr = "Numeric UI",
	},
	mod_description = {
		en = "Adds numbers to your HUD",
		["zh-cn"] = "在 HUD 上显示数字",
		["zh-tw"] = "在 HUD 上顯示數字",
		ru = "Numeric UI - Добавляет цифры в ваш интерфейс",
		fr = "Ajoute des données numériques utile à votre ATH",
	},
	ability_items = {
		en = "Ability Cooldown HUD",
		["zh-cn"] = "技能冷却 HUD",
		["zh-tw"] = "技能冷卻 HUD",
		ru = "Интерфейс перезарядки способностей",
		fr = "ATH du Temps de recharge des capacités",
	},
	player_ammo_items = {
		en = "Ammo HUD",
		["zh-cn"] = "弹药 HUD",
		["zh-tw"] = "彈藥 HUD",
		ru = "Интерфейс боеприпасов",
		fr = "ATH pour les quantités de munitions",
	},
	dodge_count_items = {
		en = "Dodge Count HUD",
		["zh-cn"] = "闪避计数 HUD",
		["zh-tw"] = "閃避計數 HUD",
		ru = "Интерфейс счётчика уклонений",
		fr = "ATH pour le nombre d'esquive",
	},
	dodge_count_timer_items = {
		-- Needs loc
		en = "Dodge Count Reset Timer HUD",
		["zh-cn"] = "闪避计数重置时间 HUD",
		["zh-tw"] = "閃避重置計時 HUD",
		fr = "ATH pour le temps de réinitialisation du nombre d'esquive",
	},
	team_hud_items = {
		en = "Team HUD",
		["zh-cn"] = "团队 HUD",
		["zh-tw"] = "團隊 HUD",
		ru = "Интерфейс команды",
		fr = "ATH pour l'équipe",
	},
	health_text = {
		en = "Show health text",
		["zh-cn"] = "显示生命值",
		["zh-tw"] = "顯示生命值",
		ru = "Показывать текст здоровья",
		fr = "Affiche la quantité de Santé",
	},
	toughness_text = {
		en = "Show toughness text",
		["zh-cn"] = "显示韧性值",
		["zh-tw"] = "顯示韌性值",
		ru = "Показывать текст стойкости",
		fr = "Affiche la quantité de Robustesse",
	},
	ability_cd_bar = {
		en = "Show team's ability cooldown as progress bar",
		["zh-cn"] = "显示团队技能冷却进度条",
		["zh-tw"] = "顯示團隊技能冷卻進度條",
		ru = "Показывать время восст. способности команды в виде полосы прогреccа",
		fr = "Affiche le temps de recharge des capacités avec une barre de progrès",
	},
	ability_cd_text = {
		en = "Show team's ability cooldown as numeric counter",
		["zh-cn"] = "显示团队技能冷却计数器",
		["zh-tw"] = "顯示團隊技能冷卻計數器",
		ru = "Показывать время восстановления способности команды в виде числа",
		fr = "Affiche le temps de recharge des capacités avec un compteur numérique",
	},
	level = {
		en = "Show level",
		["zh-cn"] = "显示等级",
		["zh-tw"] = "顯示等級",
		ru = "Показывать уровень",
		fr = "Affiche le niveau",
	},
	ammo_text = {
		en = "Show ammo text",
		["zh-cn"] = "显示弹药量",
		["zh-tw"] = "顯示彈藥量",
		ru = "Показывать текст боеприпасов",
		fr = "Affiche la quantité actuelle de munitions",
	},
	peril_icon = {
		en = "Show peril icon",
		["zh-cn"] = "显示危机值图标",
		["zh-tw"] = "顯示危機值圖示",
		ru = "Показывать значок опасности",
		fr = "Affiche l'icône du péril",
	},
	max_ammo_text = {
		en = "Show maximum ammo text",
		["zh-cn"] = "显示最大弹药量",
		["zh-tw"] = "顯示最大彈藥量",
		ru = "Показывать текст максимума боеприпасов",
		fr = "Affiche la quantité maximale de munition",
	},
	show_ammo_icon = {
		en = "Show icon for your own ammo",
		["zh-cn"] = "显示自己的弹药图标",
		["zh-tw"] = "顯示自己的彈藥圖示",
		ru = "Показывать иконку ваших боеприпасов",
		fr = "Affiche l'icône pour vos munitions",
	},
	show_munitions_gained = {
		en = "Show amount of ammo and grenades gained",
		["zh-cn"] = "显示获取的弹药数和手雷数",
		["zh-tw"] = "顯示獲得的彈藥數和手榴彈數",
		ru = "Показывать количество полученных боеприпасов и гранат",
		fr = "Affiche la quantité de munition et de grenade récupérée",
	},
	ammo_as_percent = {
		en = "Show ammo as percent",
		["zh-cn"] = "弹药量以百分比显示",
		["zh-tw"] = "彈藥量以百分比顯示",
		ru = "Показывать боеприпасы в процентах",
		fr = "Affiche les munitions en pourcentage",
	},
	show_ammo_amount_from_packs = {
		en = "Show ammo amount from packs and tins",
		["zh-cn"] = "显示弹药包内的弹药数",
		["zh-tw"] = "顯示彈藥包內的彈藥數",
		ru = "Показывать количество боеприпасов в контейнерах и коробках",
		fr = "Affiche les munitions contenus dans les boîtes de munitions",
	},
	dodge_count = {
		en = "Show dodge count",
		["zh-cn"] = "显示闪避计数",
		["zh-tw"] = "顯示閃避計數",
		ru = "Показывать количество уклонений",
		fr = "Affiche la quantité d'esquive",
	},
	dodge_timer = {
		-- Needs loc
		en = "Show dodge count reset timer",
		["zh-cn"] = "显示闪避计数重置时间",
		["zh-tw"] = "顯示閃避重置計時",
		fr = "Affiche une barre de progrès pour la réinitialisation du nombre d'esquive",
	},
	color_start = {
		-- Needs loc
		en = "Timer color - Start",
		["zh-cn"] = "计时器颜色 - 起始",
		["zh-tw"] = "計時顏色 - 開始",
		fr = "Couleur de la barre - Début",
	},
	color_start_description = {
		-- Needs loc
		en = "\nDefault value: UI Orange Light",
		["zh-cn"] = "\n默认值：UI Orange Light",
		["zh-tw"] = "\n預設：UI Orange Light",
		fr = "\nValeur par défaut : UI Orange Light",
	},
	color_end = {
		-- Needs loc
		en = "Timer color - End",
		["zh-cn"] = "计时器颜色 - 结束",
		["zh-tw"] = "計時顏色 - 結束",
		fr = "Couleur de la barre - Fin",
	},
	color_end_description = {
		-- Needs loc
		en = "\nDefault value: UI Red Light",
		["zh-cn"] = "\n默认值：UI Red Light",
		["zh-tw"] = "\n預設：UI Red Light",
		fr = "\nValeur par défaut : UI Red Light",
	},
	dodge_timer_y_offset = {
		-- Needs loc
		en = "Vertical offset",
		["zh-cn"] = "垂直偏移量",
		["zh-tw"] = "垂直偏移",
		fr = "Décalage vertical",
	},
	dodge_timer_y_offset_description = {
		-- Needs loc
		en = "\nDefault value: 30\n\nA higher vertical offset value moves the timer bar down",
		["zh-cn"] = "\n默认值：30\n\n增大垂直偏移量会使计时器向下移动",
		["zh-tw"] = "\n預設：30\n\n較高的垂直偏移值會使計時條向下移動",
		fr = "\nValeur par défaut : 30\n\nUn décalage plus grand déplace la barre vers le bas",
	},
	dodge_timer_width = {
		-- Needs loc
		en = "Width",
		["zh-cn"] = "宽度",
		["zh-tw"] = "寬度",
		fr = "Largeur",
	},
	dodge_timer_width_description = {
		-- Needs loc
		en = "\nDefault value: 208",
		["zh-cn"] = "\n默认值：208",
		["zh-tw"] = "\n預設：208",
		fr = "\nValeur par défaut : 208",
	},
	dodge_timer_height = {
		-- Needs loc
		en = "Height",
		["zh-cn"] = "高度",
		["zh-tw"] = "高度",
		fr = "Hauteur",
	},
	dodge_timer_height_description = {
		-- Needs loc
		en = "\nDefault value: 9",
		["zh-cn"] = "\n默认值：9",
		["zh-tw"] = "\n預設：9",
		fr = "\nValeur par défaut : 9",
	},
	dodge_timer_hide_full = {
		-- Needs loc
		en = "Hide dodge count reset timer when full",
		["zh-cn"] = "闪避计数重置时间为满时隐藏",
		["zh-tw"] = "閃避次數全滿時隱藏計時",
		fr = "Cacher la barre elle est au maximum",
	},
	debug_dodge_count = {
		en = "Show debug dodge info",
		["zh-cn"] = "显示闪避调试信息",
		["zh-tw"] = "顯示閃避除錯資訊",
		ru = "Показывать отладочную информацию уклонений",
		fr = "Affiche les informations interne pour l'esquive",
	},
	ability_cooldown_format = {
		en = "Ability cooldown format",
		["zh-cn"] = "主动能力冷却显示格式",
		["zh-tw"] = "戰鬥技能冷卻顯示格式",
		ru = "Формат перезарядки способностей",
		fr = "Format du Temps de recharge des capacités",
	},
	percent = {
		en = "Percent",
		["zh-cn"] = "百分比",
		["zh-tw"] = "百分比",
		ru = "Проценты",
		fr = "Pourcentage",
	},
	timer = {
		en = "Timer",
		["zh-cn"] = "等待时间",
		["zh-tw"] = "等待時間",
		ru = "Таймер",
		fr = "Temps",
	},
	none = {
		en = "None",
		["zh-cn"] = "不显示",
		["zh-tw"] = "不顯示",
		ru = "Нет",
		fr = "Rien",
	},
	dodges_count_up = {
		en = "Dodges count up",
		["zh-cn"] = "正向显示闪避次数",
		["zh-tw"] = "正向顯示閃避次數",
		ru = "Счётчик уклонений увеличивается",
		fr = "Affiche la récupération des esquives",
	},
	show_dodge_count_for_infinite_dodge = {
		en = "Show dodge count for infinite dodge weapons",
		["zh-cn"] = "无闪避上限的武器也显示闪避次数",
		["zh-tw"] = "無閃避上限的武器也顯示閃避次數",
		ru = "Показывать количество уклонений для оружия с бесконечным уклонением",
		fr = "Affiche la quantité d'esquive pour les armes à esquive infini",
	},
	disable_ability_background_progress = {
		en = "Disable ability background progress",
		["zh-cn"] = "禁用主动能力冷却图标彩色进度条",
		["zh-tw"] = "禁用技能背景冷卻進度條",
		ru = "Отключить визуальное увеличение шкалы способности на фоне",
		fr = "Désactiver l'avancée du temps de recharge en arrière-plan",
	},
	show_max_ammo_as_percent = {
		en = "Show max ammo as percent",
		["zh-cn"] = "最大弹药量以百分比显示",
		["zh-tw"] = "最大彈藥量以百分比顯示",
		ru = "Показать максимальный боезапас в процентах",
		fr = "Affiche la quantité maximale de munition en pourcentage",
	},
	mission_timer = {
		en = "Mission Timer",
		["zh-cn"] = "任务计时器",
		["zh-tw"] = "任務計時器",
		ru = "Таймер миссии",
		fr = "Temps de mission",
	},
	show_mission_timer = {
		en = "Show mission timer",
		["zh-cn"] = "显示任务计时器",
		["zh-tw"] = "顯示任務計時器",
		ru = "Показать таймер миссии",
		fr = "Affiche le temps de la mission",
	},
	mission_timer_in_overlay = {
		en = "Only in the overlay",
		["zh-cn"] = "仅在战术覆盖内显示",
		["zh-tw"] = "僅在戰術覆蓋中顯示",
		ru = "Только в оверлее",
		fr = "Affiche le temps seulement sur la fenêtre tactique",
	},
	nameplates = {
		en = "Nameplates",
		["zh-cn"] = "名称标签",
		["zh-tw"] = "名稱標籤",
		ru = "Таблички с именами",
		fr = "Nom d'affichage",
	},
	archetype_icons_in_nameplates = {
		en = "Use class icons in nameplates",
		["zh-cn"] = "在名称标签内使用职业图标",
		["zh-tw"] = "在名稱標籤內使用職業圖示",
		ru = "Использовать значки классов в табличках с именами",
		fr = "Utilise l'icône de classe dans le nom d'affichage",
	},
	color_nameplate = {
		en = "Colour nameplate text same as icon",
		["zh-cn"] = "使名称标签文本与图标颜色相同",
		["zh-tw"] = "名稱標籤文字與圖示顏色相同",
		ru = "Цвет текста таблички с именем совпадает с цветом значка",
		fr = "Le nom d'affichage est de la même couleur que l'icône",
	},
	show_efficient_dodges = {
		en = "Show number of efficient dodges",
		["zh-cn"] = "显示有效闪避数",
		["zh-tw"] = "顯示有效閃避次數",
		ru = "Показывать количество\nэффективных уклонений",
		fr = "Affiche le nombre d'esquive effective",
	},
	fade_out_max_dodges = {
		en = "Fade out when at max dodges",
		["zh-cn"] = "最大闪避数时隐藏",
		["zh-tw"] = "達到最大閃避次數時隱藏",
		ru = "Скрывать при максимальном количестве уклонений",
		fr = "S'efface en ayant le maximum d'esquive",
	},
	peril_text = {
		en = "Show peril percent text",
		["zh-cn"] = "显示危机值百分比文本",
		["zh-tw"] = "顯示反噬值百分比文字",
		ru = "Показывать проценты угрозы",
		fr = "Affiche le pourcentage de péril",
	},
	pickup_settings = {
		en = "Pickups",
		["zh-cn"] = "拾取物",
		["zh-tw"] = "拾取物",
		ru = "Размещаемые объекты",
		fr = "Consommables",
	},
	show_medical_crate_radius = {
		en = "Show medical crate radius",
		["zh-cn"] = "显示医疗箱范围",
		["zh-tw"] = "顯示醫療箱範圍",
		ru = "Показывать радиус медицинского контейнера",
		fr = "Affiche la zone de soin de la Caisse de soin",
	},
	show_medical_crate_radius_description = {
		en = "INCREASES MEMORY USE!",
		["zh-cn"] = "会增加内存占用！",
		["zh-tw"] = "會增加記憶體使用量！",
		ru = "УВЕЛИЧИВАЕТ ИСПОЛЬЗОВАНИЕ ПАМЯТИ!",
		fr = "Augmente l'utilisation de la mémoire vive",
	},
	boss_health_settings = {
		en = "Boss health",
		["zh-cn"] = "Boss 生命值",
		["zh-tw"] = "Boss 生命值",
		ru = "Здоровье босса",
		fr = "Barre de vie des Monstruosités",
	},
	show_boss_health_numbers = {
		en = "Show boss health numbers",
		["zh-cn"] = "显示 Boss 生命值数字",
		["zh-tw"] = "顯示 Boss 生命值數字",
		ru = "Показывать цифры здоровья босса",
		fr = "Affiche le nombre de point de vie des monstruosités",
	},
	marker_settings = {
		en = "Marker settings",
		["zh-cn"] = "标记设置",
		["zh-tw"] = "標記設定",
		ru = "Настройки маркера",
		fr = "Paramètre de marquage",
	},
	show_ping_skull = {
		en = "Show tag skull",
		["zh-cn"] = "显示标记骷髅图标",
		["zh-tw"] = "顯示標記骷髏圖示",
		ru = "Показывать череп пометки",
		fr = "Affiche le marqueur de crâne au dessus des ennemis",
	},
	show_vet_ping_skull = {
		en = "Show Veteran tag skull",
		["zh-cn"] = "显示老兵标记骷髅图标",
		["zh-tw"] = "顯示老兵標記骷髏圖示",
		ru = "Показывать череп пометки Ветерана",
		fr = 'Affiche le marqueur de crâne au dessus des ennemis de la clé de voûte "Ciblage" du Vétéran',
	},
	show_arb_ping_skull = {
		en = "Show Arbites tag skull",
		["zh-cn"] = "显示法务官标记骷髅图标",
		["zh-tw"] = "顯示法務官標記骷髏圖示",
	},
	ammo_text_font_size = {
		en = "Ammo text font size",
		ru = "Размер шрифта текста боеприпасов",
		["zh-cn"] = "弹药文本字体大小",
		["zh-tw"] = "彈藥文字字體大小",
	},
	ammo_text_offset_y = {
		en = "Ammo text offset Y",
		ru = "Смещение текста боеприпасов по вертикали",
		["zh-cn"] = "弹药文本 Y 轴偏移",
		["zh-tw"] = "彈藥文字 Y 軸偏移",
	},
	ammo_text_offset_x = {
		en = "Ammo text offset X",
		ru = "Смещение текста боеприпасов по горизонтали",
		["zh-cn"] = "弹药文本 X 轴偏移",
		["zh-tw"] = "彈藥文字 X 軸偏移",
	},
	ability_cooldown_font_size = {
		en = "Ability text font size",
		ru = "Размер шрифта текста способности",
		["zh-cn"] = "技能文本字体大小",
		["zh-tw"] = "技能文字字體大小",
	},
	companion_nameplates_icon = {
		en = "Show companion icon",
		["zh-cn"] = "显示伙伴图标",
		["zh-tw"] = "顯示電子獒犬圖示",
	},
	companion_nameplates_name = {
		en = "Show companion name",
		["zh-cn"] = "显示伙伴名称",
		["zh-tw"] = "顯示電子獒犬名稱",
	},
	companion_nameplates_screen_clamp = {
		en = "Clamp companion nameplates to screen",
		["zh-cn"] = "使伙伴名牌不超出屏幕边缘",
		["zh-tw"] = "將電子獒犬名稱標籤固定在螢幕內",
	},
}

local color_names = Color.list
for _, color_name in ipairs(color_names) do
	local color_values = Color[color_name](255, true)
	local text = InputUtils.apply_color_to_input_text(readable(color_name), color_values)
	loc[color_name] = {
		en = text
	}
end

return loc
