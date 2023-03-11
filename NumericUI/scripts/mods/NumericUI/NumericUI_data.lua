local mod = get_mod("NumericUI")

return {
	name = "Numeric UI",
	description = mod:localize("mod_description"),
	is_togglable = true,
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
						setting_id = "ammo_as_percent",
						type = "checkbox",
						default_value = false,
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
		},
	},
}
