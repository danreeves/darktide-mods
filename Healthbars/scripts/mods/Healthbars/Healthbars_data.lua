local mod = get_mod("Healthbars")
local Breeds = require("scripts/settings/breed/breeds")

local horde_and_roamers = {}
local elites = {}
local specials = {}
local monsters = {}
local ritualists = {}

local function add(tbl, breed_name, default_value)
	tbl[#tbl + 1] = {
		setting_id = breed_name,
		type = "checkbox",
		default_value = default_value,
	}
end

for breed_name, breed in pairs(Breeds) do
	if breed.tags.minion and not string.match(breed_name, "mutator") then
		local default_value = false
		if breed.tags.elite or breed.tags.special or breed.tags.ritualist then
			default_value = true
		end

		if breed.tags.horde or breed.tags.roamer then
			add(horde_and_roamers, breed_name, default_value)
		elseif breed.tags.elite then
			add(elites, breed_name, default_value)
		elseif breed.tags.special then
			add(specials, breed_name, default_value)
		elseif breed.tags.monster or breed.tags.captain or breed.tags.cultist_captain then
			add(monsters, breed_name, default_value)
		elseif breed.tags.ritualist then
			add(ritualists, breed_name, default_value)
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

				sub_widgets = {
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
				},
			},
			{
				setting_id = "bleed",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "burn",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "warpfire",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "toxin",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "brittleness_indicator",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "brittleness_indicator_display",
						type = "dropdown",
						default_value = "icon_text",
						options = {
							{ text = "display_icon_text", value = "icon_text" },
							{ text = "display_icon_only", value = "icon_only" },
							{ text = "display_time",      value = "time" },
						},
					},
				},
			},
			{
				setting_id = "electrocuted",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "skullcrusher",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "skullcrusher_display",
						type = "dropdown",
						default_value = "stacks",
						options = {
							{ text = "display_stacks",    value = "stacks" },
							{ text = "display_percent",   value = "percent" },
							{ text = "display_icon_only", value = "icon_only" },
						},
					}
				},
			},
			{
				setting_id = "thunderstrike",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "thunderstrike_display",
						type = "dropdown",
						default_value = "stacks",
						options = {
							{ text = "display_stacks",    value = "stacks" },
							{ text = "display_percent",   value = "percent" },
							{ text = "display_icon_only", value = "icon_only" },
						},
					},
				},
			},
			{
				setting_id = "melee_damage_taken",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "melee_damage_taken_display",
						type = "dropdown",
						default_value = "icon_only",
						options = {
							{ text = "display_icon_text", value = "icon_text" },
							{ text = "display_icon_only", value = "icon_only" },
						},
					}
				},
			},
			{
				setting_id = "damage_taken",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "damage_taken_display",
						type = "dropdown",
						default_value = "icon_text",
						options = {
							{ text = "display_icon_text", value = "icon_text" },
							{ text = "display_icon_only", value = "icon_only" },
						},
					},
				},
			},
			{
				setting_id = "empyric_shock",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "empyric_shock_display",
						type = "dropdown",
						default_value = "stacks",
						options = {
							{ text = "display_stacks",  value = "stacks" },
							{ text = "display_percent", value = "percent" },
							{ text = "display_time",    value = "time" },
						},
					},
				},
			},
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
	{
		setting_id = "ritualist_breeds",
		type = "group",
		sub_widgets = ritualists,
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
