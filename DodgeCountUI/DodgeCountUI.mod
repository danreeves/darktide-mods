return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`DodgeCountUI` encountered an error loading the Darktide Mod Framework.")

		new_mod("DodgeCountUI", {
			mod_script       = "DodgeCountUI/scripts/mods/DodgeCountUI/DodgeCountUI",
			mod_data         = "DodgeCountUI/scripts/mods/DodgeCountUI/DodgeCountUI_data",
			mod_localization = "DodgeCountUI/scripts/mods/DodgeCountUI/DodgeCountUI_localization",
		})
	end,
	packages = {},
}
