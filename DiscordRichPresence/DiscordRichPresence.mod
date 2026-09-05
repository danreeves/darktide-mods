return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`DiscordRichPresence` encountered an error loading the Darktide Mod Framework.")

		new_mod("DiscordRichPresence", {
			mod_script       = "DiscordRichPresence/scripts/mods/DiscordRichPresence/DiscordRichPresence",
			mod_data         = "DiscordRichPresence/scripts/mods/DiscordRichPresence/DiscordRichPresence_data",
			mod_localization = "DiscordRichPresence/scripts/mods/DiscordRichPresence/DiscordRichPresence_localization",
		})
	end,
	packages = {},
}
