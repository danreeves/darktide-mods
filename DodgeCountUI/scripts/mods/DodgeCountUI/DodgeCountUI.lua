local mod = get_mod("DodgeCountUI")

local hud_element_path = "DodgeCountUI/scripts/mods/DodgeCountUI/HudElement"
mod:add_require_path(hud_element_path)
mod:hook_require("scripts/ui/hud/hud_elements_player", function(instance)
	mod:echo("require")
	if not table.find_by_key(instance, "class_name", "DodgeCountUI") then
		table.insert(instance, {
			package = "packages/ui/hud/crosshair/crosshair", -- just a random hud package
			use_hud_scale = true,
			class_name = "DodgeCountUI",
			filename = hud_element_path,
			visibility_groups = {
				"alive",
			},
		})
	end
end)

local function recreate_hud()
	local ui_manager = Managers.ui
	if ui_manager then
		local hud = ui_manager._hud
		if hud then
			local player_manager = Managers.player
			local player = player_manager:local_player(1)
			local peer_id = player:peer_id()
			local local_player_id = player:local_player_id()
			local elements = hud._element_definitions
			local visibility_groups = hud._visibility_groups

			hud:destroy()
			ui_manager:create_player_hud(peer_id, local_player_id, elements, visibility_groups)
		end
	end
end

recreate_hud()
