local mod = get_mod("ChatBlock")
local WeaponTemplate = require("scripts/utilities/weapon/weapon_template")
local PlayerUnitVisualLoadout = require("scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout")

mod.input_blocked = false
mod.auto_melee_swap_blocked = false

local function auto_melee_swap_on_blocked(blocked)
	if blocked and not mod.auto_melee_swap_blocked and mod:get("auto_melee_swap") then
		local player = Managers.player:local_player(1)
		if player then
			local unit = player.player_unit
			if unit then
				local unit_data = ScriptUnit.extension(unit, "unit_data_system")
				local inventory_component = unit_data:read_component("inventory")
				local wielded_slot = inventory_component.wielded_slot

				if wielded_slot ~= "slot_primary" then
					local t = Managers.time:time("gameplay")
					PlayerUnitVisualLoadout.wield_slot("slot_primary", unit, t)
				end
			end
		end
	end

	mod.auto_melee_swap_blocked = blocked
end

local function input_get_hook(func, self, action_name)
	-- Don't impact the non gameplay input services
	if self.type == "Ingame" and action_name ~= "voip_push_to_talk" then
		-- When checking if action_two_hold is held
		if action_name == "action_two_hold" then
			local unit = Managers.player:local_player(1).player_unit
			if unit then
				local unit_data = ScriptUnit.extension(unit, "unit_data_system")
				local weapon_action_component = unit_data:read_component("weapon_action")
				local weapon_template = WeaponTemplate.current_weapon_template(weapon_action_component)
				if weapon_template then
					-- If the current held weapon has a block action
					if weapon_template.actions.action_block then
						local alt_tabbed = IS_WINDOWS and not Window.has_focus()
						-- You alt tabbed
						if alt_tabbed then
							return true
						end

						local steam_overlay_open = HAS_STEAM and Managers.steam:is_overlay_active()
						-- Steam overlay is open
						if steam_overlay_open then
							return true
						end

						-- Chat or some other menu is open
						if mod.input_blocked then
							return true
						end
					end
				end
			end
		end

		-- Act as if any other input is not working while the UI is using input
		-- so you don't move or tag or dodge while typing
		local ui_manager = Managers.ui
		if ui_manager and ui_manager:using_input() then
			local result = func(self, action_name)
			local result_type = type(result)

			if result_type == "boolean" then
				return false
			elseif result_type == "number" then
				return 0
			elseif result_type == "userdata" then
				return Vector3(0, 0, 0)
			else
				return result
			end
		end
	end

	-- Default behaviour for other input services or
	-- while UI not using input
	return func(self, action_name)
end

mod:hook("InputService", "_get", input_get_hook)
mod:hook("InputService", "_get_simulate", input_get_hook)

mod:hook("HumanGameplay", "_input_active", function(func, ...)
	mod.input_blocked = not func(...)
	if not mod:get("auto_melee_swap") then
		mod.auto_melee_swap_blocked = false
	elseif mod.input_blocked then
		-- Chat/menu block already implies the combined blocked state,
		-- so no focus/overlay polling is needed on this path.
		auto_melee_swap_on_blocked(true)
	else
		-- Input is otherwise active: only an alt-tab or Steam overlay
		-- transition can mean blocked here. Poll once per update rather
		-- than once per input query.
		local alt_tabbed = IS_WINDOWS and not Window.has_focus()
		local steam_overlay_open = HAS_STEAM and Managers.steam:is_overlay_active()
		auto_melee_swap_on_blocked(alt_tabbed or steam_overlay_open)
	end

	if Managers.state.cinematic:cinematic_active() then
		return false
	end

	-- Keep the input active so you can block
	return true
end)
