return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`%%title` encountered an error loading the Darktide Mod Framework.")

		new_mod("%%name", {
			mod_script       = "%%name/scripts/mods/%%name/%%name",
			mod_data         = "%%name/scripts/mods/%%name/%%name_data",
			mod_localization = "%%name/scripts/mods/%%name/%%name_localization",
		})
	end,
	packages = {},
}
