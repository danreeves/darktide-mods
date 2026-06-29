local mod = get_mod("Healthbars")
local Breeds = require("scripts/settings/breed/breeds")

local horde_and_roamers = {}
local elites = {}
local specials = {}
local monsters = {}
local ritualists = {}

local VANGUARD_BREEDS = {
	cultist_vanguard = true,
	renegade_vanguard = true,
}

local TAB_GENERAL = mod:localize("tab_general")
local TAB_DOT_DEBUFFS = mod:localize("tab_dot_debuffs")
local TAB_ENEMIES = mod:localize("tab_enemies")

local REQUIRED_ICON_PACKAGES = {
	"packages/ui/views/inventory_view/inventory_view",
	"packages/ui/views/inventory_weapons_view/inventory_weapons_view",
	"packages/ui/hud/player_weapon/player_weapon",
	"packages/ui/views/inventory_background_view/inventory_background_view",
	"packages/ui/views/character_appearance_view/character_appearance_view",
	"packages/ui/material_sets/circumstances",
}

mod.required_icon_packages = REQUIRED_ICON_PACKAGES

local ICON_WARPFIRE = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_ember"
local ICON_BLEED = "content/ui/materials/icons/presets/preset_13"
local ICON_CHORDCLAW_BLEED = "content/ui/materials/icons/item_types/scars"
local ICON_BURN = "content/ui/materials/icons/presets/preset_20"
local ICON_PHOSPHOR_BURN = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_rotten_armor"
local ICON_TOXIN = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_nurgle"
local ICON_BRITTLENESS = "content/ui/materials/icons/presets/preset_04"
local ICON_SKULLCRUSHER = "content/ui/materials/icons/presets/preset_05"
local ICON_THUNDERSTRIKE = "content/ui/materials/icons/presets/preset_18"
local ICON_MELEE_DAMAGE_TAKEN = "content/ui/materials/icons/presets/preset_01"
local ICON_DAMAGE_TAKEN = "content/ui/materials/icons/presets/preset_14"
local ICON_EMPYRIC_SHOCK = "content/ui/materials/icons/presets/preset_12"

local ICON_COLOUR_WHITE = { 255, 255, 255, 255 }
local ICON_COLOUR_BLEED = { 255, 255, 0, 0 }
local ICON_COLOUR_CHORDCLAW_BLEED = { 255, 255, 0, 0 }
local ICON_COLOUR_BURN = { 255, 255, 102, 0 }
local ICON_COLOUR_PHOSPHOR_BURN = { 255, 255, 130, 20 }
local ICON_COLOUR_TOXIN = { 255, 0, 255, 0 }
local ICON_COLOUR_WARPFIRE_ONE = { 255, 200, 255, 255 }
local ICON_COLOUR_WARPFIRE_TWO = { 255, 0, 230, 255 }
local ICON_COLOUR_WARPFIRE_THREE = { 255, 80, 160, 255 }
local ICON_COLOUR_WARPFIRE_FOUR = { 255, 45, 140, 255 }
local ICON_COLOUR_WARPFIRE_FIVE = { 255, 138, 43, 226 }

local function dropdown_option(text, value, icon, icon_colour)
	return {
		text = text,
		value = value,
		icon = icon,
		icon_colour = icon_colour,
	}
end

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

		if breed.tags.horde or breed.tags.roamer or VANGUARD_BREEDS[breed_name] then
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
		tab = TAB_GENERAL,
		sub_widgets = {
			{
				setting_id = "psykhanium_healthbar_behavior",
				type = "dropdown",
				default_value = "normal",
				tooltip = "psykhanium_healthbar_behavior_tooltip",
				options = {
					{ text = "psykhanium_healthbar_behavior_normal", value = "normal" },
					{ text = "psykhanium_healthbar_behavior_vanilla_only", value = "vanilla_only" },
					{ text = "psykhanium_healthbar_behavior_full_debug", value = "full_debug" },
				},
			},
			{
				setting_id = "show_bar",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_vanilla_boss_bar_indicators",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "post_kill_display_duration",
				type = "numeric",
				default_value = 1,
				range = { 0.2, 10 },
				decimals_number = 1,
				step_size_value = 0.2,
				tooltip = "post_kill_display_duration_tooltip",
			},
		},
	},
	{
		setting_id = "damage_number_settings",
		type = "group",
		tab = TAB_GENERAL,
		sub_widgets = {
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

						sub_widgets = {
							{
								setting_id = "show_armour_type_display",
								type = "dropdown",
								default_value = "armour_type",
								options = {
									{ text = "display_armour_type", value = "armour_type" },
									{ text = "display_enemy_name", value = "enemy_name" },
								},
							},
						},
					},
				},
			},
		},
	},
	{
		setting_id = "dot_debuff_settings",
		type = "group",
		tab = TAB_DOT_DEBUFFS,
		sub_widgets = {
			{
				setting_id = "bleed",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "bleed_display",
						type = "dropdown",
						default_value = "stacks",
						options = {
							dropdown_option("display_stacks", "stacks", ICON_BLEED, ICON_COLOUR_BLEED),
							dropdown_option("display_icon_only", "icon_only", ICON_BLEED, ICON_COLOUR_BLEED),
						},
					},
				},
			},
			{
				setting_id = "chordclaw_bleed",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "chordclaw_bleed_display",
						type = "dropdown",
						default_value = "stacks",
						options = {
							dropdown_option("display_stacks", "stacks", ICON_CHORDCLAW_BLEED,
								ICON_COLOUR_CHORDCLAW_BLEED),
							dropdown_option("display_time", "time", ICON_CHORDCLAW_BLEED,
								ICON_COLOUR_CHORDCLAW_BLEED),
						},
					},
				},
			},
			{
				setting_id = "burn",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "burn_display",
						type = "dropdown",
						default_value = "stacks",
						options = {
							dropdown_option("display_stacks", "stacks", ICON_BURN, ICON_COLOUR_BURN),
							dropdown_option("display_icon_only", "icon_only", ICON_BURN, ICON_COLOUR_BURN),
						},
					},
				},
			},
			{
				setting_id = "phosphor_burn",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "phosphor_burn_display",
						type = "dropdown",
						default_value = "icon_only",
						options = {
							dropdown_option("display_icon_only", "icon_only", ICON_PHOSPHOR_BURN,
								ICON_COLOUR_PHOSPHOR_BURN),
							dropdown_option("display_time", "time", ICON_PHOSPHOR_BURN,
								ICON_COLOUR_PHOSPHOR_BURN),
						},
					},
				},
			},
			{
				setting_id = "warpfire",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "warpfire_color_option",
						type = "dropdown",
						default_value = "warpfire_color_option_three",
						options = {
							dropdown_option("warpfire_color_option_one", "warpfire_color_option_one", ICON_WARPFIRE,
								ICON_COLOUR_WARPFIRE_ONE),
							dropdown_option("warpfire_color_option_two", "warpfire_color_option_two", ICON_WARPFIRE,
								ICON_COLOUR_WARPFIRE_TWO),
							dropdown_option("warpfire_color_option_three", "warpfire_color_option_three", ICON_WARPFIRE,
								ICON_COLOUR_WARPFIRE_THREE),
							dropdown_option("warpfire_color_option_four", "warpfire_color_option_four", ICON_WARPFIRE,
								ICON_COLOUR_WARPFIRE_FOUR),
							dropdown_option("warpfire_color_option_five", "warpfire_color_option_five", ICON_WARPFIRE,
								ICON_COLOUR_WARPFIRE_FIVE),
						},
					},
				},
			},
			{
				setting_id = "toxin",
				type = "checkbox",
				default_value = true,

				sub_widgets = {
					{
						setting_id = "toxin_display",
						type = "dropdown",
						default_value = "stacks",
						options = {
							dropdown_option("display_stacks", "stacks", ICON_TOXIN, ICON_COLOUR_TOXIN),
							dropdown_option("display_icon_only", "icon_only", ICON_TOXIN, ICON_COLOUR_TOXIN),
						},
					},
				},
			},
			{
				setting_id = "dot_text_font_size",
				type = "numeric",
				default_value = 14,
				range = { 10, 24 },
				step_size_value = 1,
			},
			{
				setting_id = "debuff_text_font_size",
				type = "numeric",
				default_value = 14,
				range = { 10, 24 },
				step_size_value = 1,
			},
			{
				setting_id = "dot_numbers_only",
				type = "checkbox",
				default_value = false,
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
							dropdown_option("display_stacks", "stacks", ICON_BRITTLENESS, ICON_COLOUR_WHITE),
							dropdown_option("display_icon_text", "icon_text", ICON_BRITTLENESS, ICON_COLOUR_WHITE),
							dropdown_option("display_icon_only", "icon_only", ICON_BRITTLENESS, ICON_COLOUR_WHITE),
							dropdown_option("display_time", "time", ICON_BRITTLENESS, ICON_COLOUR_WHITE),
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
				setting_id = "weapon_malfunction",
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
							dropdown_option("display_stacks", "stacks", ICON_SKULLCRUSHER, ICON_COLOUR_WHITE),
							dropdown_option("display_percent", "percent", ICON_SKULLCRUSHER, ICON_COLOUR_WHITE),
							dropdown_option("display_icon_only", "icon_only", ICON_SKULLCRUSHER, ICON_COLOUR_WHITE),
							dropdown_option("display_time", "time", ICON_SKULLCRUSHER, ICON_COLOUR_WHITE),
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
							dropdown_option("display_stacks", "stacks", ICON_THUNDERSTRIKE, ICON_COLOUR_WHITE),
							dropdown_option("display_percent", "percent", ICON_THUNDERSTRIKE, ICON_COLOUR_WHITE),
							dropdown_option("display_icon_only", "icon_only", ICON_THUNDERSTRIKE, ICON_COLOUR_WHITE),
							dropdown_option("display_time", "time", ICON_THUNDERSTRIKE, ICON_COLOUR_WHITE),
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
							dropdown_option("display_icon_text", "icon_text", ICON_MELEE_DAMAGE_TAKEN, ICON_COLOUR_WHITE),
							dropdown_option("display_icon_only", "icon_only", ICON_MELEE_DAMAGE_TAKEN, ICON_COLOUR_WHITE),
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
							dropdown_option("display_icon_text", "icon_text", ICON_DAMAGE_TAKEN, ICON_COLOUR_WHITE),
							dropdown_option("display_icon_only", "icon_only", ICON_DAMAGE_TAKEN, ICON_COLOUR_WHITE),
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
							dropdown_option("display_stacks", "stacks", ICON_EMPYRIC_SHOCK, ICON_COLOUR_WHITE),
							dropdown_option("display_percent", "percent", ICON_EMPYRIC_SHOCK, ICON_COLOUR_WHITE),
							dropdown_option("display_time", "time", ICON_EMPYRIC_SHOCK, ICON_COLOUR_WHITE),
						},
					},
				},
			},
		},
	},
	{
		setting_id = "horde_breeds",
		type = "group",
		tab = TAB_ENEMIES,
		sub_widgets = horde_and_roamers,
	},
	{
		setting_id = "elite_breeds",
		type = "group",
		tab = TAB_ENEMIES,
		sub_widgets = elites,
	},
	{
		setting_id = "special_breeds",
		type = "group",
		tab = TAB_ENEMIES,
		sub_widgets = specials,
	},
	{
		setting_id = "monster_breeds",
		type = "group",
		tab = TAB_ENEMIES,
		sub_widgets = monsters,
	},
	{
		setting_id = "ritualist_breeds",
		type = "group",
		tab = TAB_ENEMIES,
		sub_widgets = ritualists,
	},
}

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	required_icon_packages = REQUIRED_ICON_PACKAGES,
	options = {
		widgets = widgets,
	},
}
