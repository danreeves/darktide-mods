-- Healthbars
-- Description: Show healthbars from the Psykanium in regular game modes
-- Author: raindish
local mod = get_mod("Healthbars")
local Breeds = require("scripts/settings/breed/breeds")
local HealthExtension = require("scripts/extension_systems/health/health_extension")

local MarkerTemplate = mod:io_dofile("Healthbars/scripts/mods/Healthbars/CopiedDamageIndicator")

mod.screen_offset_x = 0
mod.screen_offset_y = 0

mod:hook("HudElementWorldMarkers", "_get_screen_offset", function(func, self, scale)
	local x, y = func(self, scale)
	mod.screen_offset_x = x
	mod.screen_offset_y = y
	return x, y
end)

mod:hook_safe("HudElementWorldMarkers", "init", function(self)
	self._marker_templates[MarkerTemplate.name] = MarkerTemplate
	mod.marker_templates = self._marker_templates
end)

local show = {}

local function get_toggles()
	for breed_name in pairs(Breeds) do
		show[breed_name] = mod:get(breed_name)
	end
end

get_toggles()

function mod.on_setting_changed()
	get_toggles()

	MarkerTemplate = mod:io_dofile("Healthbars/scripts/mods/Healthbars/CopiedDamageIndicator")

	if mod.marker_templates then
		mod.marker_templates[MarkerTemplate.name] = MarkerTemplate
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
		-- Add custom healthbar marker
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

-- mod.textures = { bleed = "https://darkti.de/mod-assets/bleed.png", burn = "https://darkti.de/mod-assets/burn.png" }
-- mod.colors = { bleed = { 255, 255, 0, 0 }, burn = { 255, 255, 102, 0 } }

-- for k, v in pairs(mod.textures) do
-- 	Managers.url_loader:load_texture(v):next(function(data)
-- 		mod:echo("Loaded texture: " .. k)
-- 		mod.textures[k] = data.texture
-- 	end)
-- end
