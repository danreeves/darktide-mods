return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`CustomCrosshairColor` encountered an error loading the Darktide Mod Framework.")

		new_mod("CustomCrosshairColor", {
			mod_script       = "CustomCrosshairColor/scripts/mods/CustomCrosshairColor/CustomCrosshairColor",
			mod_data         = "CustomCrosshairColor/scripts/mods/CustomCrosshairColor/CustomCrosshairColor_data",
			mod_localization = "CustomCrosshairColor/scripts/mods/CustomCrosshairColor/CustomCrosshairColor_localization",
		})
	end,
	packages = {},
}
