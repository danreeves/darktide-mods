return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`TestMod` encountered an error loading the Darktide Mod Framework.")

		new_mod("TestMod", {
			mod_script       = "TestMod/scripts/mods/TestMod/TestMod",
			mod_data         = "TestMod/scripts/mods/TestMod/TestMod_data",
			mod_localization = "TestMod/scripts/mods/TestMod/TestMod_localization",
		})
	end,
	packages = {},
}
