return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`DebugDrawer` encountered an error loading the Darktide Mod Framework.")

		new_mod("DebugDrawer", {
			mod_script       = "DebugDrawer/scripts/mods/DebugDrawer/DebugDrawer",
			mod_data         = "DebugDrawer/scripts/mods/DebugDrawer/DebugDrawer_data",
			mod_localization = "DebugDrawer/scripts/mods/DebugDrawer/DebugDrawer_localization",
		})
	end,
	packages = {},
}
