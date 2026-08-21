return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Healthbars` encountered an error loading the Darktide Mod Framework.")

		new_mod("Healthbars", {
			mod_script       = "Healthbars/scripts/mods/Healthbars/Healthbars",
			mod_data         = "Healthbars/scripts/mods/Healthbars/Healthbars_data",
			mod_localization = "Healthbars/scripts/mods/Healthbars/Healthbars_localization",
		})
	end,
	packages = {
		"packages/ui/hud/player_weapon/player_weapon",
		"packages/ui/views/inventory_background_view/inventory_background_view",
		"packages/ui/views/character_appearance_view/character_appearance_view",
		"packages/ui/material_sets/circumstances",
	},
    load_after = {
        "Alfs_DMF_Extensions",
        "animation_events",
    },
	version = "26.08.21",
	mod_id = "16",
}
