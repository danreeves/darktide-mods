return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`DodgeTrainer` encountered an error loading the Darktide Mod Framework.")

		new_mod("DodgeTrainer", {
			mod_script       = "DodgeTrainer/scripts/mods/DodgeTrainer/DodgeTrainer",
			mod_data         = "DodgeTrainer/scripts/mods/DodgeTrainer/DodgeTrainer_data",
			mod_localization = "DodgeTrainer/scripts/mods/DodgeTrainer/DodgeTrainer_localization",
		})
	end,
	packages = {},
}
