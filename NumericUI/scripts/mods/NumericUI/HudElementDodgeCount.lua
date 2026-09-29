local mod = get_mod("NumericUI")

local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local math_ceil = math.ceil
local math_clamp = math.clamp
local math_floor = math.floor
local math_huge = math.huge
local math_lerp = math.lerp
local math_min = math.min
local math_round = math.round
local math_round_with_precision = math.round_with_precision
local string_format = string.format
local table_clone = table.clone
local table_merge_recursive = table.merge_recursive
local tostring = tostring

local size = { 250, 25 }
local scenegraph_definition = {
	screen = UIWorkspaceSettings.screen,
	container = {
		parent = "screen",
		scale = "fit",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = size,
		position = { 0, 50, 10 },
	},
}

local color_efficient = Color.terminal_text_header(255, true)
local color_inefficient = Color.ui_hud_warp_charge_low(255, true)
local color_limit = Color.ui_hud_warp_charge_high(255, true)
local color_timer_hidden = Color.text_default(0, true)

-- timer gradient colors by color name, so the update loop never allocates new color tables
local timer_gradient_colors = {}
local function _timer_gradient_color(color_name)
	local color = timer_gradient_colors[color_name]
	if not color then
		color = Color[color_name](255, true)
		timer_gradient_colors[color_name] = color
	end
	return color
end

local function _copy_color(destination, source)
	destination[1] = source[1]
	destination[2] = source[2]
	destination[3] = source[3]
	destination[4] = source[4]
end

local timer_x_offset = (-UIWorkspaceSettings.screen.size[1] + scenegraph_definition.container.size[1]) / 2

local timer_size = { 0, 0 }
local timer_color = { 0, 0, 0, 0 }
local timer_size_color = function(time_to_refresh, cooldown, current_dodges, force_show_max_width)
	-- NB: time_to_refresh will increase towards zero
	local t_max = cooldown
	if (-time_to_refresh >= t_max or force_show_max_width) and mod.setting("dodge_timer_hide_full") then
		return
	end
	local natural_time = force_show_max_width and 0 or math_clamp((time_to_refresh + t_max) / t_max, 0, 1)

	timer_size[1] = mod.setting("dodge_timer_width") * (1 - natural_time)
	timer_size[2] = mod.setting("dodge_timer_height")

	local color_start = _timer_gradient_color(mod.setting("color_start"))
	local color_end = _timer_gradient_color(mod.setting("color_end"))
	for i = 1, 4 do
		timer_color[i] = math_lerp(color_start[i], color_end[i], natural_time)
	end
	-- Hide timer if dodges are full (useful when playing with the Agile blessing)
	if current_dodges == 0 then
		timer_color[1] = 0
	end
	return timer_size, timer_color
end

local DEBUG_TEXT_Y_OFFSET = 30

local dodge_count_x_offset = mod:get("dodge_count_x_offset") or 0
local dodge_count_y_offset = mod:get("dodge_count_y_offset") or 0

local style = {
	line_spacing = 1.2,
	font_size = 25,
	drop_shadow = true,
	font_type = "machine_medium",
	text_color = color_efficient,
	size = size,
	text_horizontal_alignment = "center",
	text_vertical_alignment = "center",
}
local widget_definitions = {
	dodge_count = UIWidget.create_definition(
		{ {
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			style = table_merge_recursive(table_clone(style), {
				offset = { dodge_count_x_offset, dodge_count_y_offset },
			}),
		} },
		"container"
	),

	dodge_timer = UIWidget.create_definition({
		{
			style_id = "timer",
			pass_type = "rect",
			style = {
				color = { 255, 255, 100, 100 },
				vertical_alignment = "top",
				horizontal_alignment = "center",
				drop_shadow = true,
				size = { 100, 8 },
				offset = {
					timer_x_offset + (mod:get("dodge_timer_x_offset") or 0),
					mod:get("dodge_timer_y_offset"),
				},
			},
			visibility_function = function(_content, _style)
				return mod.setting("dodge_timer")
			end,
		},
	}, "container"),

	debug_dodge_count = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			style = table_merge_recursive(table_clone(style), {
				offset = { dodge_count_x_offset, dodge_count_y_offset + DEBUG_TEXT_Y_OFFSET },
				text_vertical_alignment = "top",
			}),
		},
	}, "container"),
}

local HudElementDodgeCount = class("HudElementDodgeCount", "HudElementBase")

HudElementDodgeCount.init = function(self, parent, draw_layer, start_scale)
	HudElementDodgeCount.super.init(self, parent, draw_layer, start_scale, {
		scenegraph_definition = scenegraph_definition,
		widget_definitions = widget_definitions,
	})

	self._is_in_hub = mod._is_in_hub()
end

HudElementDodgeCount._refresh_offsets = function(self)
	local widgets_by_name = self._widgets_by_name
	local count_x_offset = mod.setting("dodge_count_x_offset") or 0
	local count_y_offset = mod.setting("dodge_count_y_offset") or 0

	local count_offset = widgets_by_name.dodge_count.style.text.offset
	count_offset[1] = count_x_offset
	count_offset[2] = count_y_offset

	local debug_offset = widgets_by_name.debug_dodge_count.style.text.offset
	debug_offset[1] = count_x_offset
	debug_offset[2] = count_y_offset + DEBUG_TEXT_Y_OFFSET

	local timer_offset = widgets_by_name.dodge_timer.style.timer.offset
	timer_offset[1] = timer_x_offset + (mod.setting("dodge_timer_x_offset") or 0)
	timer_offset[2] = mod.setting("dodge_timer_y_offset") or 0
end

HudElementDodgeCount._resolve_player = function(self)
	local player = Managers.player:local_player(1)
	local player_unit = player and player.player_unit

	if player_unit == self._resolved_unit then
		return self._unit_data_extension ~= nil
	end

	self._resolved_unit = player_unit
	self._unit_data_extension = nil
	self._weapon_extension = nil
	self._buff_extension = nil

	if not player_unit or not ALIVE[player_unit] then
		return false
	end

	local unit_data_extension = ScriptUnit.has_extension(player_unit, "unit_data_system")
	local weapon_extension = ScriptUnit.has_extension(player_unit, "weapon_system")
	local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")

	if not unit_data_extension or not weapon_extension or not buff_extension then
		return false
	end

	self._unit_data_extension = unit_data_extension
	self._weapon_extension = weapon_extension
	self._buff_extension = buff_extension
	self._dodge_state_component = unit_data_extension:read_component("dodge_character_state")
	self._movement_state_component = unit_data_extension:read_component("movement_state")
	self._slide_state_component = unit_data_extension:read_component("slide_character_state")

	local archetype = unit_data_extension:archetype()
	self._base_dodge_template = archetype and archetype.dodge

	return true
end

local function _calculate_dodge_diminishing_return(
	dodge_character_state_component,
	movement_state_component,
	slide_state_component,
	weapon_dodge_template,
	extra_consecutive_dodges,
	t
)
	local dr_start = (weapon_dodge_template and weapon_dodge_template.diminishing_return_start or 2)
		+ extra_consecutive_dodges
	local dr_limit = dr_start + (weapon_dodge_template and weapon_dodge_template.diminishing_return_limit or 1)

	local consecutive_dodges = math_min(dodge_character_state_component.consecutive_dodges, dr_limit + dr_start)

	local is_sliding = movement_state_component.method == "sliding"
	local was_in_dodge_before_slide = slide_state_component.was_in_dodge_cooldown
	local is_dodging = movement_state_component.is_dodging == true
	local is_cooled_down = dodge_character_state_component.consecutive_dodges_cooldown < t
	if is_cooled_down and not is_dodging then
		consecutive_dodges = 0
	end

	if is_cooled_down and not was_in_dodge_before_slide and is_sliding then
		consecutive_dodges = 0
	end

	local dr_distance_modifier = weapon_dodge_template and weapon_dodge_template.diminishing_return_distance_modifier
		or 1
	local base = 1 - dr_distance_modifier
	local diminishing_return = base
		+ dr_distance_modifier * (1 - math_clamp(consecutive_dodges - dr_start, 0, dr_limit) / dr_limit)

	return consecutive_dodges, dr_start, dr_limit, diminishing_return
end

local ZERO_SIZE = { 0, 0 }

local function _set_text(widget, text)
	text = text or ""

	if widget.content.text ~= text then
		widget.content.text = text
		widget.dirty = true
	end
end

HudElementDodgeCount._clear = function(self)
	local widgets_by_name = self._widgets_by_name

	_set_text(widgets_by_name.dodge_count, "")
	_set_text(widgets_by_name.debug_dodge_count, "")
	widgets_by_name.dodge_timer.style.timer.size = ZERO_SIZE

	self._sample_valid = false
	self._displayed_count_text = nil
end

HudElementDodgeCount._sample_changed = function(
	self,
	consecutive_dodges,
	is_cooled_down,
	is_dodging,
	method,
	was_in_dodge_cooldown,
	weapon_dodge_template,
	extra_consecutive_dodges
)
	if
		self._sample_valid
		and consecutive_dodges == self._sampled_dodges
		and is_cooled_down == self._sampled_cooled_down
		and is_dodging == self._sampled_is_dodging
		and method == self._sampled_method
		and was_in_dodge_cooldown == self._sampled_slide
		and weapon_dodge_template == self._sampled_template
		and extra_consecutive_dodges == self._sampled_extra_dodges
	then
		return false
	end

	self._sample_valid = true
	self._sampled_dodges = consecutive_dodges
	self._sampled_cooled_down = is_cooled_down
	self._sampled_is_dodging = is_dodging
	self._sampled_method = method
	self._sampled_slide = was_in_dodge_cooldown
	self._sampled_template = weapon_dodge_template
	self._sampled_extra_dodges = extra_consecutive_dodges

	return true
end

HudElementDodgeCount._count_text = function(self, current_dodges, num_efficient_dodges)
	if num_efficient_dodges == math_huge then
		if mod.setting("show_dodge_count_for_infinite_dodge") then
			return tostring(current_dodges)
		end

		return ""
	end

	local display_dodges = mod.setting("dodges_count_up") and current_dodges
		or (math_ceil(num_efficient_dodges) - current_dodges)

	if mod.setting("show_efficient_dodges") then
		return string_format("%d/%d", display_dodges, math_ceil(num_efficient_dodges))
	end

	return tostring(math_ceil(display_dodges))
end

HudElementDodgeCount.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementDodgeCount.super.update(self, dt, t, ui_renderer, render_settings, input_service)

	if mod._dodge_hud_dirty then
		mod._dodge_hud_dirty = false
		self:_refresh_offsets()
	end

	local show_dodge_count = mod.setting("dodge_count")
	local show_dodge_timer = mod.setting("dodge_timer")
	local show_debug = mod.setting("debug_dodge_count")

	if self._is_in_hub or not (show_dodge_count or show_dodge_timer or show_debug) then
		self:_clear()
		return
	end

	if not self:_resolve_player() then
		self:_clear()
		return
	end

	local widgets_by_name = self._widgets_by_name
	local dodge_state_component = self._dodge_state_component
	local movement_state_component = self._movement_state_component
	local slide_state_component = self._slide_state_component
	local weapon_dodge_template = self._weapon_extension:dodge_template()
	local stat_buffs = self._buff_extension:stat_buffs()
	local extra_consecutive_dodges = math_round(stat_buffs.extra_consecutive_dodges or 0)
	local gameplay_t = Managers.time:time("gameplay")
	local consecutive_dodges_cooldown = dodge_state_component.consecutive_dodges_cooldown

	local changed = self:_sample_changed(
		dodge_state_component.consecutive_dodges,
		consecutive_dodges_cooldown < gameplay_t,
		movement_state_component.is_dodging,
		movement_state_component.method,
		slide_state_component.was_in_dodge_cooldown,
		weapon_dodge_template,
		extra_consecutive_dodges
	)

	if changed then
		local current_dodges, num_efficient_dodges, dr_limit, distance_modifier =
			_calculate_dodge_diminishing_return(
				dodge_state_component,
				movement_state_component,
				slide_state_component,
				weapon_dodge_template,
				extra_consecutive_dodges,
				gameplay_t
			)

		self._current_dodges = current_dodges
		self._num_efficient_dodges = num_efficient_dodges
		self._dr_limit = dr_limit
		self._distance_modifier = distance_modifier
		self._displayed_count_text = show_dodge_count and self:_count_text(current_dodges, num_efficient_dodges)
			or ""
	end

	local current_dodges = self._current_dodges
	local num_efficient_dodges = self._num_efficient_dodges
	local dr_limit = self._dr_limit

	local base_dodge_template = self._base_dodge_template

	if show_dodge_timer and base_dodge_template then
		local weapon_consecutive_dodges_reset = weapon_dodge_template
				and weapon_dodge_template.consecutive_dodges_reset
			or 0
		local buff_modifier = stat_buffs.dodge_cooldown_reset_modifier
		local buff_dodge_cooldown_reset_modifier = buff_modifier and 1 - (buff_modifier - 1) or 1
		local relative_cooldown = (base_dodge_template.consecutive_dodges_reset + weapon_consecutive_dodges_reset)
			* buff_dodge_cooldown_reset_modifier

		local is_actually_dodging = (movement_state_component.method ~= "vaulting")
			and movement_state_component.is_dodging
		local relative_time = gameplay_t - consecutive_dodges_cooldown
		local force_show_max_width = current_dodges ~= 0
			and (is_actually_dodging or movement_state_component.method == "sliding")
		local size, color = timer_size_color(relative_time, relative_cooldown, current_dodges, force_show_max_width)

		widgets_by_name.dodge_timer.style.timer.size = size or ZERO_SIZE
		widgets_by_name.dodge_timer.style.timer.color = color or color_timer_hidden
	else
		widgets_by_name.dodge_timer.style.timer.size = ZERO_SIZE
	end

	if show_dodge_count then
		local text_color = widgets_by_name.dodge_count.style.text.text_color
		_copy_color(text_color, color_efficient)

		_set_text(widgets_by_name.dodge_count, self._displayed_count_text)

		if current_dodges >= num_efficient_dodges then
			_copy_color(text_color, color_inefficient)
		end

		if current_dodges >= math_floor(dr_limit + num_efficient_dodges) then
			_copy_color(text_color, color_limit)
		end

		if mod.setting("fade_out_max_dodges") and current_dodges == 0 then
			local time_since_cooldown = math_clamp(gameplay_t - consecutive_dodges_cooldown - 1, 0, 1)
			text_color[1] = math_lerp(255, 0, time_since_cooldown)
		end
	else
		_set_text(widgets_by_name.dodge_count, "")
	end

	if show_debug then
		local cooldown = consecutive_dodges_cooldown - gameplay_t

		_set_text(
			widgets_by_name.debug_dodge_count,
			string_format(
				"%d/%s/%s\nmodifier: x%.2f\ncooldown: %.2fs\ndodging: %s\nsliding: %s",
				current_dodges,
				num_efficient_dodges == math_huge and "inf"
					or tostring(math_round_with_precision(num_efficient_dodges, 2)),
				num_efficient_dodges == math_huge and "inf"
					or tostring(math_floor(dr_limit + num_efficient_dodges)),
				self._distance_modifier,
				cooldown > 0 and cooldown or 0,
				tostring(movement_state_component.is_dodging),
				tostring(movement_state_component.method == "sliding")
			)
		)
	else
		_set_text(widgets_by_name.debug_dodge_count, "")
	end
end

return HudElementDodgeCount
