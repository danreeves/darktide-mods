local mod = get_mod("NumericUI")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	allow_rehooking = true, -- Hooking objects in hook_require
	options = {
		widgets = {
			{
				setting_id = "team_hud_items",
				type = "group",
				sub_widgets = {
					{
						setting_id = "health_text",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "toughness_text",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "level",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "ammo_text",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "peril_text",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "peril_icon",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "ammo_as_percent",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "ability_cd_bar",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "ability_cd_text",
						type = "checkbox",
						default_value = true,
					},
				},
			},
			{
				setting_id = "dodge_count_items",
				type = "group",
				sub_widgets = {
					{
						setting_id = "dodge_count",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "dodges_count_up",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "show_efficient_dodges",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "fade_out_max_dodges",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "show_dodge_count_for_infinite_dodge",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "debug_dodge_count",
						type = "checkbox",
						default_value = false,
					},
				},
			},
			{
				setting_id = "player_ammo_items",
				type = "group",
				sub_widgets = {
					{
						setting_id = "max_ammo_text",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "show_ammo_icon",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "show_max_ammo_as_percent",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "show_munitions_gained",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "show_ammo_amount_from_packs",
						type = "checkbox",
						default_value = true,
					},
				},
			},
			{
				setting_id = "ability_items",
				type = "group",
				sub_widgets = {
					{
						setting_id = "ability_cooldown_format",
						type = "dropdown",
						default_value = "time",
						options = {
							{ text = "timer", value = "time" },
							{ text = "percent", value = "percent" },
							{ text = "none", value = "none" },
						},
					},
					{
						setting_id = "disable_ability_background_progress",
						type = "checkbox",
						default_value = true,
					},
				},
			},
			{
				setting_id = "mission_timer",
				type = "group",
				sub_widgets = {
					{
						setting_id = "show_mission_timer",
						type = "checkbox",
						default_value = true,
					},

					{
						setting_id = "mission_timer_in_overlay",
						type = "checkbox",
						default_value = true,
					},
				},
			},
			{
				setting_id = "nameplates",
				type = "group",
				sub_widgets = {
					{
						setting_id = "archetype_icons_in_nameplates",
						type = "checkbox",
						default_value = true,
					},
				},
			},
			-- {
			-- 	setting_id = "loading_screens",
			-- 	type = "group",
			-- 	sub_widgets = {
			-- 		{
			-- 			setting_id = "mission_title_on_intro",
			-- 			type = "checkbox",
			-- 			default_value = true,
			-- 		},
			-- 	},
			-- },
			{
				setting_id = "pickup_settings",
				type = "group",
				sub_widgets = {

					{
						setting_id = "show_medical_crate_radius",
						type = "checkbox",
						default_value = true,
					},
				},
			},
			{
				setting_id = "boss_health_settings",
				type = "group",
				sub_widgets = {

					{
						setting_id = "show_boss_health_numbers",
						type = "checkbox",
						default_value = true,
					},
				},
			},
		},
	},
}
