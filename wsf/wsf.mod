return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`wsf` encountered an error loading the Darktide Mod Framework.")
		new_mod("wsf", {
			mod_script = "wsf/scripts/mods/wsf/wsf",
			mod_data = "wsf/scripts/mods/wsf/wsf_data",
			mod_localization = "wsf/scripts/mods/wsf/wsf_localization",
		})
	end,
	packages = {},
}
