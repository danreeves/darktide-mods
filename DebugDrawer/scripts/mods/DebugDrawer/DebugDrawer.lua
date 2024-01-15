local mod = get_mod("DebugDrawer")
local DebugDrawerManager = mod:require("scripts/mods/DebugDrawer/modules/debug_drawer_manager")

local debug_drawer_manager =
	mod:persistent_table("debug_drawer_manager", DebugDrawerManager:new(Managers.world:world("level_world")))

-- Your mod code goes here.
-- https://vmf-docs.verminti.de
