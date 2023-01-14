return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`TaskbarFlasher` encountered an error loading the Darktide Mod Framework.")

		new_mod("TaskbarFlasher", {
			mod_script       = "TaskbarFlasher/scripts/mods/TaskbarFlasher/TaskbarFlasher",
			mod_data         = "TaskbarFlasher/scripts/mods/TaskbarFlasher/TaskbarFlasher_data",
			mod_localization = "TaskbarFlasher/scripts/mods/TaskbarFlasher/TaskbarFlasher_localization",
		})
	end,
	packages = {},
}
