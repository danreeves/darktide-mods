-- NumericUI
-- Description: Adds numbers to your HUD
-- Author: raindish
local mod = get_mod("NumericUI")

mod:io_dofile("NumericUI/scripts/mods/NumericUI/TeamPlayerPanel")
mod:io_dofile("NumericUI/scripts/mods/NumericUI/PlayerAbility")
mod:io_dofile("NumericUI/scripts/mods/NumericUI/PlayerWeapon")
mod:io_dofile("NumericUI/scripts/mods/NumericUI/Interactions")

local hud_elements = {
	{
		filename = "NumericUI/scripts/mods/NumericUI/HudElementDodgeCount",
		class_name = "HudElementDodgeCount",
	},
}

for _, hud_element in ipairs(hud_elements) do
	mod:add_require_path(hud_element.filename)
end

mod:hook("UIHud", "init", function(func, self, elements, visibility_groups, params)
	for _, hud_element in ipairs(hud_elements) do
		if not table.find_by_key(elements, "class_name", hud_element.class_name) then
			table.insert(elements, {
				class_name = hud_element.class_name,
				filename = hud_element.filename,
				use_hud_scale = true,
				visibility_groups = {
					"alive",
				},
			})
		end
	end

	return func(self, elements, visibility_groups, params)
end)

-- Taken from Fracticality
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

mod.on_all_mods_loaded = function()
	recreate_hud()
end

mod.on_setting_changed = function()
	recreate_hud()
end
