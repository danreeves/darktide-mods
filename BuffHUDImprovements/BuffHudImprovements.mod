return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`BuffHUDImprovements` encountered an error loading the Darktide Mod Framework.")

		new_mod("BuffHUDImprovements", {
			mod_script       = "BuffHUDImprovements/scripts/mods/BuffHUDImprovements/BuffHUDImprovements",
			mod_data         = "BuffHUDImprovements/scripts/mods/BuffHUDImprovements/BuffHUDImprovements_data",
			mod_localization = "BuffHUDImprovements/scripts/mods/BuffHUDImprovements/BuffHUDImprovements_localization",
		})
	end,
	packages = {},
}
