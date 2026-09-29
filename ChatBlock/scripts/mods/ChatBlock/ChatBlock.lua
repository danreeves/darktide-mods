local mod = get_mod("ChatBlock")
local WeaponTemplate = require("scripts/utilities/weapon/weapon_template")
local PlayerUnitVisualLoadout = require("scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout")

local MELEE_WIELD_INPUT = PlayerUnitVisualLoadout.wield_input_from_slot_name("slot_primary")

mod.input_blocked = false
mod.chat_opening = false
mod.cinematic_active = false
mod.auto_melee_swap_blocked = false
mod.auto_melee_swap_requested = false

local function auto_melee_swap_allowed()
	local game_mode_manager = Managers.state.game_mode

	return game_mode_manager and game_mode_manager:default_player_orientation() ~= "HubPlayerOrientation"
end

-- You alt tabbed or the Steam overlay is open
local function focus_lost()
	return (IS_WINDOWS and not Window.has_focus()) or (HAS_STEAM and Managers.steam:is_overlay_active())
end

local function holding_block_weapon(unit)
	local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")
	if not unit_data then
		return false
	end

	local weapon_action_component = unit_data:read_component("weapon_action")
	local weapon_template = WeaponTemplate.current_weapon_template(weapon_action_component)

	return weapon_template ~= nil and weapon_template.actions.action_block ~= nil
end

local function auto_melee_swap_on_blocked(blocked)
	if not blocked then
		-- The block ended before the swap went through, so don't swap afterwards
		mod.auto_melee_swap_requested = false
	elseif not mod.auto_melee_swap_blocked and mod:get("auto_melee_swap") then
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

mod:hook("HumanGameplay", "_input_active", function(func, ...)
	local input_active = func(...)

	mod.input_blocked = not input_active

	-- Chat only starts using input in the UI update, after this frame's gameplay
	-- input has been sampled, so a key typed in the same frame as the one opening
	-- chat would still act in game. Treat that frame as blocked as well.
	local ui_manager = Managers.ui
	mod.chat_opening = input_active and ui_manager ~= nil and ui_manager:input_service():get("show_chat")

	mod.cinematic_active = Managers.state.cinematic:cinematic_active()

	if not mod:get("auto_melee_swap") or not auto_melee_swap_allowed() or mod.cinematic_active then
		mod.auto_melee_swap_blocked = false
		mod.auto_melee_swap_requested = false
	elseif mod.input_blocked then
		-- Chat/menu block already implies the combined blocked state,
		-- so no focus/overlay polling is needed on this path.
		auto_melee_swap_on_blocked(true)
	else
		-- Input is otherwise active: only an alt-tab or Steam overlay
		-- transition can mean blocked here.
		auto_melee_swap_on_blocked(focus_lost())
	end

	-- While blocked the game samples the null input service, so you don't move
	-- or tag or dodge while typing. Block and the melee swap are written into
	-- the sampled input afterwards.
	return input_active and not mod.chat_opening
end)

-- HumanInputHandler samples gameplay input into a fixed-frame buffer that is
-- sent to the server. Write the melee wield and the held block straight into
-- that buffer once per fixed frame, instead of filtering every input lookup.
mod:hook_safe("HumanInputHandler", "_parse_input", function(self, input_cache, _input_service, index)
	local action_lookup = self._action_lookup

	if mod.auto_melee_swap_requested then
		-- A single press is dropped when the current action doesn't allow a
		-- weapon switch at that moment, e.g. while shooting or sprinting, so
		-- keep pressing until the melee weapon is out.
		local unit = self._player.player_unit
		local unit_data = unit and ScriptUnit.has_extension(unit, "unit_data_system")

		if unit_data and unit_data:read_component("inventory").wielded_slot ~= "slot_primary" then
			input_cache[action_lookup[MELEE_WIELD_INPUT]][index] = true
		else
			mod.auto_melee_swap_requested = false
		end
	end

	if mod.cinematic_active then
		return
	end

	-- Chat or some other menu is open, or you alt tabbed
	if not (mod.input_blocked or mod.chat_opening or focus_lost()) then
		return
	end

	-- Keep blocking if the current held weapon has a block action
	local unit = self._player.player_unit
	if unit and holding_block_weapon(unit) then
		input_cache[action_lookup.action_two_hold][index] = true
	end
end)
