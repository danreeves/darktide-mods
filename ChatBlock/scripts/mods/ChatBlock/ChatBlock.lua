local mod = get_mod("ChatBlock")
local WeaponTemplate = require("scripts/utilities/weapon/weapon_template")
local PlayerUnitVisualLoadout = require("scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout")

local MELEE_WIELD_INPUT = PlayerUnitVisualLoadout.wield_input_from_slot_name("slot_primary")

mod.input_blocked = false
mod.chat_opening = false
mod.auto_melee_swap_blocked = false
mod.auto_melee_swap_requested = false

local function auto_melee_swap_allowed()
	local game_mode_manager = Managers.state.game_mode

	return game_mode_manager and game_mode_manager:default_player_orientation() ~= "HubPlayerOrientation"
end

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
					-- Request a normal melee wield input rather than forcing the wield
					-- locally, so it goes through the buffered, networked player input
					-- and the server simulates the same swap instead of correcting it.
					mod.auto_melee_swap_requested = true
				end
			end
		end
	end

	mod.auto_melee_swap_blocked = blocked
end

-- Never let a pending wield request outlive the blocked transition it was
-- made for, e.g. by being consumed after re-enabling or in the next mission.
local function clear_auto_melee_swap_request()
	mod.auto_melee_swap_requested = false
end

mod.on_disabled = clear_auto_melee_swap_request
mod.on_game_state_changed = clear_auto_melee_swap_request

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
		-- (or chat is opening this frame) so you don't move or tag or dodge while typing
		local ui_manager = Managers.ui
		if mod.chat_opening or ui_manager and ui_manager:using_input() then
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

-- HumanInputHandler samples wield inputs through get_with_filters against
-- the UI-locked keys. Let exactly one requested melee wield through here so
-- it enters the fixed-frame input buffer sent to the server.
mod:hook("InputService", "get_with_filters", function(func, self, action_name, locked_inputs)
	if mod.auto_melee_swap_requested and action_name == MELEE_WIELD_INPUT and self.type == "Ingame" then
		mod.auto_melee_swap_requested = false

		return true
	end

	return func(self, action_name, locked_inputs)
end)

mod:hook("HumanGameplay", "_input_active", function(func, ...)
	mod.input_blocked = not func(...)

	-- Chat only starts using input in the UI update, after this frame's gameplay
	-- input has been sampled, so a key typed in the same frame as the one opening
	-- chat would still act in game. Treat that frame as blocked as well.
	local ui_manager = Managers.ui
	mod.chat_opening = not mod.input_blocked and ui_manager ~= nil and ui_manager:input_service():get("show_chat")

	local cinematic_active = Managers.state.cinematic:cinematic_active()

	if not mod:get("auto_melee_swap") or not auto_melee_swap_allowed() or cinematic_active then
		mod.auto_melee_swap_blocked = false
		mod.auto_melee_swap_requested = false
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

	if cinematic_active then
		return false
	end

	-- Keep the input active so you can block
	return true
end)
