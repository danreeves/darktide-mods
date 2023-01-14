-- Healthbars
-- Description: Show healthbars from the Psykanium in regular game modes
-- Author: raindish
local mod = get_mod("Healthbars")

mod:hook("HealthExtension", "init",
    function(func, self, extension_init_context, unit, extension_init_data, game_object_data)
        -- Set has a healthbar
        extension_init_data.has_health_bar = true

        return func(self, extension_init_context, unit, extension_init_data, game_object_data)
    end)

mod:hook("HuskHealthExtension", "init",
    function(func, self, extension_init_context, unit, extension_init_data, game_session, game_object_id, owner_id)
        -- Set has a healthbar
        extension_init_data.has_health_bar = true

        -- Make sure husks have the methods needed
        self.set_last_damaging_unit = HealthExtension.set_last_damaging_unit
        self.last_damaging_unit = HealthExtension.last_damaging_unit
        self.last_hit_zone_name = HealthExtension.last_hit_zone_name
        self.last_hit_was_critical = HealthExtension.last_hit_was_critical

        return func(self, extension_init_context, unit, extension_init_data, game_session, game_object_id, owner_id)
    end)
