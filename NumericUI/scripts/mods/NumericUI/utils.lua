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

-- "<ability_type>_resource_*" stat buff names built once instead of every frame
local flat_regen_stat_buffs = {}
local regen_modifier_stat_buffs = {}

-- Seconds until the next charge of an ability, using the same regen maths as
-- PlayerUnitAbilityExtension._update_ability_resources. Returns nil when no charge is regenerating,
-- regen is paused, or it is not progressing. Only pass the local player's ability extension:
-- husk extensions error on get_ability_resource_cost_per_second.
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
	local stat_buffs = buff_extension and buff_extension:stat_buffs()

	if stat_buffs then
		local flat_regen_stat_buff = flat_regen_stat_buffs[ability_type]

		if not flat_regen_stat_buff then
			flat_regen_stat_buff = ability_type .. "_resource_flat_regen"
			flat_regen_stat_buffs[ability_type] = flat_regen_stat_buff
			regen_modifier_stat_buffs[ability_type] = ability_type .. "_resource_regen_modifier"
		end

		regen_per_second = (regen_per_second + (stat_buffs[flat_regen_stat_buff] or 0))
			* (stat_buffs[regen_modifier_stat_buffs[ability_type]] or 1)
	end

	regen_per_second = regen_per_second - ability_extension:get_ability_resource_cost_per_second(ability_type)

	if regen_per_second <= 0 then
		return
	end

	return missing_resource / regen_per_second
end
