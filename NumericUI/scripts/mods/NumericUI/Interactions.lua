-- Show ammo amount from packs and tins
-- Description: Display numeric amount of ammo gained by ammo pack/tin, as well as amount lost due to overfill.
-- Author: groundskeeper Willie, raindish
local mod = get_mod("NumericUI")

local Pickups = require("scripts/settings/pickup/pickups")

local string_format = string.format
local pickup_ammo_amount = mod.pickup_ammo_amount
local split_pickup_ammo = mod.split_pickup_ammo
local weapon_ammo_totals = mod.weapon_ammo_totals

local small_clip_data = Pickups.by_name["small_clip"]
local large_clip_data = Pickups.by_name["large_clip"]

local SMALL_CLIP_DESCRIPTION = "loc_pickup_consumable_small_clip_01"
local LARGE_CLIP_DESCRIPTION = "loc_pickup_consumable_large_clip_01"

local function _update_pickup_description(self, interactor_extension)
	local description_widget = self._widgets_by_name.description_text
	local base_text = self._numericui_pickup_base_text
	local hud_description = self._numericui_pickup_hud_description

	if not description_widget or not base_text then
		return
	end

	if hud_description ~= SMALL_CLIP_DESCRIPTION and hud_description ~= LARGE_CLIP_DESCRIPTION then
		return
	end

	local player = Managers.player:local_player(1)
	local player_unit = player and player.player_unit

	if not player_unit then
		return
	end

	local ammo_reserve, max_ammo_reserve, ammo_clip, max_ammo_clip = weapon_ammo_totals(player_unit)

	if not ammo_reserve then
		return
	end

	local pickup_data = hud_description == SMALL_CLIP_DESCRIPTION and small_clip_data or large_clip_data
	local clip_gain = pickup_ammo_amount(pickup_data, max_ammo_reserve, max_ammo_clip)
	local ammo_gain, ammo_wasted =
		split_pickup_ammo(clip_gain, ammo_clip + ammo_reserve, max_ammo_reserve + max_ammo_clip)

	-- at full ammo the game only allows the pickup to refill a Zealot's Blades of Faith, and blocks it otherwise
	if ammo_gain == 0 and self._numericui_pickup_block_text then
		ammo_wasted = 0
	end

	local show_ammo_gain = ammo_gain > 0
	local show_ammo_wasted = ammo_wasted > 0
	local text

	if show_ammo_gain and show_ammo_wasted then
		text = string_format(
			"%s {#color(0,255,0,200);}(+%d) {#color(255,0,0,200);}(%d)",
			base_text,
			ammo_gain,
			ammo_wasted
		)
	elseif show_ammo_gain then
		text = string_format("%s {#color(0,255,0,200);}(+%d)", base_text, ammo_gain)
	elseif show_ammo_wasted then
		text = string_format("%s {#color(255,0,0,200);}(%d)", base_text, ammo_wasted)
	else
		text = base_text
	end

	if description_widget.content.text ~= text then
		description_widget.content.text = text
		description_widget.dirty = true
	end
end

mod:hook_safe(
	"HudElementInteraction",
	"_setup_interaction_information",
	function(self, _interactee_unit, _interactee_extension, interactor_extension, use_minimal_presentation)
	self._numericui_pickup_base_text = nil
	self._numericui_pickup_hud_description = nil

	if use_minimal_presentation or not mod.setting("show_ammo_amount_from_packs") then
		return
	end

	local hud_description = interactor_extension:hud_description()

	if hud_description ~= SMALL_CLIP_DESCRIPTION and hud_description ~= LARGE_CLIP_DESCRIPTION then
		return
	end

	local description_widget = self._widgets_by_name.description_text

	self._numericui_pickup_hud_description = hud_description
	self._numericui_pickup_base_text = description_widget and description_widget.content.text
	self._numericui_pickup_block_text = interactor_extension:hud_block_text()

	_update_pickup_description(self, interactor_extension)
	mod._pickup_preview_dirty = false
end)

mod:hook_safe("HudElementInteraction", "update", function(self)
	if not mod._pickup_preview_dirty then
		return
	end

	mod._pickup_preview_dirty = false

	local active_presentation_data = self._active_presentation_data

	if not active_presentation_data then
		return
	end

	_update_pickup_description(self, active_presentation_data.interactor_extension)
end)
