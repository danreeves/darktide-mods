return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`LuaGCInfo` encountered an error loading the Darktide Mod Framework.")

		new_mod("LuaGCInfo", {
			mod_script       = "LuaGCInfo/scripts/mods/LuaGCInfo/LuaGCInfo",
			mod_data         = "LuaGCInfo/scripts/mods/LuaGCInfo/LuaGCInfo_data",
			mod_localization = "LuaGCInfo/scripts/mods/LuaGCInfo/LuaGCInfo_localization",
		})
	end,
	packages = {},
}
