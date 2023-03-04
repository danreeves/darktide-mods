local mod = get_mod("CustomCrosshairColor")

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
	for _, field in ipairs(mod.fields) do
		widgets[#widgets + 1] = {
			setting_id = kind .. "_" .. field,
			type = "numeric",
			default_value = 0,
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
