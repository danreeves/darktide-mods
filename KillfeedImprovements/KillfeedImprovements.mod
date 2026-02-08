return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`KillfeedImprovements` encountered an error loading the Darktide Mod Framework.")

		new_mod("KillfeedImprovements", {
			mod_script       = "KillfeedImprovements/scripts/mods/KillfeedImprovements/KillfeedImprovements",
			mod_data         = "KillfeedImprovements/scripts/mods/KillfeedImprovements/KillfeedImprovements_data",
			mod_localization = "KillfeedImprovements/scripts/mods/KillfeedImprovements/KillfeedImprovements_localization",
		})
	end,
	packages = {},
	version = "26.02.08-1",
	mod_id = "70"
}
