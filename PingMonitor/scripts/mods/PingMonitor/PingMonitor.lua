-- PingMonitor
-- Description: Adds ping to the HUD
-- Author: raindish
local mod = get_mod("PingMonitor")
local UIWidget = require("scripts/managers/ui/ui_widget")

-- Current average
mod.num_measurements = 30
mod.measurements = {}
mod.ping = 0
mod.jitter = 0

-- Get color from number
mod.ping_color = function(jitter, ping)
	local p10 = ping / 100 * 10
	local p15 = ping / 100 * 15

	if jitter < p10 then
		return Color.online_green(255, true)
	elseif jitter > p10 and jitter <= p15 then
		return Color.citadel_troll_slayer_orange(255, true)
	elseif jitter > p15 then
		return Color.citadel_wild_rider_red(255, true)
	end
end

mod.tail = function(t, length)
	local end_index = #t
	local start_index = math.max(1, #t - length + 1)
	local slice = {}

	for i = start_index, end_index do
		slice[i - start_index + 1] = t[i]
	end

	return slice
end

mod.avg_difference = function(t)
	local diffs = {}

	if #t < 2 then
		return 0
	end

	for i = 2, #t do
		local a = math.min(t[i], t[i - 1])
		local b = math.max(t[i], t[i - 1])
		diffs[i - 1] = b - a
	end
	return table.average(diffs)
end

-- Clear measurements on game state change because different servers
-- can have different pings
mod.on_game_state_changed = function()
	mod.measurements = {}
end

-- Take measurements, called once a second
mod:hook_safe("PingReporter", "_take_measure", function(self)
	local latest_ping = self._measures[#self._measures]
	local measurements = mod.measurements
	table.insert(measurements, latest_ping)
	mod.measurements = mod.tail(measurements, mod.num_measurements)
	mod.ping = math.round(table.average(mod.measurements))
	mod.jitter = math.round(mod.avg_difference(mod.measurements))
	-- mod:echo("latest: %d, avg: %d, jitter: %d, measures: %d", latest_ping, mod.ping, mod.jitter, #mod.measurements)
end)

local hud_element_settings = {
	class_name = "HudElementPingMonitor",
	filename = "PingMonitor/scripts/mods/PingMonitor/HudElementPingMonitor",
	use_hud_scale = true,
	visibility_groups = {
		"tactical_overlay",
	},
}

mod:register_hud_element(hud_element_settings)
