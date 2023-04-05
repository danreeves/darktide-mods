-- Show ammo amount from packs and tins
-- Description: Display numeric amount of ammo gained by ammo pack/tin, as well as amount lost due to overfill.
-- Author: groundskeeper Willie, raindish

local mod = get_mod("NumericUI")
local INTERACTIONS_HUD_DEF_PATH = "scripts/ui/hud/elements/interaction/hud_element_interaction_definitions"

local backups = mod:persistent_table("interactions_hud_backups")
backups.definitions = backups.definitions or table.clone(mod:original_require(INTERACTIONS_HUD_DEF_PATH))

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local Pickups = require("scripts/settings/pickup/pickups")
local mod = get_mod("NumericUI")

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
				text_horizontal_alignment = "left",
				text_vertical_alignment = "bottom",
				offset = { 0, -6, 0 },
			}),
		},
	}, "description_box")

end)

mod:hook_safe(
	"HudElementInteraction",
	"_setup_interaction_information",
	function(self, interactee_unit, interactee_extension, interactor_extension)
		if mod:get("show_ammo_amount_from_packs") then
			local ammo_gain_widget = self._widgets_by_name.description_text

			if ammo_gain_widget and mod.max_ammo then
				local ammo_loss_widget = self._widgets_by_name.ammo_loss_description_text
				local hud_description = interactor_extension:hud_description()
				local font_size = ammo_gain_widget.style.text.font_size
				local gap_size = font_size * 0.06

				local missing_ammo = mod.max_ammo - mod.current_ammo
				local ammo_gain_text = ""
				local ammo_loss_text = ""
				local x_offset = 0

				if hud_description == "loc_pickup_consumable_small_clip_01" then
					if missing_ammo >= mod.small_clip_gain then
						ammo_gain_text = string.format("  +%d", mod.small_clip_gain)
					elseif missing_ammo > 0 then
						ammo_gain_text = string.format("  +%d", missing_ammo)
						ammo_loss_text = string.format("(%d)", (mod.small_clip_gain - missing_ammo))

						local char_gap = (string.len(ammo_gain_text) - 1) * gap_size
						x_offset = (
								mod.ammo_text_width
								* string.len(string.format("%s%s", ammo_gain_widget.content.text, ammo_gain_text))
							) + char_gap
					end
				elseif hud_description == "loc_pickup_consumable_large_clip_01" then
					if missing_ammo >= mod.large_clip_gain then
						ammo_gain_text = string.format("  +%d", mod.large_clip_gain)
					elseif missing_ammo > 0 then
						ammo_gain_text = string.format("  +%d", missing_ammo)
						ammo_loss_text = string.format("(%d)", (mod.large_clip_gain - missing_ammo))

						local char_gap = (string.len(ammo_gain_text) - 1) * gap_size
						x_offset = (
								mod.ammo_text_width
								* string.len(string.format("%s%s", ammo_gain_widget.content.text, ammo_gain_text))
							) + char_gap
					end
				end

				ammo_gain_widget.content.text = string.format("%s%s", ammo_gain_widget.content.text, ammo_gain_text)
				ammo_loss_widget.content.text = ammo_loss_text
				ammo_loss_widget.style.text.offset[1] = x_offset
				ammo_gain_widget.dirty = true
				ammo_loss_widget.dirty = true
			end
		end
	end
)

mod:hook_safe("HudElementInteraction", "update", function(self, dt, t, ui_renderer, render_settings, input_service)
	if ammo_text_width == nil and mod:get("show_ammo_amount_from_packs") then
		local description_text_widget = self._widgets_by_name.description_text
		local font_type = description_text_widget.style.text.font_type
		local font_size = description_text_widget.style.text.font_size
		mod.ammo_text_width, mod.ammo_text_height = UIRenderer.text_size(ui_renderer, "0", font_type, font_size)
	end
end)