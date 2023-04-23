return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`DTAuth` encountered an error loading the Darktide Mod Framework.")

		new_mod("DTAuth", {
			mod_script       = "DTAuth/scripts/mods/DTAuth/DTAuth",
			mod_data         = "DTAuth/scripts/mods/DTAuth/DTAuth_data",
			mod_localization = "DTAuth/scripts/mods/DTAuth/DTAuth_localization",
		})
	end,
	packages = {},
}
