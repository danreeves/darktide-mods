-- Healthbars
-- Description: Show healthbars from the Psykanium in regular game modes
-- Author: raindish
local mod = get_mod("Healthbars")

local function should_enable_healthbar(unit)
	local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
	local breed = unit_data_extension:breed()
	local tags = breed.tags

	for tag, enabled in pairs(tags) do
		local key = "show_" .. tag
		if enabled and mod:get(key) then
			return true
		end
	end
end

mod:hook(
	"HealthExtension",
	"init",
	function(func, self, extension_init_context, unit, extension_init_data, game_object_data)
		-- Set has a healthbar
		if should_enable_healthbar(unit) then
			extension_init_data.has_health_bar = true
		end
		return func(self, extension_init_context, unit, extension_init_data, game_object_data)
	end
)

mod:hook(
	"HuskHealthExtension",
	"init",
	function(func, self, extension_init_context, unit, extension_init_data, game_session, game_object_id, owner_id)
		-- Set has a healthbar
		if should_enable_healthbar(unit) then
			extension_init_data.has_health_bar = true
		end

		-- Make sure husks have the methods needed
		self.set_last_damaging_unit = HealthExtension.set_last_damaging_unit
		self.last_damaging_unit = HealthExtension.last_damaging_unit
		self.last_hit_zone_name = HealthExtension.last_hit_zone_name
		self.last_hit_was_critical = HealthExtension.last_hit_was_critical

		return func(self, extension_init_context, unit, extension_init_data, game_session, game_object_id, owner_id)
	end
)
