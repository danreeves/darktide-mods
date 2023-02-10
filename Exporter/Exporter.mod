return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Exporter` encountered an error loading the Darktide Mod Framework.")

		new_mod("Exporter", {
			mod_script       = "Exporter/scripts/mods/Exporter/Exporter",
			mod_data         = "Exporter/scripts/mods/Exporter/Exporter_data",
			mod_localization = "Exporter/scripts/mods/Exporter/Exporter_localization",
		})
	end,
	packages = {},
}
