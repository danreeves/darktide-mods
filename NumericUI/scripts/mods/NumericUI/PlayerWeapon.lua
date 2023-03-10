-- Show maximum ammo
-- Description: Adds your max ammo to your HUD
-- Author: groundskeeper Willie

local mod = get_mod("NumericUI")
local UIWidget = mod:original_require("scripts/managers/ui/ui_widget")


local UIHudSettings = mod:original_require("scripts/settings/ui/ui_hud_settings")
local UIFontSettings = mod:original_require("scripts/managers/ui/ui_font_settings")
local UIHudSettings = mod:original_require("scripts/settings/ui/ui_hud_settings")
local HudElementPlayerWeaponSettings = mod:original_require("scripts/ui/hud/elements/player_weapon/hud_element_player_weapon_settings")
local HudElementPlayerWeaponHandlerSettings = mod:original_require("scripts/ui/hud/elements/player_weapon_handler/hud_element_player_weapon_handler_settings")
local HudElementTeamPlayerPanelSettings = mod:original_require(
	"scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_settings"
)

local ammo_icon_style = {
	vertical_alignment = "top",
	horizontal_alignment = "right",
	size = HudElementTeamPlayerPanelSettings.ammo_size,
	offset = {135,-102,0},
	default_color = UIHudSettings.color_tint_main_1
}

local ammo_text_style = {
	line_spacing = 0.9,
	font_size = 48,
	drop_shadow = false,
	font_type = "machine_medium",
	text_color = UIHudSettings.color_tint_main_1,
	offset = {
		-64,
		0,
		6
	},
	default_font_size = HudElementPlayerWeaponSettings.ammo_font_size_default,
	focused_font_size = HudElementPlayerWeaponSettings.ammo_font_size_focused,
	text_horizontal_alignment = "right",
	text_vertical_alignment = "top",
	vertical_alignment = "center",
	drop_shadow = false,
	clip_ammo = true
}

local ammo_spare_text_style = table.clone(ammo_text_style)
ammo_spare_text_style.offset = {
	0,
	0,
	7
}

ammo_spare_text_style.text_horizontal_alignment = "right"
ammo_spare_text_style.text_vertical_alignment = "top"
ammo_spare_text_style.vertical_alignment = "center"
ammo_spare_text_style.text_color = UIHudSettings.color_tint_main_3
ammo_spare_text_style.default_text_color = ammo_text_style.text_color
ammo_spare_text_style.default_font_size = HudElementPlayerWeaponSettings.ammo_font_size_default_small
ammo_spare_text_style.focused_font_size = HudElementPlayerWeaponSettings.ammo_font_size_focused_small
ammo_spare_text_style.clip_ammo = false

local ammo_max_text_style = table.clone(ammo_spare_text_style)
ammo_max_text_style.font_size = HudElementPlayerWeaponSettings.ammo_font_size_default_small * .8
ammo_max_text_style.clip_ammo = false
ammo_max_text_style.default_font_size = HudElementPlayerWeaponSettings.ammo_font_size_default_small * .8
ammo_max_text_style.focused_font_size = HudElementPlayerWeaponSettings.ammo_font_size_focused_small * .8
ammo_max_text_style.text_horizontal_alignment = "right"
ammo_max_text_style.text_vertical_alignment = "center"
ammo_max_text_style.vertical_alignment = "center"
ammo_max_text_style.drop_shadow = true
ammo_max_text_style.line_spacing = 1.0

local player_weapon_hud_def_path = "scripts/ui/hud/elements/player_weapon/hud_element_player_weapon_definitions"
local backup = nil


mod:hook_require(player_weapon_hud_def_path, function(instance)
	if backup == nil then
		backup = instance.widget_definitions
	end

	if mod:get("self_ammo_status") then
		instance.widget_definitions.self_ammo_status = UIWidget.create_definition({
			{
				value_id = "ammo_icon",
				style_id = "ammo_icon",
				pass_type = "texture",
				visible = false,
				value = "content/ui/materials/hud/icons/party_ammo",
				style = table.merge({
					index = 1
				}, ammo_icon_style)
			}
		}, "background")
	else
		instance.widget_definitions.self_ammo_status = nil
	end

	if mod:get("max_ammo_text") then
		instance.widget_definitions.ammo_text = UIWidget.create_definition({
			{
				value_id = "ammo_amount_1",
				style_id = "ammo_amount_1",
				pass_type = "text",
				value = "<ammo_amount_1>",
				style = table.merge({
					index = 1,
					primary_counter = true
				}, ammo_text_style)
			},
			{
				value_id = "ammo_amount_2",
				style_id = "ammo_amount_2",
				pass_type = "text",
				value = "<ammo_amount_2>",
				style = table.merge({
					index = 2,
					primary_counter = true
				}, ammo_text_style)
			},
			{
				value_id = "ammo_amount_3",
				style_id = "ammo_amount_3",
				pass_type = "text",
				value = "<ammo_amount_3>",
				style = table.merge({
					index = 3,
					primary_counter = true
				}, ammo_text_style)
			},
			{
				value_id = "ammo_spare_1",
				style_id = "ammo_spare_1",
				pass_type = "text",
				value = "",
				style = table.merge({
					index = 1
				}, ammo_spare_text_style)
			},
			{
				value_id = "ammo_spare_2",
				style_id = "ammo_spare_2",
				pass_type = "text",
				value = "",
				style = table.merge({
					index = 2
				}, ammo_spare_text_style)
			},
			{
				value_id = "ammo_spare_3",
				style_id = "ammo_spare_3",
				pass_type = "text",
				value = "",
				style = table.merge({
					index = 3
				}, ammo_spare_text_style)
			},
			{
				value_id = "ammo_max",
				style_id = "ammo_max",
				pass_type = "text",
				value = "",
				style = table.merge({
					index = 1
				}, ammo_max_text_style)
			},
		}, "background")
	else
		instance.widget_definitions.ammo_text = backup.widget_definitions.ammo_text
	end

end)


-- Initialize max ammo indicator
local PLAYER_WEAPON_HUD_DEF_PATH = "scripts/ui/hud/elements/player_weapon/hud_element_player_weapon_definitions"
local function weapon_init_with_max_ammo(func, self, parent, draw_layer, start_scale, definitions)
	if definitions == mod:original_require(PLAYER_WEAPON_HUD_DEF_PATH) then
		definitions.widget_definitions.ammo_text = mod:get("max_ammo_text")
	end
	return func(self, parent, draw_layer, start_scale, definitions)
end


local ammo_status = 3
local function update_max_ammo(func, self, dt, t, ui_renderer, render_settings, input_service)
	func(self, dt, t, ui_renderer, render_settings, input_service)

	if not self._ability_type then
		local slot_component = self._slot_component

		if slot_component then
			local widget = self._widgets_by_name.ammo_text

			if widget then
				if self._uses_ammo and not self._infinite_ammo then  
					local display_texts = "/" .. slot_component.max_ammunition_reserve
					local key = "ammo_max"
					widget.content[key] = display_texts or ""
					widget.style[key].offset = {32,25,9}
					
					if mod:get("self_ammo_status") and slot_component.max_ammunition_reserve > 10 then

						local icon_widget = self._widgets_by_name.self_ammo_status

						icon_widget.style["ammo_icon"].horizontal_alignment = "top"
						icon_widget.style["ammo_icon"].vertical_alignment = "left"
						icon_widget.style["ammo_icon"].offset = {128,2,0}
						
						local max_clip = slot_component.max_ammunition_clip or 0
						local max_reserve = slot_component.max_ammunition_reserve or 0
						local current_clip = slot_component.current_ammunition_clip or 0
						local current_reserve = slot_component.current_ammunition_reserve or 0
						
						local total_current_ammo = current_clip + current_reserve
						local total_max_ammo = max_clip + max_reserve
						local color = nil
						local weapon_ammo_fraction = 0

						if total_max_ammo > 0 then
							weapon_ammo_fraction = total_current_ammo / total_max_ammo
						end

						if weapon_ammo_fraction > 0.66 then
							color = icon_widget.style["ammo_icon"].default_color


						elseif weapon_ammo_fraction > 0.33 then
							color = UIHudSettings.color_tint_ammo_low


						elseif weapon_ammo_fraction > 0 then
							color = UIHudSettings.color_tint_ammo_medium


						else
							color = UIHudSettings.color_tint_ammo_high


						end

						icon_widget.style["ammo_icon"].color = color
						icon_widget.dirty = true

					else
						if self._widgets_by_name.self_ammo_status then
							self._widgets_by_name.self_ammo_status.alpha_multiplier = 0
							self._widgets_by_name.self_ammo_status.dirty = true
						end
					end

				else
					widget.content.text = ""
					if self._widgets_by_name.self_ammo_status then
						self._widgets_by_name.self_ammo_status.alpha_multiplier = 0
						self._widgets_by_name.self_ammo_status.dirty = true
					end
				end
				
				widget.dirty = true

			end
		end
	end
end

mod:hook("HudElementPlayerWeapon", "update", update_max_ammo)