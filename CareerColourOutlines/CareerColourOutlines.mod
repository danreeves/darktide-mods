return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`CareerColourOutlines` encountered an error loading the Darktide Mod Framework.")

		new_mod("CareerColourOutlines", {
			mod_script       = "CareerColourOutlines/scripts/mods/CareerColourOutlines/CareerColourOutlines",
			mod_data         = "CareerColourOutlines/scripts/mods/CareerColourOutlines/CareerColourOutlines_data",
			mod_localization = "CareerColourOutlines/scripts/mods/CareerColourOutlines/CareerColourOutlines_localization",
		})
	end,
	packages = {},
}
