return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`MovementAnalyzer` encountered an error loading the Darktide Mod Framework.")

		new_mod("MovementAnalyzer", {
			mod_script       = "MovementAnalyzer/scripts/mods/MovementAnalyzer/MovementAnalyzer",
			mod_data         = "MovementAnalyzer/scripts/mods/MovementAnalyzer/MovementAnalyzer_data",
			mod_localization = "MovementAnalyzer/scripts/mods/MovementAnalyzer/MovementAnalyzer_localization",
		})
	end,
	packages = {},
}
