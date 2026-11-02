-- PingMonitor
-- Description: Adds ping to the HUD
-- Author: raindish
local mod = get_mod("PingMonitor")
local UIWidget = require("scripts/managers/ui/ui_widget")
local Hud = require("scripts/utilities/ui/hud")

-- x - x is 0 for every finite number, NaN for NaN and ±inf
local function is_finite_number(value)
	return type(value) == "number" and value - value == 0
end

-- The averaging_samples option rounded into its 1-120 range. Anything else the
-- settings file can hold falls back to the option's default of 30
local function read_num_measurements()
	local value = mod:get("averaging_samples")

	if is_finite_number(value) then
		return math.clamp(math.round(value), 1, 120)
	end

	return 30
end

-- Current average
mod.num_measurements = read_num_measurements()

-- Read once at load and on change, the HUD element checks it every frame
mod.always_visible = mod:get("always_visible")

local DEFAULT_POSITION_ANCHOR = "top_center"
local DEFAULT_POSITION_X = 0
local DEFAULT_POSITION_Y = 12
-- The position_x and position_y ranges in PingMonitor_data
local POSITION_X_LIMIT = 4000
local POSITION_Y_LIMIT = 2200

-- The scenegraph alignments of each position_anchor choice, and how far across the free
-- space each one puts the panel. Anything not listed isn't a valid anchor
local POSITION_ANCHORS = {
	top_left = { horizontal_alignment = "left", vertical_alignment = "top", x_factor = 0, y_factor = 0 },
	top_center = { horizontal_alignment = "center", vertical_alignment = "top", x_factor = 0.5, y_factor = 0 },
	top_right = { horizontal_alignment = "right", vertical_alignment = "top", x_factor = 1, y_factor = 0 },
	center_left = { horizontal_alignment = "left", vertical_alignment = "center", x_factor = 0, y_factor = 0.5 },
	center = { horizontal_alignment = "center", vertical_alignment = "center", x_factor = 0.5, y_factor = 0.5 },
	center_right = { horizontal_alignment = "right", vertical_alignment = "center", x_factor = 1, y_factor = 0.5 },
	bottom_left = { horizontal_alignment = "left", vertical_alignment = "bottom", x_factor = 0, y_factor = 1 },
	bottom_center = { horizontal_alignment = "center", vertical_alignment = "bottom", x_factor = 0.5, y_factor = 1 },
	bottom_right = { horizontal_alignment = "right", vertical_alignment = "bottom", x_factor = 1, y_factor = 1 },
}

-- ping_panel's size in HudElementPingMonitor, and the box its passes draw in relative to the
-- panel's top left. The icon's dot sits in the middle of a mostly transparent 100x100 texture,
-- 10 units in and 12.5 down, and the text starts 30 units in and runs past the panel's right
-- edge for four-digit pings
local PANEL_WIDTH = 75
local PANEL_HEIGHT = 25
local DRAWN_LEFT = -10
local DRAWN_RIGHT = 90
local DRAWN_TOP = -7.5
local DRAWN_BOTTOM = 32.5

-- The position_anchor option if it's one of the dropdown's choices, else the default top_center
local function read_position_anchor()
	local value = mod:get("position_anchor")

	if POSITION_ANCHORS[value] then
		return value
	end

	return DEFAULT_POSITION_ANCHOR
end

-- A position offset option rounded into its range. Anything else the settings file can hold
-- falls back to the option's default
local function read_position_offset(setting_id, limit, default_value)
	local value = mod:get(setting_id)

	if is_finite_number(value) then
		return math.clamp(math.round(value), -limit, limit)
	end

	return default_value
end

-- Read once at load and on change, the HUD element places ping_panel from them whenever
-- layout_version changes
mod.position_anchor = read_position_anchor()
mod.position_x = read_position_offset("position_x", POSITION_X_LIMIT, DEFAULT_POSITION_X)
mod.position_y = read_position_offset("position_y", POSITION_Y_LIMIT, DEFAULT_POSITION_Y)
mod.layout_version = 0

-- The offsets closest to x and y that keep everything the indicator draws inside a viewport of
-- the given size, measured from where the anchor puts the panel's top left
local function clamp_offsets(anchor, x, y, viewport_width, viewport_height)
	local start_x = (viewport_width - PANEL_WIDTH) * anchor.x_factor
	local start_y = (viewport_height - PANEL_HEIGHT) * anchor.y_factor

	return math.clamp(x, -DRAWN_LEFT - start_x, viewport_width - DRAWN_RIGHT - start_x),
		math.clamp(y, -DRAWN_TOP - start_y, viewport_height - DRAWN_BOTTOM - start_y)
end

-- The alignments and offsets HudElementPingMonitor places ping_panel with, at the HUD scale it
-- draws with. The viewport is the screen in that scale's UI units
mod.ping_panel_layout = function(scale)
	local anchor = POSITION_ANCHORS[mod.position_anchor]
	local x, y = clamp_offsets(
		anchor,
		mod.position_x,
		mod.position_y,
		RESOLUTION_LOOKUP.width / scale,
		RESOLUTION_LOOKUP.height / scale
	)

	return anchor.horizontal_alignment, anchor.vertical_alignment, x, y
end

-- The offsets from another anchor that keep the indicator where it's shown now
local function convert_offsets(from_anchor, to_anchor)
	local scale = Hud.hud_scale()
	local viewport_width = RESOLUTION_LOOKUP.width / scale
	local viewport_height = RESOLUTION_LOOKUP.height / scale
	-- Where it's shown, which the screen edges may have pushed in from the saved offsets
	local x, y = clamp_offsets(from_anchor, mod.position_x, mod.position_y, viewport_width, viewport_height)
	local free_width = viewport_width - PANEL_WIDTH
	local free_height = viewport_height - PANEL_HEIGHT

	-- Whole-unit distances between the anchors, so switching back and forth doesn't drift
	x = x + math.round(free_width * from_anchor.x_factor) - math.round(free_width * to_anchor.x_factor)
	y = y + math.round(free_height * from_anchor.y_factor) - math.round(free_height * to_anchor.y_factor)

	return math.clamp(math.round(x), -POSITION_X_LIMIT, POSITION_X_LIMIT),
		math.clamp(math.round(y), -POSITION_Y_LIMIT, POSITION_Y_LIMIT)
end

-- Recompute the shown values from the sampling window, which holds at least one sample here
local function update_averages()
	local measurements = mod.measurements
	mod.ping = math.round(table.average(measurements))
	mod.jitter = math.round(mod.avg_difference(measurements))
end

mod.on_setting_changed = function(setting_id)
	if setting_id == "always_visible" then
		mod.always_visible = mod:get("always_visible")
	elseif setting_id == "averaging_samples" then
		local num_measurements = read_num_measurements()
		local measurements = mod.measurements
		mod.num_measurements = num_measurements

		-- A smaller window drops the oldest samples right away, a larger one fills up with new samples
		if #measurements > num_measurements then
			mod.measurements = mod.tail(measurements, num_measurements)
			update_averages()
		end
	elseif setting_id == "position_x" then
		mod.position_x = read_position_offset("position_x", POSITION_X_LIMIT, DEFAULT_POSITION_X)
		mod.layout_version = mod.layout_version + 1
	elseif setting_id == "position_y" then
		mod.position_y = read_position_offset("position_y", POSITION_Y_LIMIT, DEFAULT_POSITION_Y)
		mod.layout_version = mod.layout_version + 1
	elseif setting_id == "position_anchor" then
		local anchor = read_position_anchor()
		local previous_anchor = mod.position_anchor

		-- A settings reset lands here too, before or after the offsets reset. on_settings_reset settles that
		if anchor ~= previous_anchor then
			local x, y = convert_offsets(POSITION_ANCHORS[previous_anchor], POSITION_ANCHORS[anchor])
			mod.position_anchor = anchor
			mod.position_x = x
			mod.position_y = y
			-- Without notify_mod, so these writes don't come back into this handler
			mod:set("position_x", x)
			mod:set("position_y", y)
			mod.layout_version = mod.layout_version + 1
		end
	end
end

-- DMF's reset sets each option back to its default in no fixed order, so the anchor conversion
-- above can run after the offsets were already reset. Once all are reset, restore the whole
-- default position, again without notify_mod
mod.on_settings_reset = function()
	mod:set("position_anchor", DEFAULT_POSITION_ANCHOR)
	mod:set("position_x", DEFAULT_POSITION_X)
	mod:set("position_y", DEFAULT_POSITION_Y)
	mod.position_anchor = DEFAULT_POSITION_ANCHOR
	mod.position_x = DEFAULT_POSITION_X
	mod.position_y = DEFAULT_POSITION_Y
	mod.layout_version = mod.layout_version + 1
end

-- Empty the sampling window and drop the shown values. ping and jitter stay nil
-- until a valid sample arrives, so the HUD never shows a value that wasn't measured
mod.reset_measurements = function()
	mod.measurements = {}
	mod.ping = nil
	mod.jitter = nil
end

mod.reset_measurements()

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

-- The hook doesn't sample while the mod is disabled, so re-enabling starts from
-- no data instead of the ping from before
mod.on_disabled = function()
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
	update_averages()
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
	-- The tactical overlay plus the groups vanilla's always-on gameplay elements use.
	-- Outside the overlay HudElementPingMonitor only draws with always_visible on
	visibility_groups = {
		"tactical_overlay",
		"alive",
		"communication_wheel",
		"emote_wheel",
		"player_in_danger_zone",
	},
}

mod:register_hud_element(hud_element_settings)
