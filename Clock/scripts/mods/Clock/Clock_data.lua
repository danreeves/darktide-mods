require("scripts/foundation/utilities/color")

local mod = get_mod("Clock")
local FontDefinitions = require("scripts/managers/ui/ui_fonts_definitions")

local font_options = {}
for font_name, _ in pairs(FontDefinitions.fonts) do
	table.insert(font_options, {
		text = font_name,
		value = font_name,
	})
end

local color_options = {}
for _, color in ipairs(Color.list) do
	table.insert(color_options, {
		text = color,
		value = color,
	})
end

return {
	name = "Clock",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "digital_clock",
				type = "checkbox",
				default_value = false,
			},
			{
				setting_id = "font_size",
				type = "numeric",
				default_value = 25,
				range = { 0, 255 },
			},
			{
				setting_id = "font",
				type = "dropdown",
				default_value = font_options[1].value,
				options = font_options,
			},
			{
				setting_id = "color",
				type = "dropdown",
				default_value = "white",
				options = color_options,
			},
		},
	},
}
