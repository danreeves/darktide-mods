return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`LogMeIn` encountered an error loading the Darktide Mod Framework.")

		new_mod("LogMeIn", {
			mod_script       = "LogMeIn/scripts/mods/LogMeIn/LogMeIn",
			mod_data         = "LogMeIn/scripts/mods/LogMeIn/LogMeIn_data",
			mod_localization = "LogMeIn/scripts/mods/LogMeIn/LogMeIn_localization",
		})
	end,
	packages = {},
}
