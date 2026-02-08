return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ChatBlock` encountered an error loading the Darktide Mod Framework.")

		new_mod("ChatBlock", {
			mod_script       = "ChatBlock/scripts/mods/ChatBlock/ChatBlock",
			mod_data         = "ChatBlock/scripts/mods/ChatBlock/ChatBlock_data",
			mod_localization = "ChatBlock/scripts/mods/ChatBlock/ChatBlock_localization",
		})
	end,
	packages = {},
	version = "26.02.08-1",
	mod_id = "68"
}
