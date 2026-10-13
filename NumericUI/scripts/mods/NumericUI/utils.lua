local mod = get_mod("NumericUI")

local table_clear = table.clear

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
