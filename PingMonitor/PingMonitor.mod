return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`PingMonitor` encountered an error loading the Darktide Mod Framework.")

		new_mod("PingMonitor", {
			mod_script       = "PingMonitor/scripts/mods/PingMonitor/PingMonitor",
			mod_data         = "PingMonitor/scripts/mods/PingMonitor/PingMonitor_data",
			mod_localization = "PingMonitor/scripts/mods/PingMonitor/PingMonitor_localization",
		})
	end,
	packages = {},
}
