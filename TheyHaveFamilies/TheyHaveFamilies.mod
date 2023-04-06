return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`TheyHaveFamilies` encountered an error loading the Darktide Mod Framework.")

		new_mod("TheyHaveFamilies", {
			mod_script       = "TheyHaveFamilies/scripts/mods/TheyHaveFamilies/TheyHaveFamilies",
			mod_data         = "TheyHaveFamilies/scripts/mods/TheyHaveFamilies/TheyHaveFamilies_data",
			mod_localization = "TheyHaveFamilies/scripts/mods/TheyHaveFamilies/TheyHaveFamilies_localization",
		})
	end,
	packages = {},
}
