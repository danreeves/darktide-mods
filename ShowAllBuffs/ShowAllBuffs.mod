return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ShowAllBuffs` encountered an error loading the Darktide Mod Framework.")

		new_mod("ShowAllBuffs", {
			mod_script       = "ShowAllBuffs/scripts/mods/ShowAllBuffs/ShowAllBuffs",
			mod_data         = "ShowAllBuffs/scripts/mods/ShowAllBuffs/ShowAllBuffs_data",
			mod_localization = "ShowAllBuffs/scripts/mods/ShowAllBuffs/ShowAllBuffs_localization",
		})
	end,
	packages = {},
}
