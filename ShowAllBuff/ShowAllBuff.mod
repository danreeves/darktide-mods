return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ShowAllBuff` encountered an error loading the Darktide Mod Framework.")

		new_mod("ShowAllBuff", {
			mod_script       = "ShowAllBuff/scripts/mods/ShowAllBuff/ShowAllBuff",
			mod_data         = "ShowAllBuff/scripts/mods/ShowAllBuff/ShowAllBuff_data",
			mod_localization = "ShowAllBuff/scripts/mods/ShowAllBuff/ShowAllBuff_localization",
		})
	end,
	packages = {},
}
