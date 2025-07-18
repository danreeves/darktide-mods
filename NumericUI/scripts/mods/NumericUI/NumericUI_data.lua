local mod = get_mod("NumericUI")

local color_options = {}
for _, color_name in ipairs(Color.list) do
  table.insert(color_options, {
    text = color_name,
    value = color_name
  })
end
table.sort(color_options, function(a, b)
  return a.text < b.text
end)

local function get_color_options()
  return table.clone(color_options)
end

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
				setting_id = "dodge_count_timer_items",
				type = "group",
				sub_widgets = {
					{
						setting_id = "dodge_timer",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "color_start",
						type = "dropdown",
						default_value = "ui_orange_light",
						options = get_color_options()
					},
					{
						setting_id = "color_end",
						type = "dropdown",
						default_value = "ui_red_light",
						options = get_color_options()
					},
					{
						setting_id = "dodge_timer_y_offset",
						type = "numeric",
						default_value = 30,
						range = {-50, 50},
						step_size_value = 2,
					},
					{
						setting_id = "dodge_timer_width",
						type = "numeric",
						default_value = 208,
						range = {0, 500},
						step_size_value = 4,
					},
					{
						setting_id = "dodge_timer_height",
						type = "numeric",
						default_value = 9,
						range = {0, 20},
					},
					{
						setting_id = "dodge_timer_hide_full",
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
						setting_id = "ammo_text_font_size",
						type = "numeric",
						default_value = 16,
						range = { 10, 150 },
						step_size_value = 1,
						change = function(new_value)
							mod:set("ammo_text_font_size", new_value)
						end,
						get = function()
							return mod:get("ammo_text_font_size") or 16
						end,
					},
					{
						setting_id = "ammo_text_offset_y",
						type = "numeric",
						default_value = -16,
						range = { -500, 500 },
						step_size_value = 1,
						change = function(new_value)
							mod:set("ammo_text_offset_y", new_value)
						end,
						get = function()
							return mod:get("ammo_text_offset_y") or -16
						end,
					},
					{
						setting_id = "ammo_text_offset_x",
						type = "numeric",
						default_value = 80,
						range = { -500, 500 },
						step_size_value = 1,
						change = function(new_value)
							mod:set("ammo_text_offset_x", new_value)
						end,
						get = function()
							return mod:get("ammo_text_offset_x") or 80
						end,
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
					{
						setting_id = "ability_cooldown_font_size",
						type = "numeric",
						default_value = 30,
						range = { 20, 50 },
						step_size_value = 1,
						change = function(new_value)
							mod:set("ability_cooldown_font_size", new_value)
						end,
						get = function()
							return mod:get("ability_cooldown_font_size") or 30
						end,
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
					{
						setting_id = "color_nameplate",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "companion_nameplates_icon",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "companion_nameplates_name",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "companion_nameplates_screen_clamp",
						type = "checkbox",
						default_value = true,
					},
				},
			},
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
			{
				setting_id = "marker_settings",
				type = "group",
				sub_widgets = {
					{
						setting_id = "show_ping_skull",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "show_vet_ping_skull",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "show_arb_ping_skull",
						type = "checkbox",
						default_value = true,
					},
				},
			},
		},
	},
}
