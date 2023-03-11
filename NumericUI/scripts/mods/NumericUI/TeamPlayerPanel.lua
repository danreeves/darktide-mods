local mod = get_mod("NumericUI")
local TEAM_HUD_DEF_PATH = "scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions"

local backups = mod:persistent_table("team_hud_backups")
backups.team_hud_definitions = backups.team_hud_definitions or mod:original_require(TEAM_HUD_DEF_PATH)

local UIWidget = require("scripts/managers/ui/ui_widget")
local HudElementTeamPlayerPanelSettings = require(
	"scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_settings"
)
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local bar_size = HudElementTeamPlayerPanelSettings.size
local hud_body_font_setting_name = "hud_body"
local hud_body_font_settings = UIFontSettings[hud_body_font_setting_name]

local health_text_style = {
	horizontal_alignment = "left",
	font_size = 16,
	text_vertical_alignment = "center",
	text_horizontal_alignment = "right",
	vertical_alignment = "center",
	drop_shadow = true,
	font_type = "machine_medium",
	text_color = UIHudSettings.color_tint_main_2,
	offset = { 0, -2, 2 },
}

local tough_text_style = {
	horizontal_alignment = "left",
	font_size = 16,
	text_vertical_alignment = "center",
	text_horizontal_alignment = "right",
	vertical_alignment = "center",
	drop_shadow = true,
	font_type = "machine_medium",
	text_color = UIHudSettings.color_tint_main_2,
	offset = { 0, -6, 2 },
}

mod:hook_require(TEAM_HUD_DEF_PATH, function(instance)
	if mod:get("health_text") or mod:get("toughness_text") then
		instance.widget_definitions.coherency_indicator = UIWidget.create_definition({
			{
				value = "content/ui/materials/hud/icons/party_cohesion",
				style_id = "texture",
				pass_type = "texture",
				style = {
					vertical_alignment = "bottom",
					horizontal_alignment = "right",
					size = { 24, 24 },
					offset = { 54, 0, 8 },
					color = UIHudSettings.color_tint_main_1,
				},
			},
		}, "bar")
	else
		instance.widget_definitions.coherency_indicator =
			backups.team_hud_definitions.widget_definitions.coherency_indicator
	end

	if mod:get("ammo_text") then
		instance.widget_definitions.numeric_ui_ammo_text = UIWidget.create_definition({
			{
				value_id = "text",
				style_id = "text",
				pass_type = "text",
				value = "<ammo_count>",
				style = {
					default_font_size = 16,
					font_size = 16,
					text_vertical_alignment = "center",
					text_horizontal_alignment = "left",
					vertical_alignment = "center",
					offset = { 60, -16, 3 },
					size = { bar_size[1] * 1.5, bar_size[2] },
					font_type = hud_body_font_settings.font_type,
					text_color = UIHudSettings.color_tint_main_2,
					default_text_color = UIHudSettings.color_tint_main_2,
				},
			},
		}, "toughness_bar")
	else
		instance.widget_definitions.numeric_ui_ammo_text = nil
	end

	if mod:get("health_text") then
		instance.widget_definitions.health_text = UIWidget.create_definition({
			{
				value_id = "text_3",
				style_id = "text_3",
				pass_type = "text",
				value = "0",
				style = table.merge_recursive(table.clone(health_text_style), {
					index = 3,
					text_color = UIHudSettings.color_tint_main_1,
					default_color = UIHudSettings.color_tint_main_1,
					dimmed_color = UIHudSettings.color_tint_main_3,
					offset = { 28 },
				}),
			},
			{
				value_id = "text_2",
				style_id = "text_2",
				pass_type = "text",
				value = "0",
				style = table.merge_recursive(table.clone(health_text_style), {
					index = 2,
					text_color = UIHudSettings.color_tint_main_1,
					default_color = UIHudSettings.color_tint_main_1,
					dimmed_color = UIHudSettings.color_tint_main_3,
					offset = { 20 },
				}),
			},
			{
				value_id = "text_1",
				style_id = "text_1",
				pass_type = "text",
				value = "0",
				style = table.merge_recursive(table.clone(health_text_style), {
					index = 1,
					text_color = UIHudSettings.color_tint_main_1,
					default_color = UIHudSettings.color_tint_main_1,
					dimmed_color = UIHudSettings.color_tint_main_3,
					offset = { 12 },
				}),
			},
		}, "bar")
	else
		instance.widget_definitions.health_text = nil
	end

	if mod:get("toughness_text") then
		instance.widget_definitions.toughness_text = UIWidget.create_definition({
			{
				value_id = "text_3",
				style_id = "text_3",
				pass_type = "text",
				value = "0",
				style = table.merge_recursive(table.clone(tough_text_style), {
					index = 3,
					text_color = UIHudSettings.color_tint_6,
					default_color = UIHudSettings.color_tint_6,
					dimmed_color = UIHudSettings.color_tint_7,
					offset = { 28 },
				}),
			},
			{
				value_id = "text_2",
				style_id = "text_2",
				pass_type = "text",
				value = "0",
				style = table.merge_recursive(table.clone(tough_text_style), {
					index = 2,
					text_color = UIHudSettings.color_tint_6,
					default_color = UIHudSettings.color_tint_6,
					dimmed_color = UIHudSettings.color_tint_7,
					offset = { 20 },
				}),
			},
			{
				value_id = "text_1",
				style_id = "text_1",
				pass_type = "text",
				value = "0",
				style = table.merge_recursive(table.clone(tough_text_style), {
					index = 1,
					text_color = UIHudSettings.color_tint_6,
					default_color = UIHudSettings.color_tint_6,
					dimmed_color = UIHudSettings.color_tint_7,
					offset = { 12 },
				}),
			},
		}, "toughness_bar")
	else
		instance.widget_definitions.toughness_text = nil
	end
end)

local TEAM_PANEL_DEF_PATH = "scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions"
local function hud_init_with_features(
	func,
	self,
	parent,
	draw_layer,
	start_scale,
	data,
	definition_path,
	definition_settings
)
	if definition_path == TEAM_PANEL_DEF_PATH then
		definition_settings.feature_list.health_text = mod:get("health_text")
		definition_settings.feature_list.toughness_text = mod:get("toughness_text")
	end
	definition_settings.feature_list.level = mod:get("level")

	return func(self, parent, draw_layer, start_scale, data, definition_path, definition_settings)
end
mod:hook("HudElementPlayerPanelBase", "init", hud_init_with_features)

local function update_ammo_count(func, self, dt, t, player, ui_renderer)
	func(self, dt, t, player, ui_renderer)

	local widget = self._widgets_by_name.numeric_ui_ammo_text

	if widget then
		local extensions = self:_player_extensions(player)
		local unit_data_extension = extensions and extensions.unit_data

		if unit_data_extension then
			local weapon_slots = self._weapon_slots
			local total_current_ammo = 0
			local total_max_ammo = 0

			for i = 1, #weapon_slots do
				local slot_id = weapon_slots[i]
				local inventory_component = unit_data_extension:read_component(slot_id)

				if inventory_component then
					local max_clip = inventory_component.max_ammunition_clip or 0
					local max_reserve = inventory_component.max_ammunition_reserve or 0
					local current_clip = inventory_component.current_ammunition_clip or 0
					local current_reserve = inventory_component.current_ammunition_reserve or 0
					total_current_ammo = total_current_ammo + current_clip + current_reserve
					total_max_ammo = total_max_ammo + max_clip + max_reserve
				end
			end

			if total_max_ammo == 0 or self._show_as_dead or self._dead or self._hogtied then
				widget.content.text = ""
			else
				if mod:get("ammo_as_percent") then
					widget.content.text = string.format("%1d%%", (total_current_ammo / total_max_ammo) * 100)
				else
					widget.content.text = string.format("%1d/%1d", total_current_ammo, total_max_ammo)
				end
				widget.style.text.text_color = self._widgets_by_name.ammo_status.style.ammo.color
			end
			widget.dirty = true
		end
	end
end

mod:hook("HudElementPersonalPlayerPanel", "_update_player_features", update_ammo_count)
mod:hook("HudElementTeamPlayerPanel", "_update_player_features", update_ammo_count)
