return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`MuteInBackground` encountered an error loading the Darktide Mod Framework.")

		new_mod("MuteInBackground", {
			mod_script       = "MuteInBackground/scripts/mods/MuteInBackground/MuteInBackground",
			mod_data         = "MuteInBackground/scripts/mods/MuteInBackground/MuteInBackground_data",
			mod_localization = "MuteInBackground/scripts/mods/MuteInBackground/MuteInBackground_localization",
		})
	end,
	packages = {},
}
