return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ProfilePictures` encountered an error loading the Darktide Mod Framework.")

		new_mod("ProfilePictures", {
			mod_script       = "ProfilePictures/scripts/mods/ProfilePictures/ProfilePictures",
			mod_data         = "ProfilePictures/scripts/mods/ProfilePictures/ProfilePictures_data",
			mod_localization = "ProfilePictures/scripts/mods/ProfilePictures/ProfilePictures_localization",
		})
	end,
	packages = {},
}
