return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`MinionStatus` encountered an error loading the Darktide Mod Framework.")

		new_mod("MinionStatus", {
			mod_script       = "MinionStatus/scripts/mods/MinionStatus/MinionStatus",
			mod_data         = "MinionStatus/scripts/mods/MinionStatus/MinionStatus_data",
			mod_localization = "MinionStatus/scripts/mods/MinionStatus/MinionStatus_localization",
		})
	end,
	packages = {},
}
