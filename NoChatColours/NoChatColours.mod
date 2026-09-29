return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`NoChatColours` encountered an error loading the Darktide Mod Framework.")

		new_mod("NoChatColours", {
			mod_script       = "NoChatColours/scripts/mods/NoChatColours/NoChatColours",
			mod_data         = "NoChatColours/scripts/mods/NoChatColours/NoChatColours_data",
			mod_localization = "NoChatColours/scripts/mods/NoChatColours/NoChatColours_localization",
		})
	end,
	packages = {},
}
