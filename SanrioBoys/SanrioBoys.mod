return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`SanrioBoys` encountered an error loading the Darktide Mod Framework.")

		new_mod("SanrioBoys", {
			mod_script       = "SanrioBoys/scripts/mods/SanrioBoys/SanrioBoys",
			mod_data         = "SanrioBoys/scripts/mods/SanrioBoys/SanrioBoys_data",
			mod_localization = "SanrioBoys/scripts/mods/SanrioBoys/SanrioBoys_localization",
		})
	end,
	packages = {},
}
