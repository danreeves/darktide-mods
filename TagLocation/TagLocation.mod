return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`TagLocation` encountered an error loading the Darktide Mod Framework.")

		new_mod("TagLocation", {
			mod_script       = "TagLocation/scripts/mods/TagLocation/TagLocation",
			mod_data         = "TagLocation/scripts/mods/TagLocation/TagLocation_data",
			mod_localization = "TagLocation/scripts/mods/TagLocation/TagLocation_localization",
		})
	end,
	packages = {},
}
