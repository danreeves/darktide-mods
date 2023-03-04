local mod = get_mod("CustomCrosshairColor")
local CrosshairSettings = require("scripts/ui/hud/elements/crosshair/hud_element_crosshair_settings")

mod.kinds = table.keys(CrosshairSettings.hit_indicator_colors)
mod.fields = { "r", "g", "b" }

local translations = {
	mod_description = {
		en = "Set your crosshair and hitmarkers to custom colors",
	},
	crosshair_opacity = {
		en = "Crosshair opacity",
	},
	crosshair_r = {
		en = "Crosshair R",
	},
	crosshair_g = {
		en = "Crosshair G",
	},
	crosshair_b = {
		en = "Crosshair B",
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
