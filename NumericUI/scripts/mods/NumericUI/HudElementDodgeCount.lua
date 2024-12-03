local mod = get_mod("NumericUI")

local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

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
			style = style,
		} },
		"container"
	),

	debug_dodge_count = UIWidget.create_definition({
		{
			value_id = "text",
			pass_type = "text",
			style = table.merge_recursive(style, {
				offset = { 0, 30 },
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

	local player_manager = Managers.player
	local player = player_manager:local_player(1)
	local player_unit = player.player_unit
	self._player_unit = player_unit
	self._is_in_hub = mod._is_in_hub()
end

local function _calculate_dodge_diminishing_return(
	dodge_character_state_component,
	movement_state_component,
	slide_state_component,
	weapon_dodge_template,
	buff_extension,
	t
)
	local stat_buffs = buff_extension:stat_buffs()
	local extra_consecutive_dodges = math.round(stat_buffs.extra_consecutive_dodges or 0)
	local dr_start = (weapon_dodge_template and weapon_dodge_template.diminishing_return_start or 2)
		+ extra_consecutive_dodges
	local dr_limit = dr_start + (weapon_dodge_template and weapon_dodge_template.diminishing_return_limit or 1)

	local consecutive_dodges = math.min(dodge_character_state_component.consecutive_dodges, dr_limit + dr_start)

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
		+ dr_distance_modifier * (1 - math.clamp(consecutive_dodges - dr_start, 0, dr_limit) / dr_limit)

	return consecutive_dodges, dr_start, dr_limit, diminishing_return
end

HudElementDodgeCount.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementDodgeCount.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	-- Reset to empty in case we can't fill it in
	self._widgets_by_name.dodge_count.content.text = ""
	self._widgets_by_name.debug_dodge_count.content.text = ""

	if self._is_in_hub or not mod:get("dodge_count") then
		return
	end

	local style = self._widgets_by_name.dodge_count.style
	style.text.text_color = table.clone(color_efficient)

	local unit_data_extension = ScriptUnit.extension(self._player_unit, "unit_data_system")
	local weapon_extension = ScriptUnit.has_extension(self._player_unit, "weapon_system")
	local buff_extension = ScriptUnit.extension(self._player_unit, "buff_system")
	if unit_data_extension and weapon_extension and buff_extension then
		local dodge_state_component = unit_data_extension:read_component("dodge_character_state")
		local movement_state_component = unit_data_extension:read_component("movement_state")
		local slide_state_component = unit_data_extension:read_component("slide_character_state")
		local weapon_dodge_template = weapon_extension:dodge_template()
		local gameplay_t = Managers.time:time("gameplay")
		local cooldown = dodge_state_component.consecutive_dodges_cooldown - gameplay_t

		local current_dodges, num_efficient_dodges, dr_limit, distance_modifier = _calculate_dodge_diminishing_return(
			dodge_state_component,
			movement_state_component,
			slide_state_component,
			weapon_dodge_template,
			buff_extension,
			gameplay_t
		)

		if num_efficient_dodges == math.huge then
			if mod:get("show_dodge_count_for_infinite_dodge") then
				self._widgets_by_name.dodge_count.content.text = tostring(current_dodges)
			end
		else
			local display_dodges = mod:get("dodges_count_up") and current_dodges
				or (math.ceil(num_efficient_dodges) - current_dodges)

			if mod:get("show_efficient_dodges") then
				self._widgets_by_name.dodge_count.content.text = string.format(
					"%d/%d",
					display_dodges,
					math.ceil(num_efficient_dodges)
				)
			else
				self._widgets_by_name.dodge_count.content.text = tostring(math.ceil(display_dodges))
			end
		end

		if current_dodges >= num_efficient_dodges then
			style.text.text_color = table.clone(color_inefficient)
		end

		if current_dodges >= math.floor(dr_limit + num_efficient_dodges) then
			style.text.text_color = table.clone(color_limit)
		end

		if mod:get("fade_out_max_dodges") and current_dodges == 0 then
			local time_since_cooldown = math.clamp(
				gameplay_t - dodge_state_component.consecutive_dodges_cooldown - 1,
				0,
				1
			)
			style.text.text_color[1] = math.lerp(255, 0, time_since_cooldown)
		end

		if mod:get("debug_dodge_count") then
			self._widgets_by_name.debug_dodge_count.content.text = string.format(
				"%d/%s/%s\nmodifier: x%.2f\ncooldown: %.2fs\ndodging: %s\nsliding: %s",
				current_dodges,
				num_efficient_dodges == math.huge and "inf"
					or tostring(math.round_with_precision(num_efficient_dodges, 2)),
				num_efficient_dodges == math.huge and "inf" or tostring(math.floor(dr_limit + num_efficient_dodges)),
				distance_modifier,
				cooldown > 0 and cooldown or 0,
				tostring(movement_state_component.is_dodging),
				tostring(movement_state_component.method == "sliding")
			)
		end
	end
end

return HudElementDodgeCount
