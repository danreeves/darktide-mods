local mod = get_mod("Healthbars")
local Breeds = require("scripts/settings/breed/breeds")

local horde_and_roamers = {}
local elites = {}
local specials = {}
local monsters = {}

local function add(tbl, breed_name, default_value)
	tbl[#tbl + 1] = {
		setting_id = breed_name,
		type = "checkbox",
		default_value = default_value,
	}
end

for breed_name, breed in pairs(Breeds) do
	if breed.tags.minion then
		local default_value = false
		if breed.tags.elite or breed.tags.special then
			default_value = true
		end

		if breed.tags.horde or breed.tags.roamer then
			add(horde_and_roamers, breed_name, default_value)
		elseif breed.tags.elite then
			add(elites, breed_name, default_value)
		elseif breed.tags.special then
			add(specials, breed_name, default_value)
		elseif breed.tags.monster or breed.tags.captain then
			add(monsters, breed_name, default_value)
		end
	end
end

local widgets = {
	{
		setting_id = "feature_toggles",
		type = "group",
		sub_widgets = {
			{
				setting_id = "show_bar",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_damage_numbers",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_dps",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_armour_type",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "damage_number_type",
				type = "dropdown",
				default_value = "readable",
				options = {
					{ text = "readable", value = "readable" },
					{ text = "floating", value = "floating" },
					{ text = "flashy", value = "flashy" },
				},
			},
			{
				setting_id = "max_distance",
				type = "numeric",
				default_value = 25,
				range = { 1, 100 },
			},
			-- {
			-- 	setting_id = "bleed",
			-- 	type = "checkbox",
			-- 	default_value = true,
			-- },
			-- {
			-- 	setting_id = "burn",
			-- 	type = "checkbox",
			-- 	default_value = true,
			-- },
		},
	},
	{
		setting_id = "horde_breeds",
		type = "group",
		sub_widgets = horde_and_roamers,
	},
	{
		setting_id = "elite_breeds",
		type = "group",
		sub_widgets = elites,
	},
	{
		setting_id = "special_breeds",
		type = "group",
		sub_widgets = specials,
	},
	{
		setting_id = "monster_breeds",
		type = "group",
		sub_widgets = monsters,
	},
}

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = widgets,
	},
}
