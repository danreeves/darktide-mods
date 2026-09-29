return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`DisableScreenEffects` encountered an error loading the Darktide Mod Framework.")

		new_mod("DisableScreenEffects", {
			mod_script       = "DisableScreenEffects/scripts/mods/DisableScreenEffects/DisableScreenEffects",
			mod_data         = "DisableScreenEffects/scripts/mods/DisableScreenEffects/DisableScreenEffects_data",
			mod_localization = "DisableScreenEffects/scripts/mods/DisableScreenEffects/DisableScreenEffects_localization",
		})
	end,
	packages = {},
}
