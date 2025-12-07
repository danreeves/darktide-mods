-- Show ammo amount from packs and tins
-- Description: Display numeric amount of ammo gained by ammo pack/tin, as well as amount lost due to overfill.
-- Author: groundskeeper Willie, raindish
local mod = get_mod("NumericUI")

local Pickups = require("scripts/settings/pickup/pickups")
local Havoc = require("scripts/utilities/havoc")
local HavocSettings = require("scripts/settings/havoc_settings")
local Ammo = require("scripts/utilities/ammo")

local small_clip_data = Pickups.by_name["small_clip"]
local large_clip_data = Pickups.by_name["large_clip"]

mod:hook_safe("HudElementInteraction", "update", function(self)
	if mod:get("show_ammo_amount_from_packs") then
		if self._active_presentation_data then
			local interactor_extension = self._active_presentation_data.interactor_extension
			local description_widget = self._widgets_by_name.description_text

			local hud_description = interactor_extension:hud_description()

			if hud_description == nil then
				return
			end

			local player = Managers.player:local_player(1)
			local player_unit = player.player_unit
			local unit_data_ext = ScriptUnit.extension(player_unit, "unit_data_system")
			local visual_loadout_extension = ScriptUnit.extension(player_unit, "visual_loadout_system")
			local weapon_slot_configuration = visual_loadout_extension:slot_configuration_by_type("weapon")
			local ammo_modifier = 1
			if Managers.mechanism._mechanism then
				local mechanism_data = Managers.mechanism._mechanism._mechanism_data
				if mechanism_data.havoc_data then
					local parsed = Havoc.parse_data(mechanism_data.havoc_data)
					if parsed.modifiers then
						for _, modifier in ipairs(parsed.modifiers) do
							if modifier.name == "ammo_pickup_modifier" then
								ammo_modifier = HavocSettings.modifier_templates.ammo_pickup_modifier[modifier.level].ammo_pickup_modifier or 1
							end
						end
					end
				end
			end

			local max_ammo_reserve = 0
			local ammo_reserve = 0
			local ammo_clip = 0
			local max_ammo_clip = 0

			for slot_name in pairs(weapon_slot_configuration) do
				local wieldable_component = unit_data_ext:write_component(slot_name)
				if wieldable_component.max_ammunition_reserve > 0 then
					ammo_reserve = Ammo.current_ammo_in_reserve(wieldable_component)
					max_ammo_reserve = Ammo.max_ammo_in_reserve(wieldable_component)
					ammo_clip = Ammo.current_ammo_in_clips(wieldable_component)
					max_ammo_clip = Ammo.max_ammo_in_clips(wieldable_component)
					break
				end
			end

			local max_ammo = max_ammo_reserve + max_ammo_clip
			local current_ammo = ammo_clip + ammo_reserve

			small_clip_data.modifier = ammo_modifier
			large_clip_data.modifier = ammo_modifier

			local small_clip_gain = small_clip_data.ammo_amount_func(max_ammo_reserve, max_ammo_clip, small_clip_data)
			local large_clip_gain = large_clip_data.ammo_amount_func(max_ammo_reserve, max_ammo_clip, large_clip_data)

			if description_widget and max_ammo then
				local missing_ammo = max_ammo - current_ammo
				local ammo_gain = 0
				local ammo_wasted = 0

				if hud_description == "loc_pickup_consumable_small_clip_01" then
					if missing_ammo >= small_clip_gain then
						ammo_gain = small_clip_gain
					elseif missing_ammo > 0 then
						ammo_gain = missing_ammo
						ammo_wasted = small_clip_gain - missing_ammo
					end
				elseif hud_description == "loc_pickup_consumable_large_clip_01" then
					if missing_ammo >= large_clip_gain then
						ammo_gain = large_clip_gain
					elseif missing_ammo > 0 then
						ammo_gain = missing_ammo
						ammo_wasted = large_clip_gain - missing_ammo
					end
				end

				local show_ammo_gain = ammo_gain > 0
				local show_ammo_wasted = ammo_wasted > 0

				local desc_str = show_ammo_gain
						and show_ammo_wasted
						and "%s {#color(0,255,0,200);}(+%d) {#color(255,0,0,200);}(%d)"
					or show_ammo_gain and not show_ammo_wasted and "%s {#color(0,255,0,200);}(+%d)"
					or "%s"

				description_widget.content.text =
					string.format(desc_str, Localize(hud_description), ammo_gain, ammo_wasted)
				description_widget.dirty = true
			end
		end
	end
end)
