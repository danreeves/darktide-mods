return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`TrueSoloQoL` encountered an error loading the Darktide Mod Framework.")

		new_mod("TrueSoloQoL", {
			mod_script       = "TrueSoloQoL/scripts/mods/TrueSoloQoL/TrueSoloQoL",
			mod_data         = "TrueSoloQoL/scripts/mods/TrueSoloQoL/TrueSoloQoL_data",
			mod_localization = "TrueSoloQoL/scripts/mods/TrueSoloQoL/TrueSoloQoL_localization",
		})
	end,
	packages = {},
}
