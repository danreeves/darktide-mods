-- Show ammo amount from packs and tins
-- Description: Display numeric amount of ammo gained by ammo pack/tin, as well as amount lost due to overfill.
-- Author: groundskeeper Willie, raindish

local mod = get_mod("NumericUI")
local INTERACTIONS_HUD_DEF_PATH = "scripts/ui/hud/elements/interaction/hud_element_interaction_definitions"

local backups = mod:persistent_table("interactions_hud_backups")
backups.definitions = backups.definitions or table.clone(mod:original_require(INTERACTIONS_HUD_DEF_PATH))

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local Pickups = require("scripts/settings/pickup/pickups")

local current_ammo = nil
local max_ammo = nil
local small_clip_gain = 0
local large_clip_gain = 0

mod:hook_require(INTERACTIONS_HUD_DEF_PATH, function(instance)
	
	local ammo_description_size_mod = 0.9
	local description_text_style = table.clone(backups.definitions.widget_definitions.description_text.style.text)

	instance.widget_definitions.ammo_loss_description_text = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			value = " ",
			retained_mode = false,
			style = table.merge_recursive(table.clone(description_text_style), {
				font_size = description_text_style.font_size * ammo_description_size_mod,
				text_color = UIHudSettings.color_tint_ammo_high,
				text_horizontal_alignment = "center",
				text_vertical_alignment = "bottom",
				offset = {0,-6,0}
				
			}),
		},
	}, "description_box")
end)


mod:hook_safe("HudElementInteraction", "_setup_interaction_information", function(self, interactee_unit, interactee_extension, interactor_extension)
	
	if mod:get("show_ammo_amount_from_packs") then
		local interaction_widget = self._widgets_by_name.description_text

		if interaction_widget and max_ammo then
			local ammo_gain_widget = self._widgets_by_name.description_text
			local ammo_loss_widget = self._widgets_by_name.ammo_loss_description_text
			local hud_description = interactor_extension:hud_description()

			local missing_ammo = max_ammo - current_ammo
			local ammo_gain_text = ""
			local ammo_loss_text = ""

			if hud_description == "loc_pickup_consumable_small_clip_01" then
				if missing_ammo >= small_clip_gain then
					ammo_gain_text = string.format("  +%d", small_clip_gain)
					

				elseif missing_ammo > 0 then
					ammo_gain_text = string.format("  +%d", missing_ammo)
					ammo_loss_text = string.format("(%d)", (small_clip_gain - missing_ammo))
					ammo_loss_widget.style.text.offset[1] = 15*string.len(missing_ammo)
				end

			elseif hud_description == "loc_pickup_consumable_large_clip_01" then
				if missing_ammo >= large_clip_gain then
					ammo_gain_text = string.format("  +%d", large_clip_gain)

				elseif missing_ammo > 0 then
					ammo_gain_text = string.format("  +%d", missing_ammo)
					ammo_loss_text = string.format("(%d)", (large_clip_gain - missing_ammo))
					ammo_loss_widget.style.text.offset[1] = 15*string.len(missing_ammo) + 30 --The extra 30 is the size difference between "Ammo Tin" and "Ammo Pack"

				end
			end

			ammo_gain_widget.content.text = string.format("%s%s", ammo_gain_widget.content.text, ammo_gain_text)
			ammo_loss_widget.content.text = ammo_loss_text
			ammo_gain_widget.dirty = true
			ammo_loss_widget.dirty = true
		end
	end
end)

mod:hook_safe("HudElementPlayerWeapon","init", function(self,  amount, total_max_amount)
	if not self._ability_type then
		local slot_component = self._slot_component
		if slot_component then
			if self._uses_ammo or self._uses_overheat then
				local max_reserve = slot_component.max_ammunition_reserve
				local max_ammunition_clip = slot_component.max_ammunition_clip
				local pickup_data_small_clip = Pickups.by_name["small_clip"]
				local pickup_data_large_clip = Pickups.by_name["large_clip"]

				max_ammo = max_reserve + max_ammunition_clip
				current_ammo = max_ammo

				small_clip_gain = pickup_data_small_clip.ammo_amount_func(max_reserve, max_ammunition_clip, pickup_data_small_clip)
				large_clip_gain = pickup_data_large_clip.ammo_amount_func(max_reserve, max_ammunition_clip, pickup_data_large_clip)
			end
		end
	end
end)

mod:hook_safe("HudElementPlayerWeapon", "set_ammo_amount", function(self, total_ammo, total_max_ammo)
	if total_max_ammo == max_ammo then
		current_ammo = total_ammo
	end
end)