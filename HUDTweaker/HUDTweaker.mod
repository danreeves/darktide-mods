return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`HUDTweaker` encountered an error loading the Darktide Mod Framework.")

		new_mod("HUDTweaker", {
			mod_script       = "HUDTweaker/scripts/mods/HUDTweaker/HUDTweaker",
			mod_data         = "HUDTweaker/scripts/mods/HUDTweaker/HUDTweaker_data",
			mod_localization = "HUDTweaker/scripts/mods/HUDTweaker/HUDTweaker_localization",
		})
	end,
	packages = {},
	version = "26.02.08-1",
	mod_id = "154"
}
