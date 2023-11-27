return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`PlayerList` encountered an error loading the Darktide Mod Framework.")

		new_mod("PlayerList", {
			mod_script       = "PlayerList/scripts/mods/PlayerList/PlayerList",
			mod_data         = "PlayerList/scripts/mods/PlayerList/PlayerList_data",
			mod_localization = "PlayerList/scripts/mods/PlayerList/PlayerList_localization",
		})
	end,
	packages = {},
}
