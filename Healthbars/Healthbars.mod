return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Healthbars` encountered an error loading the Darktide Mod Framework.")

		new_mod("Healthbars", {
			mod_script       = "Healthbars/scripts/mods/Healthbars/Healthbars",
			mod_data         = "Healthbars/scripts/mods/Healthbars/Healthbars_data",
			mod_localization = "Healthbars/scripts/mods/Healthbars/Healthbars_localization",
		})
	end,
	packages = {},
	version = "26.02.08-1",
	mod_id = "16"
}
