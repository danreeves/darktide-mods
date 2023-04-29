return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`MoveViewmodel` encountered an error loading the Darktide Mod Framework.")

		new_mod("MoveViewmodel", {
			mod_script       = "MoveViewmodel/scripts/mods/MoveViewmodel/MoveViewmodel",
			mod_data         = "MoveViewmodel/scripts/mods/MoveViewmodel/MoveViewmodel_data",
			mod_localization = "MoveViewmodel/scripts/mods/MoveViewmodel/MoveViewmodel_localization",
		})
	end,
	packages = {},
}
