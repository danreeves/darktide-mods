local mod = get_mod("CustomCrosshairColor")
local CrosshairSettings = require("scripts/ui/hud/elements/crosshair/hud_element_crosshair_settings")

local widgets = {
	{
		setting_id = "crosshair_opacity",
		type = "numeric",
		default_value = 255,
		range = { 0, 255 },
	},
	{
		setting_id = "crosshair_r",
		type = "numeric",
		default_value = 255,
		range = { 0, 255 },
	},
	{
		setting_id = "crosshair_g",
		type = "numeric",
		default_value = 255,
		range = { 0, 255 },
	},
	{
		setting_id = "crosshair_b",
		type = "numeric",
		default_value = 255,
		range = { 0, 255 },
	},
}

for _, kind in ipairs(mod.kinds) do
	for i, field in ipairs(mod.fields) do
		-- +1 because the colors has alpha first but we only configure r,g,b
		local default = CrosshairSettings.hit_indicator_colors[kind][i + 1]
		widgets[#widgets + 1] = {
			setting_id = kind .. "_" .. field,
			type = "numeric",
			default_value = default,
			range = { 0, 255 },
		}
	end
end

return {
	name = "Custom Crosshair Color",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = widgets,
	},
}
