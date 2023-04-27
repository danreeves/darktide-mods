return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`RainbowImpacts` encountered an error loading the Darktide Mod Framework.")

		new_mod("RainbowImpacts", {
			mod_script       = "RainbowImpacts/scripts/mods/RainbowImpacts/RainbowImpacts",
			mod_data         = "RainbowImpacts/scripts/mods/RainbowImpacts/RainbowImpacts_data",
			mod_localization = "RainbowImpacts/scripts/mods/RainbowImpacts/RainbowImpacts_localization",
		})
	end,
	packages = {},
}
