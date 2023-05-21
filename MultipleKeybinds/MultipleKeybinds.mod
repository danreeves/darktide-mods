return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`MultipleKeybinds` encountered an error loading the Darktide Mod Framework.")

		new_mod("MultipleKeybinds", {
			mod_script       = "MultipleKeybinds/scripts/mods/MultipleKeybinds/MultipleKeybinds",
			mod_data         = "MultipleKeybinds/scripts/mods/MultipleKeybinds/MultipleKeybinds_data",
			mod_localization = "MultipleKeybinds/scripts/mods/MultipleKeybinds/MultipleKeybinds_localization",
		})
	end,
	packages = {},
}
