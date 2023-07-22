return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Tertium4Or5` encountered an error loading the Darktide Mod Framework.")

		new_mod("Tertium4Or5", {
			mod_script       = "Tertium4Or5/scripts/mods/Tertium4Or5/Tertium4Or5",
			mod_data         = "Tertium4Or5/scripts/mods/Tertium4Or5/Tertium4Or5_data",
			mod_localization = "Tertium4Or5/scripts/mods/Tertium4Or5/Tertium4Or5_localization",
		})
	end,
	packages = {},
}
