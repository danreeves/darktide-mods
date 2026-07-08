-- Healthbars
-- Description: Show healthbars from the Psykanium in regular game modes
-- Author: raindish
local mod = get_mod("Healthbars")
local Breeds = require("scripts/settings/breed/breeds")
local BreedActions = require("scripts/settings/breed/breed_actions")
require("scripts/extension_systems/health/health_extension_base")
local HealthExtension = require("scripts/extension_systems/health/health_extension")
require("scripts/extension_systems/behavior/nodes/actions/bt_stagger_action")
local MarkerTemplate = mod:io_dofile("Healthbars/scripts/mods/Healthbars/HealthbarMarker")

mod.textures = {
	bleed = "content/ui/materials/icons/presets/preset_13",
	chordclaw_bleed = "content/ui/materials/icons/item_types/scars",
	burn = "content/ui/materials/icons/presets/preset_20",
	phosphor_burn = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_rotten_armor",
	warpfire = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_ember",
	toxin = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_nurgle",
	electrocuted = "content/ui/materials/icons/presets/preset_11",
	weapon_malfunction = "content/ui/materials/icons/circumstances/darkness_01",
	brittleness = "content/ui/materials/icons/presets/preset_04",
	stagger = "content/ui/materials/icons/throwables/hud/small/party_psyker",
	skullcrusher = "content/ui/materials/icons/presets/preset_05",
	thunderstrike = "content/ui/materials/icons/presets/preset_18",
	melee_damage_taken = "content/ui/materials/icons/presets/preset_01",
	damage_taken = "content/ui/materials/icons/presets/preset_14",
	empyric_shock = "content/ui/materials/icons/presets/preset_12",
}
local WARPFIRE_COLOR_OPTIONS = {
	warpfire_color_option_one = { 255, 200, 255, 255 },
	warpfire_color_option_two = { 255, 0, 230, 255 },
	warpfire_color_option_three = { 255, 80, 160, 255 },
	warpfire_color_option_four = { 255, 45, 140, 255 },
	warpfire_color_option_five = { 255, 138, 43, 226 },
}

local ScriptUnit = ScriptUnit
local Managers = Managers
local pairs = pairs
local math_min = math.min
local setmetatable = setmetatable
local table_remove = table.remove
local type = type
local string_match = string.match

local function copy_color(color)
	return { color[1], color[2], color[3], color[4] }
end

local function new_marker_cache()
	return setmetatable({}, { __mode = "k" })
end

local function is_unit_alive(unit)
	local alive = rawget(_G, "ALIVE")
	return alive and alive[unit] or false
end

mod._custom_marker_units = mod._custom_marker_units or new_marker_cache()
mod._last_hit_time = mod._last_hit_time or new_marker_cache()
mod._last_hit_weakspot = mod._last_hit_weakspot or new_marker_cache()
mod._last_hit_was_critical = mod._last_hit_was_critical or new_marker_cache()
mod._stagger_end_times = mod._stagger_end_times or new_marker_cache()
mod._estimated_stagger_start_times = mod._estimated_stagger_start_times or new_marker_cache()
mod._estimated_stagger_states = mod._estimated_stagger_states or new_marker_cache()
mod._animation_events_available = false

local function stagger_feature_enabled()
	return mod:get("stagger") == true
end

local STAGGER_ANIMATION_EVENT_PACK = "healthbars_stagger"
local stagger_animation_events = {}
local stagger_animation_event_lookup = {}

local function collect_stagger_animation_events(value)
	local value_type = type(value)

	if value_type == "string" then
		if not stagger_animation_event_lookup[value] then
			stagger_animation_event_lookup[value] = true
			stagger_animation_events[#stagger_animation_events + 1] = value
		end
	elseif value_type == "table" then
		for _, child in pairs(value) do
			collect_stagger_animation_events(child)
		end
	end
end

for _, breed_actions in pairs(BreedActions) do
	for _, action_data in pairs(breed_actions) do
		if type(action_data) == "table" then
			collect_stagger_animation_events(action_data.stagger_anims)
			collect_stagger_animation_events(action_data.running_stagger_anim_left)
			collect_stagger_animation_events(action_data.running_stagger_anim_right)
		end
	end
end

local function clear_estimated_stagger(unit)
	mod._estimated_stagger_start_times[unit] = nil
	mod._estimated_stagger_states[unit] = nil
end

local function on_stagger_animation_started(_event_name, _event_index, unit, _first_person, context)
	if context == "minion" and unit and stagger_feature_enabled() then
		local time_manager = Managers.time

		mod._estimated_stagger_start_times[unit] = time_manager and time_manager:time("gameplay") or true
		mod._estimated_stagger_states[unit] = nil
	end
end

local function on_stagger_animation_finished(_event_name, _event_index, unit, _first_person, context)
	if context == "minion" and unit then
		mod._stagger_end_times[unit] = nil
		clear_estimated_stagger(unit)
	end
end

local animation_events_pack_definition = {
	[STAGGER_ANIMATION_EVENT_PACK] = stagger_animation_events,
}
local animation_events_callback_definition = {
	[STAGGER_ANIMATION_EVENT_PACK] = on_stagger_animation_started,
	stagger_finished = on_stagger_animation_finished,
}

local function publish_animation_events_definitions(enabled)
	mod.animation_events_add_packs = enabled and animation_events_pack_definition or nil
	mod.animation_events_add_callbacks = enabled and animation_events_callback_definition or nil
end

local function contains_reference(array, wanted)
	if array then
		for i = 1, #array do
			if array[i] == wanted then
				return true
			end
		end
	end

	return false
end

local function remove_reference(array, wanted)
	if array then
		for i = #array, 1, -1 do
			if array[i] == wanted then
				table_remove(array, i)
			end
		end
	end
end

local function animation_event_still_registered(animation_events, wanted)
	for _, pack_definition in pairs(animation_events.packs) do
		for _, event_names in pairs(pack_definition) do
			for i = 1, #event_names do
				if event_names[i] == wanted then
					return true
				end
			end
		end
	end

	for _, callback_definition in pairs(animation_events.events) do
		if callback_definition[wanted] then
			return true
		end
	end

	for i = 1, #animation_events.callbacks do
		if animation_events.callbacks[i].event_name == wanted then
			return true
		end
	end

	return false
end

local function register_animation_events_definitions(animation_events)
	publish_animation_events_definitions(true)

	if not contains_reference(animation_events.packs, animation_events_pack_definition) then
		animation_events.packs[#animation_events.packs + 1] = animation_events_pack_definition

		for i = 1, #stagger_animation_events do
			animation_events.all_events[stagger_animation_events[i]] = true
		end
	end

	if not contains_reference(animation_events.events, animation_events_callback_definition) then
		animation_events.events[#animation_events.events + 1] = animation_events_callback_definition

		for event_name, callback in pairs(animation_events_callback_definition) do
			animation_events.all_events[event_name] = true
			animation_events:register_callback(event_name, callback)
		end
	end

	if type(animation_events.clear_indices) == "function" then
		animation_events:clear_indices()
	end
end

local function unregister_animation_events_definitions(animation_events)
	publish_animation_events_definitions(false)

	if not animation_events then
		return
	end

	remove_reference(animation_events.packs, animation_events_pack_definition)
	remove_reference(animation_events.events, animation_events_callback_definition)

	local callbacks = animation_events.callbacks

	for i = #callbacks, 1, -1 do
		local callback = callbacks[i].callback

		if callback == on_stagger_animation_started or callback == on_stagger_animation_finished then
			table_remove(callbacks, i)
		end
	end

	for event_name in pairs(stagger_animation_event_lookup) do
		if not animation_event_still_registered(animation_events, event_name) then
			animation_events.all_events[event_name] = nil
		end
	end

	for event_name in pairs(animation_events_callback_definition) do
		if not animation_event_still_registered(animation_events, event_name) then
			animation_events.all_events[event_name] = nil
		end
	end

	if type(animation_events.clear_indices) == "function" then
		animation_events:clear_indices()
	end
end

local function refresh_animation_events_availability()
	local animation_events = get_mod("animation_events")
	local available = animation_events and type(animation_events.minion_handle_event) == "function" and
		type(animation_events.handle_callbacks) == "function" and type(animation_events.register_callback) == "function" and
		type(animation_events.packs) == "table" and type(animation_events.events) == "table" and
		type(animation_events.callbacks) == "table" and type(animation_events.all_events) == "table"

	mod._animation_events_available = available == true

	if not available then
		mod._estimated_stagger_start_times = new_marker_cache()
		mod._estimated_stagger_states = new_marker_cache()
	end

	return available == true
end

publish_animation_events_definitions(mod:get("stagger") == true)

local COLOR_BLEED = { 255, 255, 0, 0 }
local COLOR_BURN = { 255, 255, 102, 0 }
local COLOUR_PHOSPHOR_BURN = { 255, 255, 130, 20 }
local COLOR_TOXIN = { 255, 0, 255, 0 }
local COLOR_ELECTROCUTED = { 255, 255, 235, 245 }
local COLOR_WEAPON_MALFUNCTION = { 255, 255, 245, 80 }

local function refresh_colors()
	local warpfire_key = mod:get("warpfire_color_option") or "warpfire_color_option_three"

	mod.colors = {
		bleed = COLOR_BLEED,
		chordclaw_bleed = COLOR_BLEED,
		burn = COLOR_BURN,
		phosphor_burn = COLOUR_PHOSPHOR_BURN,
		warpfire = copy_color(WARPFIRE_COLOR_OPTIONS[warpfire_key] or WARPFIRE_COLOR_OPTIONS.warpfire_color_option_three),
		toxin = COLOR_TOXIN,
		electrocuted = COLOR_ELECTROCUTED,
		weapon_malfunction = COLOR_WEAPON_MALFUNCTION,
		-- brittleness, skullcrusher, thunderstrike and damage taken debuffs are calculated by applied stacks
	}
end

refresh_colors()

function mod.on_all_mods_loaded()
	if not refresh_animation_events_availability() then
		publish_animation_events_definitions(false)
	end

	-- Preload icon packages
	local function load_package(package_name)
		if not Managers.package:has_loaded(package_name) then
			Managers.package:load(package_name, "Healthbars")
		end
	end

	local required_icon_packages = mod.required_icon_packages

	if required_icon_packages then
		for i = 1, #required_icon_packages do
			load_package(required_icon_packages[i])
		end
	end
end

local display_modes_by_breed = {}
local MUTATOR_BREED_SETTING_OVERRIDES = {
	chaos_mutator_ritualist = "cultist_ritualist",
}
local PSYKHANIUM_BEHAVIOR_NORMAL = "normal"
local PSYKHANIUM_BEHAVIOR_VANILLA_ONLY = "vanilla_only"
local PSYKHANIUM_BEHAVIOR_FULL_DEBUG = "full_debug"

local DISPLAY_MODE_FULL = {
	show_healthbar = true,
	show_dots = true,
	show_debuffs = true,
}
local DISPLAY_MODES = {
	full = DISPLAY_MODE_FULL,
	disabled = {
		show_healthbar = false,
		show_dots = false,
		show_debuffs = false,
	},
	healthbar_only = {
		show_healthbar = true,
		show_dots = false,
		show_debuffs = false,
	},
	healthbar_dots = {
		show_healthbar = true,
		show_dots = true,
		show_debuffs = false,
	},
	healthbar_debuffs = {
		show_healthbar = true,
		show_dots = false,
		show_debuffs = true,
	},
}

local function get_display_mode(setting_id)
	local value = mod:get(setting_id)

	if value == true then
		value = "full"
		mod:set(setting_id, value, false)
	elseif value == false then
		value = "disabled"
		mod:set(setting_id, value, false)
	end

	return DISPLAY_MODES[value]
end

local function cache_display_modes()
	for breed_name in pairs(Breeds) do
		local setting_id = MUTATOR_BREED_SETTING_OVERRIDES[breed_name]

		if setting_id then
			display_modes_by_breed[breed_name] = get_display_mode(setting_id)
		elseif string_match(breed_name, "mutator") then
			display_modes_by_breed[breed_name] = get_display_mode((breed_name):gsub("_mutator", ""))
		else
			display_modes_by_breed[breed_name] = get_display_mode(breed_name)
		end
	end
end

local function is_psykhanium()
	local game_mode_manager = Managers.state and Managers.state.game_mode
	return game_mode_manager and game_mode_manager:game_mode_name() == "shooting_range"
end

local function current_psykhanium_behavior()
	local behavior = nil
	local in_psykhanium = is_psykhanium()

	if in_psykhanium then
		behavior = mod:get("psykhanium_healthbar_behavior") or PSYKHANIUM_BEHAVIOR_NORMAL
	end

	mod._active_psykhanium_healthbar_behavior = behavior
	mod._psykhanium_full_debug_display = behavior == PSYKHANIUM_BEHAVIOR_FULL_DEBUG
	mod._psykhanium_vanilla_only = behavior == PSYKHANIUM_BEHAVIOR_VANILLA_ONLY
	mod._inactive_outside_psykhanium = not in_psykhanium and mod:get("only_active_in_psykhanium") == true

	return behavior
end

local function healthbar_breed(unit)
	if not is_unit_alive(unit) then
		return nil
	end

	local unit_data_extension = ScriptUnit.has_extension(unit, "unit_data_system")
	if not unit_data_extension then
		return nil
	end

	return unit_data_extension:breed()
end

local function should_enable_healthbar(unit, psykhanium_behavior)
	local breed = healthbar_breed(unit)
	if not breed then
		return false
	end

	local behavior = psykhanium_behavior
	if behavior == nil then
		behavior = current_psykhanium_behavior()
	end

	if mod._inactive_outside_psykhanium then
		return false
	end

	if behavior == PSYKHANIUM_BEHAVIOR_VANILLA_ONLY then
		return false
	end

	if behavior == PSYKHANIUM_BEHAVIOR_FULL_DEBUG then
		return display_modes_by_breed[breed.name] ~= nil
	end

	local display_mode = display_modes_by_breed[breed.name]

	return display_mode and display_mode.show_healthbar == true or false
end

local function add_custom_healthbar_marker(unit)
	if not mod:is_enabled() then
		return false
	end

	if not should_enable_healthbar(unit) then
		return false
	end

	local event_manager = Managers.event
	if not event_manager then
		return false
	end

	local custom_marker_units = mod._custom_marker_units
	if custom_marker_units[unit] then
		return false
	end

	custom_marker_units[unit] = true
	event_manager:trigger("add_world_marker_unit", MarkerTemplate.name, unit)

	return true
end

local function visit_units_from_container(container, seen_units, visitor)
	if not container then
		return 0
	end

	local count = 0

	for key, value in pairs(container) do
		local unit = nil

		if is_unit_alive(key) then
			unit = key
		elseif type(value) == "table" then
			local value_unit = value._unit
			if is_unit_alive(value_unit) then
				unit = value_unit
			end
		end

		if unit and not seen_units[unit] then
			seen_units[unit] = true

			if visitor(unit) then
				count = count + 1
			end
		end
	end

	return count
end

local function remove_custom_healthbar_markers(world_markers)
	local markers_by_type = world_markers and world_markers._markers_by_type
	local custom_markers = markers_by_type and markers_by_type[MarkerTemplate.name]
	local event_manager = Managers.event

	if not custom_markers or not event_manager then
		return 0
	end

	local custom_marker_units = mod._custom_marker_units
	local removed = 0

	for i = #custom_markers, 1, -1 do
		local marker = custom_markers[i]

		if marker then
			if custom_marker_units then
				custom_marker_units[marker.unit] = nil
			end

			event_manager:trigger("remove_world_marker", marker.id)
			removed = removed + 1
		end
	end

	return removed
end

local function resync_existing_healthbars()
	if not mod:is_enabled() then
		return 0
	end

	local state_manager = Managers.state
	local extension_manager = state_manager and state_manager.extension
	if not extension_manager then
		return 0
	end

	local health_system = extension_manager:system("health_system")
	if not health_system then
		return 0
	end

	local seen_units = {}
	local behavior = current_psykhanium_behavior()
	local world_markers = mod._world_markers

	if mod._inactive_outside_psykhanium then
		return remove_custom_healthbar_markers(world_markers)
	end

	if not behavior or not world_markers then
		local added = 0
		local add_custom = function(unit)
			return add_custom_healthbar_marker(unit)
		end

		added = added + visit_units_from_container(health_system._unit_to_extension_map, seen_units, add_custom)
		added = added + visit_units_from_container(health_system._health_extensions, seen_units, add_custom)
		added = added + visit_units_from_container(health_system._extensions, seen_units, add_custom)

		return added
	end

	local markers_by_type = world_markers._markers_by_type
	local custom_markers = markers_by_type and markers_by_type[MarkerTemplate.name]
	local vanilla_markers = markers_by_type and markers_by_type.damage_indicator
	local custom_by_unit = {}
	local vanilla_by_unit = {}

	if custom_markers then
		for i = 1, #custom_markers do
			local marker = custom_markers[i]
			custom_by_unit[marker.unit] = marker.id
		end
	end

	if vanilla_markers then
		for i = 1, #vanilla_markers do
			local marker = vanilla_markers[i]
			vanilla_by_unit[marker.unit] = marker.id
		end
	end

	local marker_ids_to_remove = {}
	local custom_units_to_add = {}
	local vanilla_units_to_add = {}
	local custom_marker_units = mod._custom_marker_units

	local function reconcile_unit(unit)
		local breed = healthbar_breed(unit)
		if not breed or display_modes_by_breed[breed.name] == nil then
			return false
		end

		if should_enable_healthbar(unit, behavior) then
			local vanilla_marker_id = vanilla_by_unit[unit]
			if vanilla_marker_id then
				marker_ids_to_remove[#marker_ids_to_remove + 1] = vanilla_marker_id
				vanilla_by_unit[unit] = nil
			end

			if not custom_by_unit[unit] then
				custom_marker_units[unit] = nil
				custom_units_to_add[#custom_units_to_add + 1] = unit
			end
		else
			local custom_marker_id = custom_by_unit[unit]
			if custom_marker_id then
				marker_ids_to_remove[#marker_ids_to_remove + 1] = custom_marker_id
				custom_by_unit[unit] = nil
				custom_marker_units[unit] = nil
			end

			if not vanilla_by_unit[unit] then
				vanilla_units_to_add[#vanilla_units_to_add + 1] = unit
			end
		end

		return true
	end

	visit_units_from_container(health_system._unit_to_extension_map, seen_units, reconcile_unit)
	visit_units_from_container(health_system._health_extensions, seen_units, reconcile_unit)
	visit_units_from_container(health_system._extensions, seen_units, reconcile_unit)

	local event_manager = Managers.event

	for i = 1, #marker_ids_to_remove do
		event_manager:trigger("remove_world_marker", marker_ids_to_remove[i])
	end

	local added = 0

	for i = 1, #custom_units_to_add do
		if add_custom_healthbar_marker(custom_units_to_add[i]) then
			added = added + 1
		end
	end

	for i = 1, #vanilla_units_to_add do
		event_manager:trigger("add_world_marker_unit", "damage_indicator", vanilla_units_to_add[i])
		added = added + 1
	end

	return added
end

local function hide_existing_boss_indicators()
	local boss_health = mod._boss_health_element
	local widget_groups = boss_health and boss_health._widget_groups

	if not widget_groups then
		return
	end

	local hide_indicator = MarkerTemplate.hide_vanilla_boss_indicator

	if not hide_indicator then
		return
	end

	for i = 1, #widget_groups do
		local widget_group = widget_groups[i]
		local widget = widget_group and widget_group.healthbars_indicators

		if widget then
			hide_indicator(widget)
		end
	end
end

local function register_world_marker_template(world_markers)
	local marker_templates = world_markers and world_markers._marker_templates

	if not marker_templates then
		return false
	end

	marker_templates[MarkerTemplate.name] = MarkerTemplate
	mod._world_markers = world_markers

	return true
end

local function current_world_markers()
	local ui_manager = Managers.ui
	local hud = ui_manager and ui_manager:get_hud()

	return hud and hud:element("HudElementWorldMarkers")
end

local function setting_requires_marker_resync(setting_id)
	if setting_id == "only_active_in_psykhanium" or setting_id == "psykhanium_healthbar_behavior" or
		display_modes_by_breed[setting_id] ~= nil then
		return true
	end

	for _, mapped_setting_id in pairs(MUTATOR_BREED_SETTING_OVERRIDES) do
		if mapped_setting_id == setting_id then
			return true
		end
	end

	return false
end

cache_display_modes()
mod._healthbar_breed_display_modes = display_modes_by_breed
current_psykhanium_behavior()

mod.on_setting_changed = function(setting_id)
	cache_display_modes()
	refresh_colors()
	current_psykhanium_behavior()

	if not mod:is_enabled() then
		return
	end

	if setting_id == "stagger" then
		mod._stagger_end_times = new_marker_cache()
		mod._estimated_stagger_start_times = new_marker_cache()
		mod._estimated_stagger_states = new_marker_cache()

		if stagger_feature_enabled() then
			if refresh_animation_events_availability() then
				register_animation_events_definitions(get_mod("animation_events"))
			else
				publish_animation_events_definitions(false)
			end
		else
			unregister_animation_events_definitions(get_mod("animation_events"))
		end
	end

	if setting_id == "show_vanilla_boss_bar_indicators" then
		if mod:get("show_vanilla_boss_bar_indicators") ~= true then
			hide_existing_boss_indicators()
		end

		return
	end

	if setting_id == "only_active_in_psykhanium" and mod._inactive_outside_psykhanium then
		hide_existing_boss_indicators()
	end

	if setting_requires_marker_resync(setting_id) then
		resync_existing_healthbars()
	end
end

mod.on_disabled = function()
	remove_custom_healthbar_markers(current_world_markers() or mod._world_markers)
	mod._world_markers = nil
	mod._custom_marker_units = new_marker_cache()
	mod._stagger_end_times = new_marker_cache()
	mod._estimated_stagger_start_times = new_marker_cache()
	mod._estimated_stagger_states = new_marker_cache()
	unregister_animation_events_definitions(get_mod("animation_events"))
	hide_existing_boss_indicators()
end

mod.on_enabled = function()
	if stagger_feature_enabled() then
		if refresh_animation_events_availability() then
			register_animation_events_definitions(get_mod("animation_events"))
		else
			publish_animation_events_definitions(false)
		end
	end

	if register_world_marker_template(current_world_markers()) then
		current_psykhanium_behavior()
		resync_existing_healthbars()
	end
end

mod:hook_safe("HudElementWorldMarkers", "init", function(self)
	register_world_marker_template(self)
	mod._custom_marker_units = new_marker_cache()
	mod._last_hit_time = new_marker_cache()
	mod._last_hit_weakspot = new_marker_cache()
	mod._last_hit_was_critical = new_marker_cache()
	mod._stagger_end_times = new_marker_cache()
	mod._estimated_stagger_start_times = new_marker_cache()
	mod._estimated_stagger_states = new_marker_cache()
	current_psykhanium_behavior()
	resync_existing_healthbars()
end)

mod:hook_require("scripts/ui/hud/elements/boss_health/hud_element_boss_health_definitions", function(instance)
	local HudElementBossHealthSettings = require("scripts/ui/hud/elements/boss_health/hud_element_boss_health_settings")
	local health_bar_width = HudElementBossHealthSettings.size[1]
	local health_bar_width_small = HudElementBossHealthSettings.size_small[1]
	local small_bar_center_offset = (health_bar_width - health_bar_width_small) * 0.5

	instance.single_target_widget_definitions.healthbars_indicators =
		MarkerTemplate.create_vanilla_boss_indicator_definition(health_bar_width, 0)
	instance.left_double_target_widget_definitions.healthbars_indicators =
		MarkerTemplate.create_vanilla_boss_indicator_definition(health_bar_width_small, -small_bar_center_offset)
	instance.right_double_target_widget_definitions.healthbars_indicators =
		MarkerTemplate.create_vanilla_boss_indicator_definition(health_bar_width_small, small_bar_center_offset)
end)

mod:hook_safe("HudElementBossHealth", "update", function(self, dt)
	mod._boss_health_element = self

	local widget_groups = self._widget_groups
	local active_targets_array = self._active_targets_array

	if not widget_groups or not active_targets_array then
		return
	end

	local num_active_targets = #active_targets_array
	local num_health_bars_to_update = math_min(num_active_targets, self._max_health_bars or 2)

	for i = 1, num_health_bars_to_update do
		local widget_group_index = num_active_targets > 1 and i + 1 or i
		local widget_group = widget_groups[widget_group_index]
		local widget = widget_group and widget_group.healthbars_indicators

		if widget then
			MarkerTemplate.update_vanilla_boss_indicator(widget, active_targets_array[i], dt)
		end
	end
end)

mod:hook_safe(
	"BtStaggerAction",
	"enter",
	function(_self, unit, _breed, _blackboard, scratchpad)
		local stagger_time = scratchpad and scratchpad.stagger_time

		if unit and stagger_feature_enabled() and type(stagger_time) == "number" then
			mod._stagger_end_times[unit] = stagger_time
		end
	end
)

mod:hook_safe(
	"BtStaggerAction",
	"leave",
	function(_self, unit)
		if unit then
			mod._stagger_end_times[unit] = nil
			clear_estimated_stagger(unit)
		end
	end
)

mod:hook_safe(
	"HealthExtension",
	"init",
	function(_self, _extension_init_context, unit, _extension_init_data, _game_object_data)
		add_custom_healthbar_marker(unit)
	end
)

mod:hook_safe(
	"HuskHealthExtension",
	"init",
	function(self, _extension_init_context, unit, _extension_init_data, _game_session, _game_object_id, _owner_id)
		-- Make sure husks have the methods needed
		self.set_last_damaging_unit = HealthExtension.set_last_damaging_unit
		self.last_damaging_unit = HealthExtension.last_damaging_unit
		self.last_hit_zone_name = HealthExtension.last_hit_zone_name
		self.last_hit_was_critical = HealthExtension.last_hit_was_critical
		self.was_hit_by_critical_hit_this_render_frame = HealthExtension.was_hit_by_critical_hit_this_render_frame

		-- Set has a healthbar
		add_custom_healthbar_marker(unit)
	end
)

mod:hook_safe(
	"AttackReportManager",
	"add_attack_result",
	function(_self, _damage_profile, attacked_unit, _attacking_unit, _attack_direction, _hit_world_position,
			hit_weakspot, damage, _attack_result, _attack_type, _damage_efficiency, is_critical_strike)
		if attacked_unit and damage > 0 and mod._custom_marker_units[attacked_unit] then
			local hit_time = Managers.time:time("gameplay")
			local same_frame = mod._last_hit_time[attacked_unit] == hit_time

			mod._last_hit_time[attacked_unit] = hit_time
			mod._last_hit_weakspot[attacked_unit] = hit_weakspot == true
			mod._last_hit_was_critical[attacked_unit] =
				same_frame and mod._last_hit_was_critical[attacked_unit] == true or is_critical_strike == true
		end
	end
)

mod:hook("HudElementWorldMarkers", "event_add_world_marker_unit", function(func, self, marker_type, unit, callback, data)
	if marker_type == MarkerTemplate.name and not register_world_marker_template(self) then
		mod._custom_marker_units[unit] = nil

		return
	end

	if marker_type == "damage_indicator" then
		local behavior = current_psykhanium_behavior()

		if behavior and should_enable_healthbar(unit, behavior) then
			return
		end
	end

	return func(self, marker_type, unit, callback, data)
end)
