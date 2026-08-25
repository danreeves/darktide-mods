-- NumericUI
-- Description: Adds numbers to your HUD
-- Author: raindish
local mod = get_mod("NumericUI")

mod:io_dofile("NumericUI/scripts/mods/NumericUI/utils")
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
		if not table.find_by_key(elements, "class_name", hud_element.class_name) then
			table.insert(elements, {
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
	initialized = false
	recreate_hud_delay = 0
	if mod:get("show_medical_crate_radius") then
		local package_name = "content/levels/training_grounds/missions/mission_tg_basic_combat_01"
		Managers.package:load(package_name, "NumericUI")
	end
end

mod.on_setting_changed = function(setting_id)
	if live_applied_settings[setting_id] then
		mod._dodge_hud_dirty = true
		return
	end

	initialized = false
	recreate_hud_delay = RECREATE_HUD_DELAY
end
