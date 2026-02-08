return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`NumericUI` encountered an error loading the Darktide Mod Framework.")

		new_mod("NumericUI", {
			mod_script       = "NumericUI/scripts/mods/NumericUI/NumericUI",
			mod_data         = "NumericUI/scripts/mods/NumericUI/NumericUI_data",
			mod_localization = "NumericUI/scripts/mods/NumericUI/NumericUI_localization",
		})
	end,
	packages = {},
	version = "26.02.08-1",
	mod_id = "14"
}
