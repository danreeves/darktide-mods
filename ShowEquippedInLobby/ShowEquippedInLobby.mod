return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ShowEquippedInLobby` encountered an error loading the Darktide Mod Framework.")

		new_mod("ShowEquippedInLobby", {
			mod_script       = "ShowEquippedInLobby/scripts/mods/ShowEquippedInLobby/ShowEquippedInLobby",
			mod_data         = "ShowEquippedInLobby/scripts/mods/ShowEquippedInLobby/ShowEquippedInLobby_data",
			mod_localization = "ShowEquippedInLobby/scripts/mods/ShowEquippedInLobby/ShowEquippedInLobby_localization",
		})
	end,
	packages = {},
}
