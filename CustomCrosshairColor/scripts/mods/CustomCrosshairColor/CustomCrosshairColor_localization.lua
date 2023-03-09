local mod = get_mod("CustomCrosshairColor")
local CrosshairSettings = require("scripts/ui/hud/elements/crosshair/hud_element_crosshair_settings")

mod.kinds = table.keys(CrosshairSettings.hit_indicator_colors)
mod.fields = { "r", "g", "b" }

local translations = {
	mod_description = {
		en = "Set your crosshair and hitmarkers to custom colors",
		["zh-cn"] = "自定义准星和击中标记的颜色",
	},
	crosshair_opacity = {
		en = "Crosshair opacity",
		["zh-cn"] = "准星不透明度",
	},
	crosshair_r = {
		en = "Crosshair R",
		["zh-cn"] = "准星红色",
	},
	crosshair_g = {
		en = "Crosshair G",
		["zh-cn"] = "准星绿色",
	},
	crosshair_b = {
		en = "Crosshair B",
		["zh-cn"] = "准星蓝色",
	},
}

function firstToUpper(str)
	return str:gsub("^%l", string.upper)
end

function underscoreToSpace(str)
	return str:gsub("_", " ")
end

for _, kind in ipairs(mod.kinds) do
	for _, field in ipairs(mod.fields) do
		translations[kind .. "_" .. field] = {
			en = underscoreToSpace(firstToUpper(kind)) .. " " .. firstToUpper(field),
		}
	end
end

return translations
