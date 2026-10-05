local mod = get_mod("NumericUI")
local BuffSettings = require("scripts/settings/buff/buff_settings")
local FixedFrame = require("scripts/utilities/fixed_frame")

local pcall = pcall
local table_clear = table.clear
local table_contains = table.contains

local SYRINGE_KEYWORD = BuffSettings.keywords.syringe

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

local stat_buff_base_values = BuffSettings.stat_buff_type_base_values

-- Stand-in for a buff extension's stat table that timed buffs are measured into. Every stat starts at its
-- base value, as BuffExtensionBase._reset_stat_buffs leaves them.
local timed_stat_buffs = setmetatable({}, { __index = stat_buff_base_values })
local timed_modified_stats = {}

-- Per buff extension and ability type: the regen stat totals the timed share was last measured against, and
-- that share. Weakly keyed so a respawned player's old buff extension can still be collected.
local timed_regen_shares = setmetatable({}, { __mode = "k" })

-- Buffs with a duration, stimms, and proc buffs whose proc stats touch regen only speed up recharge for a while.
-- Stimms are matched by keyword because the copies a Hive Scum's Stimm Field applies have no duration: they
-- last for as long as you stand in the field.
local function _is_timed_regen_buff(buff, flat_regen_stat_buff, regen_modifier_stat_buff)
	if buff:duration() then
		return true
	end

	local template = buff:template()
	local keywords = template.keywords

	if keywords and table_contains(keywords, SYRINGE_KEYWORD) then
		return true
	end

	local proc_stat_buffs = template.proc_stat_buffs

	return proc_stat_buffs ~= nil
		and (proc_stat_buffs[flat_regen_stat_buff] ~= nil or proc_stat_buffs[regen_modifier_stat_buff] ~= nil)
end

-- The flat regen and regen modifier that timed buffs add right now. Each timed buff is measured with its own
-- update_stat_buffs, so stacks, multipliers and conditions count exactly as vanilla counts them. The share can
-- only change when one of the regen stat totals does, so the buff list is walked only then.
local function _timed_regen_share(
	buff_extension,
	stat_buffs,
	ability_type,
	flat_regen_stat_buff,
	regen_modifier_stat_buff
)
	local flat_regen_total = stat_buffs[flat_regen_stat_buff] or 0
	local regen_modifier_total = stat_buffs[regen_modifier_stat_buff] or 1
	local shares = timed_regen_shares[buff_extension]

	if not shares then
		shares = {}
		timed_regen_shares[buff_extension] = shares
	end

	local share = shares[ability_type]

	if not share then
		share = {}
		shares[ability_type] = share
	end

	if share.flat_regen_total ~= flat_regen_total or share.regen_modifier_total ~= regen_modifier_total then
		table_clear(timed_stat_buffs)
		table_clear(timed_modified_stats)
		timed_stat_buffs._modified_stats = timed_modified_stats

		local buffs = buff_extension:buffs()
		local t = FixedFrame.get_latest_fixed_time()

		for i = 1, #buffs do
			local buff = buffs[i]

			if _is_timed_regen_buff(buff, flat_regen_stat_buff, regen_modifier_stat_buff) then
				-- a buff that can't be measured outside its extension stays in the projection, as before
				pcall(buff.update_stat_buffs, buff, timed_stat_buffs, t)
			end
		end

		share.flat_regen_total = flat_regen_total
		share.regen_modifier_total = regen_modifier_total
		share.flat_regen = timed_stat_buffs[flat_regen_stat_buff] - stat_buff_base_values[flat_regen_stat_buff]
		share.regen_modifier = timed_stat_buffs[regen_modifier_stat_buff]
			- stat_buff_base_values[regen_modifier_stat_buff]
	end

	return share.flat_regen, share.regen_modifier
end

-- Seconds until the next charge of an ability, using the regen maths of
-- PlayerUnitAbilityExtension._update_ability_resources at the recharge speed of permanent buffs only. Timed
-- buffs are left out, so the countdown never assumes they last until the charge is ready and never jumps back
-- up when they end; while one is active the countdown runs slightly faster than the clock instead. Returns nil
-- when no charge is regenerating, regen is paused, the active ability is draining its own resource, or regen is
-- not progressing. Only pass the local player's ability extension: husk extensions error on
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
	local stat_buffs = buff_extension and buff_extension:stat_buffs()

	if stat_buffs then
		local flat_regen_stat_buff = flat_regen_stat_buffs[ability_type]

		if not flat_regen_stat_buff then
			flat_regen_stat_buff = ability_type .. "_resource_flat_regen"
			flat_regen_stat_buffs[ability_type] = flat_regen_stat_buff
			regen_modifier_stat_buffs[ability_type] = ability_type .. "_resource_regen_modifier"
		end

		local regen_modifier_stat_buff = regen_modifier_stat_buffs[ability_type]
		local timed_flat_regen, timed_regen_modifier = _timed_regen_share(
			buff_extension,
			stat_buffs,
			ability_type,
			flat_regen_stat_buff,
			regen_modifier_stat_buff
		)

		regen_per_second = (regen_per_second + (stat_buffs[flat_regen_stat_buff] or 0) - timed_flat_regen)
			* ((stat_buffs[regen_modifier_stat_buff] or 1) - timed_regen_modifier)
	end

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
