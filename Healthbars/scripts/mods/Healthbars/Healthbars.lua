-- Healthbars
-- Description: Show healthbars from the Psykanium in regular game modes
-- Author: raindish
local mod = get_mod("Healthbars")
local Breeds = require("scripts/settings/breed/breeds")
local HealthExtension = require("scripts/extension_systems/health/health_extension")
local MarkerTemplate = mod:io_dofile("Healthbars/scripts/mods/Healthbars/HealthbarMarker")

mod.textures = {
	bleed = "content/ui/materials/icons/presets/preset_13",
	burn = "content/ui/materials/icons/presets/preset_20",
	warpfire = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_ember",
	toxin = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_nurgle",
	electrocuted = "content/ui/materials/icons/presets/preset_11",
	brittleness = "content/ui/materials/icons/presets/preset_04",
	skullcrusher = "content/ui/materials/icons/presets/preset_05",
	thunderstrike = "content/ui/materials/icons/presets/preset_18",
	melee_damage_taken = "content/ui/materials/icons/presets/preset_01",
	damage_taken = "content/ui/materials/icons/presets/preset_14",
	empyric_shock = "content/ui/materials/icons/presets/preset_12",
}
local WARPFIRE_COLOR_OPTIONS = {
	warpfire_color_option_one = { 255, 200, 255, 255 },
	warpfire_color_option_two = { 255, 0, 230, 255 },
	warpfire_color_option_three = { 255, 80, 160, 255 },
	warpfire_color_option_four = { 255, 45, 140, 255 },
	warpfire_color_option_five = { 255, 138, 43, 226 },
}

local ScriptUnit = ScriptUnit
local Managers = Managers
local ALIVE = ALIVE
local pairs = pairs
local setmetatable = setmetatable
local type = type
local string_match = string.match

local function copy_color(color)
	return { color[1], color[2], color[3], color[4] }
end

local function new_marker_cache()
	return setmetatable({}, { __mode = "k" })
end

mod._custom_marker_units = mod._custom_marker_units or new_marker_cache()

local function refresh_colors()
	local warpfire_key = mod:get("warpfire_color_option") or "warpfire_color_option_three"

	mod.colors = {
		bleed = { 255, 255, 0, 0 },
		burn = { 255, 255, 102, 0 },
		warpfire = copy_color(WARPFIRE_COLOR_OPTIONS[warpfire_key] or WARPFIRE_COLOR_OPTIONS.warpfire_color_option_three),
		toxin = { 255, 0, 255, 0 },
		electrocuted = { 255, 255, 235, 245 },
		-- brittleness, skullcrusher, thunderstrike and damage taken debuffs are calculated by applied stacks
	}
end

refresh_colors()

function mod.on_all_mods_loaded()
	-- Preload icon packages
	local function load_package(package_name)
		if not Managers.package:has_loaded(package_name) then
			Managers.package:load(package_name, "Healthbars")
		end
	end

	load_package("packages/ui/views/inventory_view/inventory_view")
	load_package("packages/ui/views/inventory_weapons_view/inventory_weapons_view")
	load_package("packages/ui/hud/player_weapon/player_weapon")
	load_package("packages/ui/views/inventory_background_view/inventory_background_view")
end

local show = {}

local function get_toggles()
	for breed_name in pairs(Breeds) do
		if string_match(breed_name, "mutator") then
			show[breed_name] = mod:get((breed_name):gsub("_mutator", ""))
		else
			show[breed_name] = mod:get(breed_name)
		end
	end
end

local function is_psykhanium()
	local game_mode_manager = Managers.state and Managers.state.game_mode
	return game_mode_manager and game_mode_manager:game_mode_name() == "shooting_range"
end

local function should_enable_healthbar(unit)
	if not ALIVE[unit] then
		return false
	end

	local unit_data_extension = ScriptUnit.has_extension(unit, "unit_data_system")
	if not unit_data_extension then
		return false
	end

	local breed = unit_data_extension:breed()
	return breed and show[breed.name] == true or false
end

local function add_custom_healthbar_marker(unit)
	if not should_enable_healthbar(unit) then
		return false
	end

	local event_manager = Managers.event
	if not event_manager then
		return false
	end

	local custom_marker_units = mod._custom_marker_units
	if custom_marker_units[unit] then
		return false
	end

	custom_marker_units[unit] = true
	event_manager:trigger("add_world_marker_unit", MarkerTemplate.name, unit)

	return true
end

local function visit_units_from_container(container, seen_units)
	if not container then
		return 0
	end

	local count = 0

	for key, value in pairs(container) do
		local unit = nil

		if ALIVE[key] then
			unit = key
		elseif type(value) == "table" then
			local value_unit = value._unit
			if ALIVE[value_unit] then
				unit = value_unit
			end
		end

		if unit and not seen_units[unit] then
			seen_units[unit] = true

			if add_custom_healthbar_marker(unit) then
				count = count + 1
			end
		end
	end

	return count
end

local function resync_existing_healthbars()
	local state_manager = Managers.state
	local extension_manager = state_manager and state_manager.extension
	if not extension_manager then
		return 0
	end

	local health_system = extension_manager:system("health_system")
	if not health_system then
		return 0
	end

	local seen_units = {}
	local added = 0

	added = added + visit_units_from_container(health_system._unit_to_extension_map, seen_units)
	added = added + visit_units_from_container(health_system._health_extensions, seen_units)
	added = added + visit_units_from_container(health_system._extensions, seen_units)

	return added
end

get_toggles()

mod.on_setting_changed = function()
	get_toggles()
	refresh_colors()
	resync_existing_healthbars()
end

mod:hook_safe("HudElementWorldMarkers", "init", function(self)
	self._marker_templates[MarkerTemplate.name] = MarkerTemplate
	mod._custom_marker_units = new_marker_cache()
	resync_existing_healthbars()
end)

mod:hook_safe(
	"HealthExtension",
	"init",
	function(_self, _extension_init_context, unit, _extension_init_data, _game_object_data)
		add_custom_healthbar_marker(unit)
	end
)

mod:hook_safe(
	"HuskHealthExtension",
	"init",
	function(self, _extension_init_context, unit, _extension_init_data, _game_session, _game_object_id, _owner_id)
		-- Make sure husks have the methods needed
		self.set_last_damaging_unit = HealthExtension.set_last_damaging_unit
		self.last_damaging_unit = HealthExtension.last_damaging_unit
		self.last_hit_zone_name = HealthExtension.last_hit_zone_name
		self.last_hit_was_critical = HealthExtension.last_hit_was_critical
		self.was_hit_by_critical_hit_this_render_frame = HealthExtension.was_hit_by_critical_hit_this_render_frame

		-- Set has a healthbar
		add_custom_healthbar_marker(unit)
	end
)

mod:hook("HudElementWorldMarkers", "event_add_world_marker_unit", function(func, self, marker_type, unit, callback, data)
	if marker_type == "damage_indicator" and is_psykhanium() and should_enable_healthbar(unit) then
		return
	end

	return func(self, marker_type, unit, callback, data)
end)
