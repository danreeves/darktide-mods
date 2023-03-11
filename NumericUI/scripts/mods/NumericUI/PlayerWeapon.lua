-- Show maximum ammo
-- Description: Adds your max ammo to your HUD
-- Author: groundskeeper Willie, raindish

local mod = get_mod("NumericUI")
local PLAYER_WEAPON_HUD_DEF_PATH = "scripts/ui/hud/elements/player_weapon/hud_element_player_weapon_definitions"

local backups = mod:persistent_table("player_weapon_hud_backups")
backups.definitions = backups.definitions or table.clone(mod:original_require(PLAYER_WEAPON_HUD_DEF_PATH))

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local HudElementTeamPlayerPanelSettings = require(
	"scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_settings"
)

mod:hook_require(PLAYER_WEAPON_HUD_DEF_PATH, function(instance)
	instance.widget_definitions.ammo_icon = UIWidget.create_definition({
		{
			value_id = "ammo_icon",
			style_id = "ammo_icon",
			pass_type = "texture",
			-- this gets set later because it's a retained UI and there would be a static copy otherwise
			-- value = "content/ui/materials/hud/icons/party_ammo",
			value = "content/ui/materials/hud/icons/weapon_icon_container",
			retained_mode = false,
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				size = HudElementTeamPlayerPanelSettings.ammo_size,
				offset = { -10, 0, 0 },
				color = UIHudSettings.color_tint_main_1,
			},
		},
	}, "background")

	local ammo_text_widget = table.clone(backups.definitions.widget_definitions.ammo_text)
	UIWidget.add_definition_pass(ammo_text_widget, {
		value_id = "max_ammo",
		style_id = "max_ammo",
		pass_type = "text",
		value = "",
		style = backups.definitions.widget_definitions.ammo_text.style.ammo_spare_1,
	})

	instance.widget_definitions.ammo_text = ammo_text_widget
end)

mod:hook_safe("HudElementPlayerWeapon", "update", function(self)
	if not self._ability_type then
		local slot_component = self._slot_component

		if slot_component then
			local ammo_text_widget = self._widgets_by_name.ammo_text
			local icon_widget = self._widgets_by_name.ammo_icon
			local uses_ammo = self._uses_ammo and not self._infinite_ammo

			if ammo_text_widget then
				local content = ammo_text_widget.content
				local style = ammo_text_widget.style
				ammo_text_widget.content.max_ammo = ""

				if uses_ammo and mod:get("max_ammo_text") then
					local display_text = "/" .. slot_component.max_ammunition_reserve

					content.max_ammo = display_text

					style.max_ammo.offset[1] = style.max_ammo.offset[1] + style.max_ammo.font_size * 2
					style.max_ammo.offset[2] = style.max_ammo.offset[2] + style.max_ammo.font_size
					style.max_ammo.drop_shadow = true
				end
			end

			if mod:get("show_ammo_icon") and icon_widget and uses_ammo then
				icon_widget.content.ammo_icon = "content/ui/materials/hud/icons/party_ammo"

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
					color = UIHudSettings.color_tint_main_1
				elseif weapon_ammo_fraction > 0.33 then
					color = UIHudSettings.color_tint_ammo_low
				elseif weapon_ammo_fraction > 0 then
					color = UIHudSettings.color_tint_ammo_medium
				else
					color = UIHudSettings.color_tint_ammo_high
				end

				icon_widget.style.ammo_icon.color = color
				icon_widget.dirty = true
			end
		end
	end
end)
