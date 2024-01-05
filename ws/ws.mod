return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ws` encountered an error loading the Darktide Mod Framework.")

		new_mod("ws", {
			mod_script       = "ws/scripts/mods/ws/ws",
			mod_data         = "ws/scripts/mods/ws/ws_data",
			mod_localization = "ws/scripts/mods/ws/ws_localization",
		})
	end,
	packages = {},
}
