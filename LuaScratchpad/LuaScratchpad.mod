return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`LuaScratchpad` encountered an error loading the Darktide Mod Framework.")

		new_mod("LuaScratchpad", {
			mod_script       = "LuaScratchpad/scripts/mods/LuaScratchpad/LuaScratchpad",
			mod_data         = "LuaScratchpad/scripts/mods/LuaScratchpad/LuaScratchpad_data",
			mod_localization = "LuaScratchpad/scripts/mods/LuaScratchpad/LuaScratchpad_localization",
		})
	end,
	packages = {},
}
