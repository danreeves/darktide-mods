-- NumericUI
-- Description: Adds numbers to your HUD
-- Author: raindish
local mod = get_mod("NumericUI")

local table_find_by_key = table.find_by_key
local table_insert = table.insert
local ipairs = ipairs
local pairs = pairs

local SETTINGS_SCHEMA_VERSION_ID = "settings_schema_version"
local SETTINGS_SCHEMA_VERSION = 1

-- The Blitz timer used to time the Hive Scum's Stimm as well, until the Stimm got settings of its own
local STIMM_SETTINGS_FROM_BLITZ = {
	blitz_cooldown_format = "stimm_cooldown_format",
	blitz_cooldown_font_size = "stimm_cooldown_font_size",
	blitz_cooldown_x_offset = "stimm_cooldown_x_offset",
	blitz_cooldown_y_offset = "stimm_cooldown_y_offset",
	disable_blitz_background_progress = "disable_stimm_background_progress",
}

-- Settings a release moved are copied over once, so the HUD looks the same after updating. DMF has saved the new
-- settings' defaults by now, and the Stimm defaults match the Blitz ones, so a fresh install keeps its defaults.
local function migrate_settings()
	local schema_version = mod:get(SETTINGS_SCHEMA_VERSION_ID)

	if type(schema_version) ~= "number" then
		schema_version = 0
	elseif schema_version >= SETTINGS_SCHEMA_VERSION then
		return
	end

	if schema_version < 1 then
		for blitz_setting_id, stimm_setting_id in pairs(STIMM_SETTINGS_FROM_BLITZ) do
			local value = mod:get(blitz_setting_id)

			if value ~= nil then
				mod:set(stimm_setting_id, value, false)
			end
		end
	end

	mod:set(SETTINGS_SCHEMA_VERSION_ID, SETTINGS_SCHEMA_VERSION, false)
end

mod:io_dofile("NumericUI/scripts/mods/NumericUI/utils")

migrate_settings()
mod:io_dofile("NumericUI/scripts/mods/NumericUI/TeamPlayerPanel")
mod:io_dofile("NumericUI/scripts/mods/NumericUI/PlayerAbility")
mod:io_dofile("NumericUI/scripts/mods/NumericUI/PlayerWeapon")
mod:io_dofile("NumericUI/scripts/mods/NumericUI/Interactions")
mod:io_dofile("NumericUI/scripts/mods/NumericUI/Nameplates")
mod:io_dofile("NumericUI/scripts/mods/NumericUI/MedicalCrate")
mod:io_dofile("NumericUI/scripts/mods/NumericUI/BossHealth")
mod:io_dofile("NumericUI/scripts/mods/NumericUI/PingMarkers")
mod:io_dofile("NumericUI/scripts/mods/NumericUI/CompanionNameplates")

local hud_elements = {
	{
		filename = "NumericUI/scripts/mods/NumericUI/HudElementDodgeCount",
		class_name = "HudElementDodgeCount",
		visibility_groups = {
			"tactical_overlay",
			"alive",
			"communication_wheel",
		},
	},
	{
		filename = "NumericUI/scripts/mods/NumericUI/HudElementMissionTimer",
		class_name = "HudElementMissionTimer",
		visibility_groups = {
			"tactical_overlay",
			"alive",
			"communication_wheel",
		},
	},
}

for _, hud_element in ipairs(hud_elements) do
	mod:add_require_path(hud_element.filename)
end

mod:hook("UIHud", "init", function(func, self, elements, visibility_groups, params)
	for _, hud_element in ipairs(hud_elements) do
		if not table_find_by_key(elements, "class_name", hud_element.class_name) then
			table_insert(elements, {
				class_name = hud_element.class_name,
				filename = hud_element.filename,
				use_hud_scale = true,
				visibility_groups = hud_element.visibility_groups or {
					"alive",
				},
			})
		end
	end

	return func(self, elements, visibility_groups, params)
end)

local function recreate_hud()
	local ui_manager = Managers.ui

	if not ui_manager or not ui_manager._hud then
		-- UI manager or HUD is not ready, waiting...
		return false
	end
	local player_manager = Managers.player
	local player = player_manager:local_player(1)
	if not player then
		-- Local player is not ready, waiting...
		return false
	end
	local hud = ui_manager._hud
	local peer_id = player:peer_id()
	local local_player_id = player:local_player_id()
	local elements = hud._element_definitions
	local visibility_groups = hud._visibility_groups

	hud:destroy()
	ui_manager:create_player_hud(peer_id, local_player_id, elements, visibility_groups)
	return true
end

local live_applied_settings = {
	dodge_count_x_offset = true,
	dodge_count_y_offset = true,
	dodge_timer_x_offset = true,
	dodge_timer_y_offset = true,
	dodge_timer_width = true,
	dodge_timer_height = true,
}

local RECREATE_HUD_DELAY = 0.25

local initialized = false
local recreate_hud_delay = 0
mod.update = function(dt)
	if mod._ability_active_timer_element then
		mod.update_ability_active_timer()
	end

	if initialized then
		return
	end

	if recreate_hud_delay > 0 then
		recreate_hud_delay = recreate_hud_delay - dt
		return
	end

	initialized = recreate_hud()
end

mod.on_all_mods_loaded = function()
	mod.flush_settings()

	initialized = false
	recreate_hud_delay = 0
	if mod:get("show_medical_crate_radius") then
		local package_name = "content/levels/training_grounds/missions/mission_tg_basic_combat_01"
		Managers.package:load(package_name, "NumericUI")
	end
end

mod.on_setting_changed = function(setting_id)
	mod.flush_settings()

	if live_applied_settings[setting_id] then
		mod._dodge_hud_dirty = true
		return
	end

	initialized = false
	recreate_hud_delay = RECREATE_HUD_DELAY
end

mod.on_game_state_changed = function(status, state)
	if state == "GameplayStateRun" then
		-- Mission-scoped caches (Havoc modifiers, ammo pickup preview) must not survive a mission.
		mod._havoc_ammo_modifier = nil
		mod._pickup_preview_dirty = false
	end
end
