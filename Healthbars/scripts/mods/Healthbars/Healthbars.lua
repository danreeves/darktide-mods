--[[-------------------------------------------------------------------------
Healthbars (v4_final)

Notes on this version:
  * The healthbar marker is spawned from HealthExtension/HuskHealthExtension init.
  * In live matches the 'unit_data_system' extension isn't guaranteed to exist at the exact hook moment,
    and units can be despawned quickly (especially in high-intensity fights).

This version adds defensive nil/extension checks before reading breed data.
That prevents rare-but-nasty crashes without changing the feature set.
---------------------------------------------------------------------------]]

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
end

local function should_enable_healthbar(unit)
	local game_mode_name = Managers.state.game_mode:game_mode_name()
	if game_mode_name == "shooting_range" and not get_mod("creature_spawner") then
		return false
	end

	-- BUGFIX: Defensive checks before touching unit extensions.
	-- Some units can be dead/despawned or missing unit_data_system at hook time.
	if not (unit and Unit.alive(unit)) then
		return false
	end
	
	if not ScriptUnit.has_extension(unit, "unit_data_system") then
		return false
	end
	
	local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
	if not unit_data_extension then
		return false
	end
	
	local breed = unit_data_extension:breed()
	if not breed then
		return false
	end

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
