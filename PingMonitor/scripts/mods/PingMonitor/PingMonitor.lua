-- PingMonitor
-- Description: Adds ping to the HUD
-- Author: raindish
local mod = get_mod("PingMonitor")
local UIWidget = require("scripts/managers/ui/ui_widget")

-- Current average
mod.num_measurements = 30

-- Empty the sampling window and drop the shown values. ping and jitter stay nil
-- until a valid sample arrives, so the HUD never shows a value that wasn't measured
mod.reset_measurements = function()
	mod.measurements = {}
	mod.ping = nil
	mod.jitter = nil
end

mod.reset_measurements()

-- x - x is 0 for every finite number, NaN for NaN and ±inf
local function is_finite_number(value)
	return type(value) == "number" and value - value == 0
end

-- Created once at load, the HUD assigns them every frame and the renderer only reads them
local WHITE = Color.white(255, true)
local GREEN = Color.online_green(255, true)
local ORANGE = Color.citadel_troll_slayer_orange(255, true)
local RED = Color.citadel_wild_rider_red(255, true)

-- Get color from number
mod.ping_color = function(jitter, ping)
	local p10 = ping / 100 * 10
	local p15 = ping / 100 * 15

	if jitter <= p10 then
		return GREEN
	elseif jitter <= p15 then
		return ORANGE
	elseif ping == ping then
		return RED
	end

	-- A NaN ping fails every comparison above and can't be graded
	return WHITE
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

-- Clear measurements and the shown ping on game state change because
-- different servers can have different pings
mod.on_game_state_changed = function()
	mod.reset_measurements()
end

-- Add a sample the reporter just took and update the averages
local function take_sample(latest_ping)
	if not is_finite_number(latest_ping) then
		return
	end

	local measurements = mod.measurements
	measurements[#measurements + 1] = latest_ping
	measurements = mod.tail(measurements, mod.num_measurements)
	mod.measurements = measurements
	mod.ping = math.round(table.average(measurements))
	mod.jitter = math.round(mod.avg_difference(measurements))
	-- mod:echo("latest: %d, avg: %d, jitter: %d, measures: %d", latest_ping, mod.ping, mod.jitter, #mod.measurements)
end

-- Take measurements, called once a second
mod:hook("PingReporter", "_take_measure", function(func, self, ...)
	local measures = self._measures
	local count = measures and #measures

	func(self, ...)

	-- The original returns without appending when this isn't a client or there's no host,
	-- e.g. local-hosted games, leaving the tail missing or an older, already counted sample.
	-- _measures is a plain array, so the slot after the old length is this call's sample or nil
	if count then
		return take_sample(measures[count + 1])
	end
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
