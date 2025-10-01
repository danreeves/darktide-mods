return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`rtc` encountered an error loading the Darktide Mod Framework.")

		new_mod("rtc", {
			mod_script       = "rtc/scripts/mods/rtc/rtc",
			mod_data         = "rtc/scripts/mods/rtc/rtc_data",
			mod_localization = "rtc/scripts/mods/rtc/rtc_localization",
		})
	end,
	packages = {},
}
