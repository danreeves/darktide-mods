local mod = get_mod("NumericUI")
local TEAM_HUD_DEF_PATH = "scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions"
local Ammo = require("scripts/utilities/ammo")

local backups = mod:persistent_table("team_hud_backups")
backups.team_hud_definitions = backups.team_hud_definitions or mod:original_require(TEAM_HUD_DEF_PATH)

local UIWidget = require("scripts/managers/ui/ui_widget")
local HudElementTeamPlayerPanelSettings =
	require("scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_settings")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local math_clamp = math.clamp
local math_floor = math.floor
local math_min = math.min
local math_round = math.round
local string_format = string.format
local table_clone = table.clone
local table_merge_recursive = table.merge_recursive

local bar_size = HudElementTeamPlayerPanelSettings.size
local hud_body_font_setting_name = "hud_body"
local hud_body_font_settings = UIFontSettings[hud_body_font_setting_name]

local health_text_style = {
	horizontal_alignment = "left",
	font_size = 16,
	text_vertical_alignment = "center",
	text_horizontal_alignment = "right",
	vertical_alignment = "center",
	drop_shadow = true,
	font_type = "machine_medium",
	text_color = UIHudSettings.color_tint_main_2,
	offset = { 0, -2, 2 },
}

local tough_text_style = {
	horizontal_alignment = "left",
	font_size = 16,
	text_vertical_alignment = "center",
	text_horizontal_alignment = "right",
	vertical_alignment = "center",
	drop_shadow = true,
	font_type = "machine_medium",
	text_color = UIHudSettings.color_tint_main_2,
	offset = { 0, -6, 2 },
}

local ability_bar_cooldown_color = Color.terminal_background_gradient_selected(255, true)
local ABILITY_TYPE = "combat_ability"

-- the ability bar is split into one segment per charge, spaced like vanilla's health bar wound segments and
-- budgeted like them: vanilla pre-creates 10 wound segments. Mortis Trials' Empowered perk alone takes a
-- 5 charge Skitarius to 7
local ABILITY_BAR_MAX_SEGMENTS = 10
local ABILITY_BAR_SEGMENT_SPACING = 4

-- segment style ids built once instead of every frame
local ability_bar_segment_ids = {}
local ability_bar_segment_background_ids = {}

for i = 1, ABILITY_BAR_MAX_SEGMENTS do
	ability_bar_segment_ids[i] = "segment_" .. i
	ability_bar_segment_background_ids[i] = "segment_background_" .. i
end

local AMMO_UPDATE_INTERVAL = 0.1

mod:hook_require(TEAM_HUD_DEF_PATH, function(instance)
	if mod.setting("health_text") or mod.setting("toughness_text") then
		instance.widget_definitions.coherency_indicator = UIWidget.create_definition({
			{
				value = "content/ui/materials/hud/icons/party_cohesion",
				style_id = "texture",
				pass_type = "texture",
				style = {
					vertical_alignment = "bottom",
					horizontal_alignment = "right",
					size = { 24, 24 },
					offset = { 54, 0, 8 },
					color = UIHudSettings.color_tint_main_1,
				},
			},
		}, "bar")
	else
		instance.widget_definitions.coherency_indicator =
			backups.team_hud_definitions.widget_definitions.coherency_indicator
	end

	if mod.setting("ability_cd_text") then
		instance.widget_definitions.ability_text = UIWidget.create_definition({
			{
				value_id = "text",
				style_id = "text",
				pass_type = "text",
				value = "",
				style = table_merge_recursive(table_clone(tough_text_style), {
					text_color = UIHudSettings.color_tint_secondary_1,
					default_color = UIHudSettings.color_tint_secondary_1,
					dimmed_color = UIHudSettings.color_tint_secondary_3,
					offset = { 28, 22 },
					character_spacing = 0.05,
				}),
			},
		}, "toughness_bar")
	else
		instance.widget_definitions.ability_text = nil
	end

	if mod.setting("ability_cd_bar") then
		local ability_bar_passes = {}

		-- one fill and one background pass per segment; unused segments are hidden when laid out
		for i = 1, ABILITY_BAR_MAX_SEGMENTS do
			ability_bar_passes[i * 2 - 1] = {
				value = "content/ui/materials/backgrounds/default_square",
				style_id = ability_bar_segment_ids[i],
				pass_type = "texture",
				style = {
					vertical_alignment = "center",
					horizontal_alignment = "left",
					offset = { 0, 20, 4 },
					size = { bar_size[1], 3 },
					color = UIHudSettings.color_tint_secondary_1,
					visible = i == 1,
				},
			}
			ability_bar_passes[i * 2] = {
				value = "content/ui/materials/backgrounds/default_square",
				style_id = ability_bar_segment_background_ids[i],
				pass_type = "texture",
				style = {
					vertical_alignment = "center",
					horizontal_alignment = "left",
					offset = { 0, 20, 0 },
					size = { bar_size[1], 2 },
					color = UIHudSettings.color_tint_0,
					visible = i == 1,
				},
			}
		end

		instance.widget_definitions.ability_bar = UIWidget.create_definition(ability_bar_passes, "toughness_bar")
	else
		instance.widget_definitions.ability_bar = nil
	end

	if mod.setting("ammo_text") or mod.setting("peril_icon") then
		instance.widget_definitions.numeric_ui_peril_icon = UIWidget.create_definition({
			{
				value_id = "icon_text",
				style_id = "icon_text",
				pass_type = "text",
				value = "",
				visible = false,
				style = {
					font_size = 18,
					text_vertical_alignment = "center",
					text_horizontal_alignment = "right",
					vertical_alignment = "top",
					horizontal_alignment = "left",
					offset = { 0, -22, 3 },
					size = { bar_size[1], 18 },
					font_type = "machine_medium",
					text_color = UIHudSettings.color_tint_alert_2,
					default_text_color = UIHudSettings.color_tint_main_2,
				},
			},
		}, "toughness_bar")
	else
		instance.widget_definitions.numeric_ui_peril_icon = nil
	end

	if mod.setting("ammo_text") then
		instance.widget_definitions.numeric_ui_ammo_text = UIWidget.create_definition({
			{
				value_id = "text",
				style_id = "text",
				pass_type = "text",
				value = "<ammo_count>",
				style = {
					default_font_size = 16,
					font_size = 16,
					text_vertical_alignment = "center",
					text_horizontal_alignment = "left",
					vertical_alignment = "center",
					offset = { 80, -16, 3 },
					size = { bar_size[1] * 1.5, bar_size[2] },
					font_type = hud_body_font_settings.font_type,
					text_color = UIHudSettings.color_tint_main_2,
					default_text_color = UIHudSettings.color_tint_main_2,
				},
			},
		}, "toughness_bar")
	else
		instance.widget_definitions.numeric_ui_ammo_text = nil
	end

	if mod.setting("health_text") then
		instance.widget_definitions.health_text = UIWidget.create_definition({
			{
				value_id = "text_3",
				style_id = "text_3",
				pass_type = "text",
				value = "0",
				style = table_merge_recursive(table_clone(health_text_style), {
					index = 3,
					text_color = UIHudSettings.color_tint_main_1,
					default_color = UIHudSettings.color_tint_main_1,
					dimmed_color = UIHudSettings.color_tint_main_3,
					offset = { 28 },
				}),
			},
			{
				value_id = "text_2",
				style_id = "text_2",
				pass_type = "text",
				value = "0",
				style = table_merge_recursive(table_clone(health_text_style), {
					index = 2,
					text_color = UIHudSettings.color_tint_main_1,
					default_color = UIHudSettings.color_tint_main_1,
					dimmed_color = UIHudSettings.color_tint_main_3,
					offset = { 20 },
				}),
			},
			{
				value_id = "text_1",
				style_id = "text_1",
				pass_type = "text",
				value = "0",
				style = table_merge_recursive(table_clone(health_text_style), {
					index = 1,
					text_color = UIHudSettings.color_tint_main_1,
					default_color = UIHudSettings.color_tint_main_1,
					dimmed_color = UIHudSettings.color_tint_main_3,
					offset = { 12 },
				}),
			},
		}, "bar")
	else
		instance.widget_definitions.health_text = nil
	end

	if mod.setting("toughness_text") then
		instance.widget_definitions.toughness_text = UIWidget.create_definition({
			{
				value_id = "text_3",
				style_id = "text_3",
				pass_type = "text",
				value = "0",
				style = table_merge_recursive(table_clone(tough_text_style), {
					index = 3,
					text_color = UIHudSettings.color_tint_6,
					default_color = UIHudSettings.color_tint_6,
					dimmed_color = UIHudSettings.color_tint_7,
					offset = { 28 },
				}),
			},
			{
				value_id = "text_2",
				style_id = "text_2",
				pass_type = "text",
				value = "0",
				style = table_merge_recursive(table_clone(tough_text_style), {
					index = 2,
					text_color = UIHudSettings.color_tint_6,
					default_color = UIHudSettings.color_tint_6,
					dimmed_color = UIHudSettings.color_tint_7,
					offset = { 20 },
				}),
			},
			{
				value_id = "text_1",
				style_id = "text_1",
				pass_type = "text",
				value = "0",
				style = table_merge_recursive(table_clone(tough_text_style), {
					index = 1,
					text_color = UIHudSettings.color_tint_6,
					default_color = UIHudSettings.color_tint_6,
					dimmed_color = UIHudSettings.color_tint_7,
					offset = { 12 },
				}),
			},
		}, "toughness_bar")
	else
		instance.widget_definitions.toughness_text = nil
	end
end)

local function hide_numericui_ability_cd(ability_bar_widget, ability_text_widget, show_ability_text, show_ability_bar)
	if show_ability_text then
		ability_text_widget.dirty = ability_text_widget.visible
		ability_text_widget.visible = false
	end

	if show_ability_bar then
		ability_bar_widget.dirty = ability_bar_widget.visible
		ability_bar_widget.visible = false
	end
end

local function layout_numericui_ability_bar(ability_bar_widget, num_segments)
	local style = ability_bar_widget.style
	local segment_width = (bar_size[1] - (num_segments - 1) * ABILITY_BAR_SEGMENT_SPACING) / num_segments

	for i = 1, ABILITY_BAR_MAX_SEGMENTS do
		local segment_style = style[ability_bar_segment_ids[i]]
		local background_style = style[ability_bar_segment_background_ids[i]]
		local visible = i <= num_segments
		local x = (i - 1) * (segment_width + ABILITY_BAR_SEGMENT_SPACING)

		segment_style.visible = visible
		segment_style.offset[1] = x
		background_style.visible = visible
		background_style.offset[1] = x
		background_style.size[1] = segment_width
	end

	local content = ability_bar_widget.content

	content._numericui_num_segments = num_segments
	content._numericui_segment_width = segment_width
	ability_bar_widget.dirty = true
end

local function update_numericui_ability_bar(ability_bar_widget, max_charges, remaining_charges, charge_progress)
	-- more charges than segments collapse to a single bar that reads ready while any charge is left
	local num_segments = (max_charges >= 1 and max_charges <= ABILITY_BAR_MAX_SEGMENTS) and max_charges or 1
	local content = ability_bar_widget.content

	if content._numericui_num_segments ~= num_segments then
		layout_numericui_ability_bar(ability_bar_widget, num_segments)
	end

	local style = ability_bar_widget.style
	local segment_width = content._numericui_segment_width
	local charged_segments = math_min(remaining_charges, num_segments)

	for i = 1, num_segments do
		local segment_style = style[ability_bar_segment_ids[i]]
		local width = 0
		local color = ability_bar_cooldown_color

		if i <= charged_segments then
			width = segment_width
			color = UIHudSettings.color_tint_secondary_1
		elseif i == charged_segments + 1 then
			-- quantize to whole pixels so the retained bar only re-renders when it visibly grows
			width = math_floor(segment_width * charge_progress + 0.5)
		end

		local segment_size = segment_style.size

		if segment_size[1] ~= width or segment_style.color ~= color then
			segment_size[1] = width
			segment_style.color = color
			ability_bar_widget.dirty = true
		end
	end
end

local function update_numericui_ability_cd(self, ability_extension, ability_bar_widget, ability_text_widget)
	local hide_widgets = (self._show_as_dead or self._dead or self._hogtied)
	local show_ability_text = (mod.setting("ability_cd_text") and ability_text_widget)
	local show_ability_bar = (mod.setting("ability_cd_bar") and ability_bar_widget)

	-- the personal panel has no cooldown widgets, so there is nothing to update
	if not show_ability_text and not show_ability_bar then
		return
	end

	if hide_widgets then
		hide_numericui_ability_cd(ability_bar_widget, ability_text_widget, show_ability_text, show_ability_bar)

		return
	end

	-- Darktide 1.13.0 regenerates abilities as a resource instead of counting down a cooldown
	local regen_progress_func = ability_extension.get_ability_resource_regen_progress
	local max_regen_time_func = ability_extension.max_regen_time_for_ability_charge

	if not regen_progress_func or not max_regen_time_func then
		hide_numericui_ability_cd(ability_bar_widget, ability_text_widget, show_ability_text, show_ability_bar)

		return
	end

	local remaining_charges = ability_extension:remaining_ability_charges(ABILITY_TYPE)
	local max_charges = ability_extension:max_ability_charges(ABILITY_TYPE)
	local is_regenerating = remaining_charges < max_charges
	-- progress of the charge being regenerated, which only exists while a charge is missing
	local regen_progress = 1

	if is_regenerating then
		regen_progress = math_clamp(regen_progress_func(ability_extension, ABILITY_TYPE) or 0, 0, 1)
	end

	if show_ability_text then
		-- counts down to the next charge, even while the teammate still has one available
		if not is_regenerating then
			if ability_text_widget.visible then
				ability_text_widget.visible = false
				ability_text_widget.content._numericui_last_value = nil
				ability_text_widget.dirty = true
			end
		else
			local content = ability_text_widget.content
			-- the base-rate charge time is the only regen timing synced for teammates, so under regen
			-- buffs this counts down faster than the clock, but it always reaches zero as the bar fills
			local time_remaining = (1 - regen_progress) * (max_regen_time_func(ability_extension, ABILITY_TYPE) or 0)
			local display_value = math_floor(time_remaining)
			local text_style = ability_text_widget.style.text
			-- dimmed while the teammate still has a charge available, full brightness once they have none
			local text_color = remaining_charges > 0 and text_style.dimmed_color or text_style.default_color

			if not ability_text_widget.visible then
				ability_text_widget.visible = true
				ability_text_widget.dirty = true
			end

			if text_style.text_color ~= text_color then
				text_style.text_color = text_color
				ability_text_widget.dirty = true
			end

			-- only re-render the text when the displayed value changes
			if content._numericui_last_value ~= display_value then
				content._numericui_last_value = display_value

				local text = string_format("%03d", time_remaining)

				if content.text ~= text then
					content.text = text
					ability_text_widget.dirty = true
				end
			end
		end
	end

	if show_ability_bar then
		-- matches vanilla's ability HUD, which shows paused regen as an empty bar
		local charge_progress = regen_progress

		if is_regenerating and ability_extension:is_ability_resource_regen_paused(ABILITY_TYPE) then
			charge_progress = 0
		end

		if not ability_bar_widget.visible then
			ability_bar_widget.visible = true
			ability_bar_widget.dirty = true
		end

		update_numericui_ability_bar(ability_bar_widget, max_charges, remaining_charges, charge_progress)
	end
end

mod:hook_safe("HudElementPlayerPanelBase", "destroy", function(self)
	if mod.setting("ability_cd_text") then
		local ability_text_widget = self._widgets_by_name.ability_text

		if ability_text_widget then
			ability_text_widget.visible = false
			ability_text_widget.dirty = true
		end
	end

	if mod.setting("ability_cd_bar") then
		local ability_bar_widget = self._widgets_by_name.ability_bar

		if ability_bar_widget then
			ability_bar_widget.visible = false
			ability_bar_widget.dirty = true
		end
	end
end)

local function update_numericui_ammo(self, unit_data_extension, ammo_text_widget, peril_icon_widget)
	local peril_color = nil
	local warp_charge_level = nil

	if peril_icon_widget and peril_icon_widget.visible then
		local warp_charge_component = unit_data_extension:read_component("warp_charge")
		warp_charge_level = warp_charge_component.current_percentage

		if warp_charge_level > 0.98 then
			peril_color = UIHudSettings.color_tint_ammo_high
		elseif warp_charge_level > 0.75 then
			peril_color = UIHudSettings.color_tint_ammo_medium
		elseif warp_charge_level > 0.5 then
			peril_color = UIHudSettings.color_tint_ammo_low
		else
			peril_color = peril_icon_widget.style.icon_text.default_text_color
		end

		if mod.setting("peril_icon") and peril_color ~= peril_icon_widget.style.icon_text.text_color then
			peril_icon_widget.style.icon_text.text_color = peril_color
			peril_icon_widget.dirty = true
		end
	end

	local weapon_slots = self._weapon_slots
	local total_current_ammo = 0
	local total_max_ammo = 0

	for i = 1, #weapon_slots do
		local slot_id = weapon_slots[i]
		local inventory_component = unit_data_extension:read_component(slot_id)

		if inventory_component then
			local max_clip = Ammo.max_ammo_in_clips(inventory_component) or 0
			local max_reserve = Ammo.max_ammo_in_reserve(inventory_component) or 0
			local current_clip = Ammo.current_ammo_in_clips(inventory_component) or 0
			local current_reserve = Ammo.current_ammo_in_reserve(inventory_component) or 0
			total_current_ammo = total_current_ammo + current_clip + current_reserve
			total_max_ammo = total_max_ammo + max_clip + max_reserve
		end
	end

	local show_as_empty = total_max_ammo == 0 or self._show_as_dead or self._dead or self._hogtied

	-- only re-render the retained widget when the displayed values change
	if
		total_current_ammo ~= self._numericui_ammo_current
		or total_max_ammo ~= self._numericui_ammo_max
		or show_as_empty ~= self._numericui_ammo_empty
	then
		self._numericui_ammo_current = total_current_ammo
		self._numericui_ammo_max = total_max_ammo
		self._numericui_ammo_empty = show_as_empty

		if show_as_empty then
			-- No ammo or dead
			ammo_text_widget.content.text = ""
		elseif total_max_ammo == 0 and (peril_icon_widget and peril_icon_widget.visible) and mod.setting("peril_text") then
			-- Ammo text as peril percent
			ammo_text_widget.content.text = string_format("%1d%%", math_round(warp_charge_level * 100))
			ammo_text_widget.style.text.text_color = peril_color
		else
			-- Ammo
			if mod.setting("ammo_as_percent") then
				ammo_text_widget.content.text = string_format("%1d%%", (total_current_ammo / total_max_ammo) * 100)
			else
				ammo_text_widget.content.text = string_format("%1d/%1d", total_current_ammo, total_max_ammo)
			end
			ammo_text_widget.style.text.text_color = self._widgets_by_name.ammo_status.style.ammo.color
		end
		ammo_text_widget.dirty = true
	end
end

local function update_numericui_player_features(func, self, dt, t, player, ui_renderer)
	func(self, dt, t, player, ui_renderer)

	local ammo_text_widget = self._widgets_by_name.numeric_ui_ammo_text
	local peril_icon_widget = self._widgets_by_name.numeric_ui_peril_icon
	local extensions = self:_player_extensions(player)
	local unit_data_extension = extensions and extensions.unit_data

	if ammo_text_widget and unit_data_extension then
		local elapsed = (self._numericui_ammo_t or AMMO_UPDATE_INTERVAL) + dt

		if elapsed >= AMMO_UPDATE_INTERVAL then
			self._numericui_ammo_t = 0
			update_numericui_ammo(self, unit_data_extension, ammo_text_widget, peril_icon_widget)
		else
			self._numericui_ammo_t = elapsed
		end
	end

	local ability_extension = extensions and extensions.ability

	if ability_extension and (mod.setting("ability_cd_text") or mod.setting("ability_cd_bar")) then
		update_numericui_ability_cd(
			self,
			ability_extension,
			self._widgets_by_name.ability_bar,
			self._widgets_by_name.ability_text
		)
	end
end

mod:hook("HudElementPersonalPlayerPanel", "_update_player_features", update_numericui_player_features)
mod:hook("HudElementTeamPlayerPanel", "_update_player_features", update_numericui_player_features)

mod:hook("HudElementTeamPlayerPanel", "init", function(func, self, _parent, _draw_layer, _start_scale, data)
	HudElementTeamPlayerPanelSettings.feature_list.health_text = mod.setting("health_text")
	HudElementTeamPlayerPanelSettings.feature_list.toughness_text = mod.setting("toughness_text")
	HudElementTeamPlayerPanelSettings.feature_list.level = mod.setting("level")

	func(self, _parent, _draw_layer, _start_scale, data)

	local player_extensions = self:_player_extensions(data.player)

	if player_extensions then
		local unit_data_extension = player_extensions.unit_data
		if unit_data_extension then
			local archetype = unit_data_extension:archetype_name()
			local peril_icon_widget = self._widgets_by_name.numeric_ui_peril_icon

			if mod.setting("peril_icon") then
				peril_icon_widget.content.icon_text = "" -- this boxed questionmark is the character for the peril icon
				peril_icon_widget.visible = (archetype == "psyker")
			elseif mod.setting("ammo_text") then
				peril_icon_widget.content.icon_text = ""
				peril_icon_widget.visible = (archetype == "psyker") -- I use the "visible" flag to determine if it's a psyker
			end
		end
	end
end)
