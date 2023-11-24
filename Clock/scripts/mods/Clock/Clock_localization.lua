require("scripts/foundation/utilities/color")

local FontDefinitions = require("scripts/managers/ui/ui_fonts_definitions")

function firstToUpper(str)
	return str:gsub("^%l", string.upper)
end

function underscoreToSpace(str)
	return str:gsub("_", " ")
end

local localizations = {
	mod_name = {
		en = "Clock",
		["zh-cn"] = "时钟",
	},
	mod_description = {
		en = "Adds a clock to the HUD",
		["zh-cn"] = "在 HUD 上添加时钟",
	},
	digital_clock = {
		en = "Digital clock font",
		["zh-cn"] = "数字时钟",
	},
	digital_clock_tooltip = {
		en = "Uses a special digital clock font for the numbers",
	},
	font_size = {
		en = "Font size",
		["zh-cn"] = "字号",
	},
	font = {
		en = "Font",
		["zh-cn"] = "字体",
	},
	color = {
		en = "Color",
		["zh-cn"] = "颜色",
	},
	twentyfour_hour = {
		en = "24 hour clock",
	},
}

for font_name, _ in pairs(FontDefinitions.fonts) do
	localizations[font_name] = {
		en = firstToUpper(underscoreToSpace(font_name)),
	}
end

for _, color_name in ipairs(Color.list) do
	local color = Color[color_name](255, true)
	local color_string = "{#color(" .. color[2] .. "," .. color[3] .. "," .. color[4] .. ")}"
	localizations[color_name] = {
		en = color_string .. firstToUpper(underscoreToSpace(color_name)),
	}
end

return localizations
