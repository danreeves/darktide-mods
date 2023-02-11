return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`DontStartEmptyGames` encountered an error loading the Darktide Mod Framework.")

		new_mod("DontStartEmptyGames", {
			mod_script       = "DontStartEmptyGames/scripts/mods/DontStartEmptyGames/DontStartEmptyGames",
			mod_data         = "DontStartEmptyGames/scripts/mods/DontStartEmptyGames/DontStartEmptyGames_data",
			mod_localization = "DontStartEmptyGames/scripts/mods/DontStartEmptyGames/DontStartEmptyGames_localization",
		})
	end,
	packages = {},
}
