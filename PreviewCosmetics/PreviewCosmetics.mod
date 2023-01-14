return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`PreviewCosmetics` encountered an error loading the Darktide Mod Framework.")

		new_mod("PreviewCosmetics", {
			mod_script       = "PreviewCosmetics/scripts/mods/PreviewCosmetics/PreviewCosmetics",
			mod_data         = "PreviewCosmetics/scripts/mods/PreviewCosmetics/PreviewCosmetics_data",
			mod_localization = "PreviewCosmetics/scripts/mods/PreviewCosmetics/PreviewCosmetics_localization",
		})
	end,
	packages = {},
}
