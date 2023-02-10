local mod = get_mod("MinionStatus")
local MarkerTemplate = mod:io_dofile("MinionStatus/scripts/mods/MinionStatus/MinionStatusMarker")

mod:hook_safe("HudElementWorldMarkers", "init", function(self)
    self._marker_templates[MarkerTemplate.name] = MarkerTemplate
end)

mod:hook("UnitSpawnerManager", "spawn_network_unit", function(func, ...)
    local unit, gid = func(...)
    Managers.event:trigger("add_world_marker_unit", MarkerTemplate.name, unit)
    return unit, gid
end)

local function _get_hud()
    local ui_manager = Managers.ui
    local hud = ui_manager._hud or ui_manager._spectator_hud

    return hud
end
local function recreate_hud()
    local ui_manager = Managers.ui
    if ui_manager then
        local hud = _get_hud()
        if hud then
            local player_manager = Managers.player

            local player = player_manager:local_player(1)
            local peer_id = player:peer_id()
            local local_player_id = player:local_player_id()
            local elements = hud._element_definitions
            local visibility_groups = hud._visibility_groups

            ui_manager:destroy_player_hud()
            ui_manager:create_player_hud(peer_id, local_player_id, elements, visibility_groups)
        end
    end
end

recreate_hud()