local mod = get_mod("PingMonitor")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "always_visible",
				type = "checkbox",
				default_value = false,
				tooltip = "always_visible_tooltip",
			},
			{
				setting_id = "averaging_samples",
				type = "numeric",
				default_value = 30,
				range = { 1, 120 },
				decimals_number = 0,
				tooltip = "averaging_samples_tooltip",
			},
			{
				setting_id = "widget_position",
				type = "group",
				sub_widgets = {
					{
						setting_id = "position_anchor",
						type = "dropdown",
						default_value = "top_center",
						tooltip = "position_anchor_tooltip",
						options = {
							{ text = "anchor_top_left", value = "top_left" },
							{ text = "anchor_top_center", value = "top_center" },
							{ text = "anchor_top_right", value = "top_right" },
							{ text = "anchor_center_left", value = "center_left" },
							{ text = "anchor_center", value = "center" },
							{ text = "anchor_center_right", value = "center_right" },
							{ text = "anchor_bottom_left", value = "bottom_left" },
							{ text = "anchor_bottom_center", value = "bottom_center" },
							{ text = "anchor_bottom_right", value = "bottom_right" },
						},
					},
					{
						setting_id = "position_x",
						type = "numeric",
						default_value = 0,
						range = { -4000, 4000 },
						decimals_number = 0,
						tooltip = "position_x_tooltip",
					},
					{
						setting_id = "position_y",
						type = "numeric",
						default_value = 12,
						range = { -2200, 2200 },
						decimals_number = 0,
						tooltip = "position_y_tooltip",
					},
				},
			},
		},
	},
}
