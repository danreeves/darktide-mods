local mod = get_mod("DisableScreenEffects")
local MoodSettings = require("scripts/settings/camera/mood/mood_settings")
local mood_types = MoodSettings.mood_types

local BuffTemplates = require("scripts/settings/buff/buff_templates")

mod.screenspace_effects = {
	"corruptor_ambience",
	"content/fx/particles/screenspace/screen_stunned_light",
	"content/fx/particles/screenspace/screen_stunned_heavy",
	"content/fx/particles/screenspace/screen_blood_splatter",
}

local function localize(name)
	return {
		en = string.format("Disable %s", string.gsub(name, "_", " ")),
		["zh-cn"] = string.format("禁用 %s", string.gsub(name, "_", " ")),
		ru = string.format("Отключение %s", string.gsub(name, "_", " ")),
	}
end

local localization = {
	mod_name = {
		en = "Disable Screen Effects",
		["zh-cn"] = "禁用屏幕特效",
		ru = "Отключение экранных эффектов",
	},
	mod_description = {
		en = "Makes all screen effects toggleable",
		["zh-cn"] = "允许开关所有屏幕特效",
		ru = "Позволяет переключать видимость экранных эффектов",
	},
	disable_plasmagun = {
		en = "Disable plasmagun overheat",
		["zh-cn"] = "禁用等离子枪过热效果",
		ru = "Отключение перегрева плазмомёта",
	},
	chaos_daemonhost_ambience = {
		en = "Disable Daemonhost effects",
		["zh-cn"] = "禁用恶魔宿主效果",
		ru = "Отключение эффекта от Демонхоста",
	},
	[mod.screenspace_effects[4]] = {
		en = "Disable corruptor effects",
		["zh-cn"] = "禁用腐化效果",
		ru = "Отключение эффекта порчи",
	},
	[mod.screenspace_effects[1]] = {
		en = "Disable player stun distortion light",
		["zh-cn"] = "禁用玩家轻度眩晕效果",
		ru = "Отключение искажения света при оглушении игрока",
	},
	[mod.screenspace_effects[2]] = {
		en = "Disable player stun distortion heavy",
		["zh-cn"] = "禁用玩家重度眩晕效果",
		ru = "Отключение сильного искажения при оглушении игрока",
	},
	[mod.screenspace_effects[3]] = {
		en = "Disable blood splatter",
		["zh-cn"] = "禁用血液飞溅",
		ru = "Отключение брызг крови",
	},
}

for buff_name, template in pairs(BuffTemplates) do
	if template.player_effects then
		localization[buff_name] = localize(buff_name)
	end
end

for mood_type, _ in pairs(mood_types) do
	localization[mood_type] = localize(mood_type)
end

return localization
