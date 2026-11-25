local mod = get_mod("NumericUI")

local Ammo = require("scripts/utilities/ammo")
local PlayerCharacterConstants = require("scripts/settings/player_character/player_character_constants")

local table_clear = table.clear

-- The weapon slots, listed the way the vanilla team panel lists them. A teammate's visual loadout has no
-- slot_configuration_by_type, so the slots come from the constants for every player.
local weapon_slot_names = {}

for slot_name in pairs(PlayerCharacterConstants.slot_configuration_by_type.weapon) do
	weapon_slot_names[#weapon_slot_names + 1] = slot_name
end

local num_weapon_slots = #weapon_slot_names

mod._is_in_hub = function()
	local game_mode_name = Managers.state.game_mode:game_mode_name()
	local is_in_hub = game_mode_name == "hub"

	return is_in_hub
end

local setting_values = {}
local setting_cached = {}

mod.setting = function(setting_id)
	if not setting_cached[setting_id] then
		setting_values[setting_id] = mod:get(setting_id)
		setting_cached[setting_id] = true
	end

	return setting_values[setting_id]
end

mod.flush_settings = function()
	table_clear(setting_values)
	table_clear(setting_cached)
end

-- Seconds until the next charge of an ability at its base recharge speed, the way vanilla's
-- max_regen_time_for_ability_charge and the teammate panel time a charge. Recharge speed buffs, flat regen or regen
-- modifier, permanent or timed, are left out: the game still applies them to the live missing resource, so they make
-- the countdown run faster or slower than the clock instead of shortening it or making it jump when they end, and it
-- still reaches zero when the charge is ready. Returns nil when no charge is regenerating, regen is paused, the
-- active ability is draining its own resource, or regen is not progressing. buff_extension is no longer read; it
-- only keeps the callers' argument order. Only pass the local player's ability extension: husk extensions error on
-- get_ability_resource_cost_per_second.
mod.ability_charge_time_remaining = function(ability_extension, buff_extension, ability_type)
	local missing_resource_func = ability_extension.missing_ability_resource_until_next_charge

	if not missing_resource_func or not ability_type then
		return
	end

	local missing_resource = missing_resource_func(ability_extension, ability_type)

	if
		not missing_resource
		or missing_resource <= 0
		or ability_extension:is_ability_resource_regen_paused(ability_type)
	then
		return
	end

	local ability = ability_extension:ability_is_equipped(ability_type)

	if not ability then
		return
	end

	local max_resource = ability_extension:max_ability_resource(ability_type)
	local regen_per_second = (ability.resource_regen_per_second or 0)
		+ max_resource * (ability.resource_regen_percent_per_second or 0)
	local resource_cost_per_second = ability_extension:get_ability_resource_cost_per_second(ability_type)

	-- an active ability draining its own resource, like the Skitarius' Precision Stance, is spending its charge
	-- rather than recharging it, so there is nothing to count down, just as while regen is paused
	if resource_cost_per_second > 0 and ability_extension:is_ability_active(ability_type) then
		return
	end

	regen_per_second = regen_per_second - resource_cost_per_second

	if regen_per_second <= 0 then
		return
	end

	return missing_resource / regen_per_second
end

-- Havoc's ammo pickup modifier, read once per mission. The game hands it to the DifficultyManager on the server alone,
-- so clients read it from the Havoc game mode extension instead.
local function _havoc_ammo_modifier()
	local cached = mod._havoc_ammo_modifier

	if cached then
		return cached
	end

	local modifier = 1
	local game_mode_manager = Managers.state.game_mode
	local game_mode = game_mode_manager and game_mode_manager:game_mode()
	local havoc_extension = game_mode and game_mode.extension and game_mode:extension("havoc")

	if havoc_extension then
		modifier = havoc_extension:get_modifier_value("ammo_pickup_modifier") or 1
	end

	mod._havoc_ammo_modifier = modifier

	return modifier
end

-- The current and max reserve, then the current and max clip ammo, of the unit's first weapon that uses ammo, and that
-- weapon's slot. Nil without one, or before a teammate's ammo has been received. Works for teammates as well as the
-- local player.
mod.weapon_ammo_totals = function(unit)
	local unit_data_extension = ScriptUnit.has_extension(unit, "unit_data_system")

	if not unit_data_extension then
		return
	end

	for i = 1, num_weapon_slots do
		local slot_name = weapon_slot_names[i]
		local wieldable_component = unit_data_extension:read_component(slot_name)
		local max_ammo_reserve = wieldable_component and wieldable_component.max_ammunition_reserve

		if max_ammo_reserve and max_ammo_reserve > 0 then
			return Ammo.current_ammo_in_reserve(wieldable_component),
				max_ammo_reserve,
				Ammo.current_ammo_in_clips(wieldable_component),
				Ammo.max_ammo_in_clips(wieldable_component),
				slot_name
		end
	end
end

-- The rounds an ammo pickup offers a weapon with this capacity, with Havoc's modifier, the way AmmunitionInteraction
-- works it out. The game's pickup data keeps its own modifier.
mod.pickup_ammo_amount = function(pickup_data, max_ammo_reserve, max_ammo_clip)
	local previous_modifier = pickup_data.modifier

	pickup_data.modifier = _havoc_ammo_modifier()

	local amount = pickup_data.ammo_amount_func(max_ammo_reserve, max_ammo_clip, pickup_data)

	pickup_data.modifier = previous_modifier

	return amount
end

-- Splits the rounds a pickup offers into the rounds gained and the rounds left over. The game adds them to the reserve
-- up to the ammo missing from the reserve and the clips together, so a weapon with no ammo missing gains none.
mod.split_pickup_ammo = function(pickup_amount, current_ammo, max_ammo)
	local missing_ammo = max_ammo - current_ammo

	if missing_ammo >= pickup_amount then
		return pickup_amount, 0
	elseif missing_ammo > 0 then
		return missing_ammo, pickup_amount - missing_ammo
	end

	return 0, pickup_amount
end
