return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Sprays` encountered an error loading the Darktide Mod Framework.")

		new_mod("Sprays", {
			mod_script       = "Sprays/scripts/mods/Sprays/Sprays",
			mod_data         = "Sprays/scripts/mods/Sprays/Sprays_data",
			mod_localization = "Sprays/scripts/mods/Sprays/Sprays_localization",
		})
	end,
	packages = {},
}
