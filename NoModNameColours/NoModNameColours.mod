return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`NoModNameColours` encountered an error loading the Darktide Mod Framework.")

		new_mod("NoModNameColours", {
			mod_script       = "NoModNameColours/scripts/mods/NoModNameColours/NoModNameColours",
			mod_data         = "NoModNameColours/scripts/mods/NoModNameColours/NoModNameColours_data",
			mod_localization = "NoModNameColours/scripts/mods/NoModNameColours/NoModNameColours_localization",
		})
	end,
	packages = {},
}
