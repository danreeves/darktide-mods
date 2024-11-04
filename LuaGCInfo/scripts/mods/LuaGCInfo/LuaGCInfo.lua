local mod = get_mod("LuaGCInfo")

mod:register_hud_element({
	class_name = "HudElementLuaGCInfo",
	filename = "LuaGCInfo/scripts/mods/LuaGCInfo/HudElementLuaGCInfo",
	use_hud_scale = true,
	visibility_groups = {
		"in_hub_view",
		"dead",
		"alive",
		"communication_wheel",
		"tactical_overlay",
	},
})
