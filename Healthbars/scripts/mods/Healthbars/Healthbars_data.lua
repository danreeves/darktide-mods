local mod = get_mod("Healthbars")

local widgets = {}

for i = 1, #mod.tags do
	local default_value = true
	-- Default to false for trash and monsters
	if i == 1 or i == 2 or i == 5 then
		default_value = false
	end
	widgets[i] = {
		setting_id = "show_" .. mod.tags[i],
		type = "checkbox",
		default_value = default_value,
	}
end

return {
	name = "Healthbars",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = widgets,
	},
}
