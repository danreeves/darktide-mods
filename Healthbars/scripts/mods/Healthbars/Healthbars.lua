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
	toxin = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_nurgle",
}
mod.colors = {
	bleed = { 255, 255, 0, 0 },
	burn = { 255, 255, 102, 0 },
	toxin = { 255, 0, 255, 0 },
}

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
end

mod:hook_safe("HudElementWorldMarkers", "init", function(self)
	self._marker_templates[MarkerTemplate.name] = MarkerTemplate
end)

local show = {}

local function get_toggles()
	for breed_name in pairs(Breeds) do
		if string.match(breed_name, "mutator") then
			show[breed_name] = mod:get((breed_name):gsub("_mutator", ""))
		else
			show[breed_name] = mod:get(breed_name)
		end
	end
end

get_toggles()

mod.on_setting_changed = function()
	get_toggles()

	-- Update cached settings for all active healthbar markers
	local hud = Managers.ui and Managers.ui:get_hud()
	if hud then
		local world_markers_element = hud:element("HudElementWorldMarkers")
		if world_markers_element and world_markers_element._active_markers then
			for _, marker in pairs(world_markers_element._active_markers) do
				if marker.template_name == MarkerTemplate.name and marker.cached_settings then
					-- Update cached settings
					marker.cached_settings.show_damage_numbers = mod:get("show_damage_numbers")
					marker.cached_settings.show_dps = mod:get("show_dps")
					marker.cached_settings.show_armour_type = mod:get("show_armour_type")
					marker.cached_settings.show_bar = mod:get("show_bar")
					marker.cached_settings.bleed = mod:get("bleed")
					marker.cached_settings.burn = mod:get("burn")
					marker.cached_settings.toxin = mod:get("toxin")
				end
			end
		end
	end
end

local function should_enable_healthbar(unit)
	local game_mode_name = Managers.state.game_mode:game_mode_name()
	if game_mode_name == "shooting_range" and not get_mod("creature_spawner") then
		return false
	end

	local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
	local breed = unit_data_extension:breed()

	if show[breed.name] then
		return true
	end

	return false
end

mod:hook_safe(
	"HealthExtension",
	"init",
	function(_self, _extension_init_context, unit, _extension_init_data, _game_object_data)
		if should_enable_healthbar(unit) then
			Managers.event:trigger("add_world_marker_unit", MarkerTemplate.name, unit)
		end
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
		if should_enable_healthbar(unit) then
			Managers.event:trigger("add_world_marker_unit", MarkerTemplate.name, unit)
		end
	end
)
