return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Clock` encountered an error loading the Darktide Mod Framework.")

		new_mod("Clock", {
			mod_script       = "Clock/scripts/mods/Clock/Clock",
			mod_data         = "Clock/scripts/mods/Clock/Clock_data",
			mod_localization = "Clock/scripts/mods/Clock/Clock_localization",
		})
	end,
	packages = {},
}
