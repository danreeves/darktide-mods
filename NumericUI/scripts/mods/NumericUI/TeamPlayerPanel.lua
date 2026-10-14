local mod = get_mod("NumericUI")
local TEAM_HUD_DEF_PATH = "scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions"
local Ammo = require("scripts/utilities/ammo")
local MasterItems = require("scripts/backend/master_items")

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

-- shared with the peril percent, which takes this slot for a Psyker with no ammo text to show
local ammo_text_style = {
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

-- U+E021, the peril skull in Darktide's private-use glyph range, escaped so editors can't strip it again
local PERIL_ICON = "\238\128\161"

-- while the ammo text shows a gun's ammo, a smaller percent sits above the skull's column at the end of the bar,
-- over a smaller skull, so neither runs into the ammo text on the same line. Text wraps to its box, so the
-- percent gets a box wide enough for "100%", centred on the column
local PERIL_STACK_WIDTH = 20
local PERIL_STACK_TEXT_WIDTH = 60
local PERIL_STACK_LINE_HEIGHT = 12
local PERIL_STACK_TEXT_Y = -26
local PERIL_STACK_ICON_Y = -14
local PERIL_STACK_TEXT_FONT_SIZE = 12
local PERIL_STACK_ICON_FONT_SIZE = 14

local GRENADE_ABILITY_TYPE = "grenade_ability"
local GRENADE_SLOT_NAME = "slot_grenade_ability"
local BLITZ_ICON_PACKAGE_REFERENCE = "NumericUI_team_blitz_icon"
-- the team panel definitions' own Blitz icon, loaded with the team panel's package
local THROWABLE_DEFAULT_ICON = "content/ui/materials/hud/icons/party_throwable"

-- the Blitz charge count sits in the bottom-right corner of vanilla's 16px Blitz icon. It is right-aligned to end
-- in the gap before the ammo icon, so a two-digit count (Assail, throwing knives) grows over the Blitz icon instead
local BLITZ_CHARGES_RIGHT_X = 20
local BLITZ_CHARGES_WIDTH = 24

-- The count sits on the icon's strokes, and the engine's text only has a single drop shadow, so a dark copy is drawn
-- 1px off in each of the eight directions behind it, outlining every digit. A detailed Blitz icon gets the same outline
local OUTLINE_OFFSETS = {
	{ -1, -1 },
	{ 0, -1 },
	{ 1, -1 },
	{ -1, 0 },
	{ 1, 0 },
	{ -1, 1 },
	{ 0, 1 },
	{ 1, 1 },
}
local BLITZ_CHARGES_OUTLINE_COLOR = { 120, 0, 0, 0 }
local BLITZ_ICON_OUTLINE_COLOR = { 120, 0, 0, 0 }
-- Detailed icons are drawn for the weapon HUD's 84px slot and lose fine detail at vanilla's 16px, like the burst inside
-- the frag grenade, so they're drawn a little bigger, centred on vanilla's icon. Vanilla's own icons keep their size
local BLITZ_ICON_DETAILED_SIZE = 20
-- a two-digit count ends where vanilla's ammo icon starts, and the ammo icon has room before the pickup icons
local BLITZ_CHARGES_AMMO_ICON_SHIFT = 3

-- NumericUI's team panel numbers that vanilla's _set_dead doesn't hide. The ability cooldown widgets hide
-- themselves in update_numericui_ability_cd
local COMBAT_WIDGET_NAMES = { "health_text", "toughness_text", "numeric_ui_ammo_text", "numeric_ui_peril_icon" }

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

	if mod.setting("peril_text") or mod.setting("peril_icon") then
		local peril_icon_style = {
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
		}
		local column_x = bar_size[1] - PERIL_STACK_WIDTH
		local peril_icon_stacked_style = table_merge_recursive(table_clone(peril_icon_style), {
			font_size = PERIL_STACK_ICON_FONT_SIZE,
			text_horizontal_alignment = "center",
			offset = { column_x, PERIL_STACK_ICON_Y },
			size = { PERIL_STACK_WIDTH, PERIL_STACK_LINE_HEIGHT },
		})
		local peril_text_style = {
			font_size = PERIL_STACK_TEXT_FONT_SIZE,
			text_vertical_alignment = "center",
			text_horizontal_alignment = "center",
			vertical_alignment = "top",
			horizontal_alignment = "left",
			offset = { column_x + (PERIL_STACK_WIDTH - PERIL_STACK_TEXT_WIDTH) / 2, PERIL_STACK_TEXT_Y, 3 },
			size = { PERIL_STACK_TEXT_WIDTH, PERIL_STACK_LINE_HEIGHT },
			font_type = hud_body_font_settings.font_type,
			text_color = UIHudSettings.color_tint_main_2,
		}

		-- the update fills in whichever passes match the current layout and leaves the others empty
		instance.widget_definitions.numeric_ui_peril_icon = UIWidget.create_definition({
			{
				value_id = "icon_text",
				style_id = "icon_text",
				pass_type = "text",
				value = "",
				visible = false,
				style = peril_icon_style,
			},
			{
				value_id = "icon_text_stacked",
				style_id = "icon_text_stacked",
				pass_type = "text",
				value = "",
				style = peril_icon_stacked_style,
			},
			{
				value_id = "peril_text",
				style_id = "peril_text",
				pass_type = "text",
				value = "",
				style = peril_text_style,
			},
			{
				value_id = "peril_ammo_slot_text",
				style_id = "peril_ammo_slot_text",
				pass_type = "text",
				value = "",
				style = table_clone(ammo_text_style),
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
				value = "",
				style = table_clone(ammo_text_style),
			},
		}, "toughness_bar")
	else
		instance.widget_definitions.numeric_ui_ammo_text = nil
	end

	if mod.setting("blitz_charges_text") then
		local text_style = {
			font_size = 11,
			text_vertical_alignment = "center",
			text_horizontal_alignment = "right",
			vertical_alignment = "top",
			horizontal_alignment = "left",
			offset = { BLITZ_CHARGES_RIGHT_X - BLITZ_CHARGES_WIDTH, -16, 5 },
			size = { BLITZ_CHARGES_WIDTH, 12 },
			font_type = hud_body_font_settings.font_type,
			text_color = UIHudSettings.color_tint_main_1,
		}
		local passes = {}

		-- every pass shows the same content.text
		for i = 1, #OUTLINE_OFFSETS do
			local outline_offset = OUTLINE_OFFSETS[i]

			passes[i] = {
				value_id = "text",
				style_id = "outline_" .. i,
				pass_type = "text",
				value = "",
				style = table_merge_recursive(table_clone(text_style), {
					offset = { text_style.offset[1] + outline_offset[1], text_style.offset[2] + outline_offset[2], 4 },
					text_color = BLITZ_CHARGES_OUTLINE_COLOR,
				}),
			}
		end

		passes[#passes + 1] = {
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			value = "",
			style = text_style,
		}

		instance.widget_definitions.numeric_ui_blitz_charges = UIWidget.create_definition(passes, "toughness_bar")
	else
		instance.widget_definitions.numeric_ui_blitz_charges = nil
	end

	if mod.setting("blitz_hud_icon") then
		-- dark copies of the Blitz icon around and below vanilla's, sized for the detailed icons they outline
		local icon_style = instance.widget_definitions.throwable.style.texture
		local icon_x, icon_y, icon_z = unpack(icon_style.offset)
		local grow_x = (BLITZ_ICON_DETAILED_SIZE - icon_style.size[1]) / 2
		local grow_y = (BLITZ_ICON_DETAILED_SIZE - icon_style.size[2]) / 2
		local passes = {}

		for i = 1, #OUTLINE_OFFSETS do
			local outline_offset = OUTLINE_OFFSETS[i]

			passes[i] = {
				value_id = "texture",
				style_id = "outline_" .. i,
				pass_type = "texture",
				value = THROWABLE_DEFAULT_ICON,
				style = {
					horizontal_alignment = icon_style.horizontal_alignment,
					vertical_alignment = icon_style.vertical_alignment,
					size = { BLITZ_ICON_DETAILED_SIZE, BLITZ_ICON_DETAILED_SIZE },
					offset = { icon_x - grow_x + outline_offset[1], icon_y - grow_y + outline_offset[2], icon_z - 1 },
					color = BLITZ_ICON_OUTLINE_COLOR,
				},
			}
		end

		instance.widget_definitions.numeric_ui_blitz_icon_outline = UIWidget.create_definition(passes, "toughness_bar")
	else
		instance.widget_definitions.numeric_ui_blitz_icon_outline = nil
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

-- Progress of the charge being regenerated. A teammate's copy of the ability extension prices a charge at the
-- template cost and ignores cost modifiers, while the synced max resource, resource and charge count include
-- them, so the cost per charge comes from the synced values. This equals vanilla's progress for local extensions.
local function ability_charge_regen_progress(ability_extension, regen_progress_func, max_charges, remaining_charges)
	local max_resource = ability_extension:max_ability_resource(ABILITY_TYPE)

	-- nothing synced yet
	if max_charges <= 0 or max_resource <= 0 then
		return math_clamp(regen_progress_func(ability_extension, ABILITY_TYPE) or 0, 0, 1)
	end

	local cost_per_charge = max_resource / max_charges
	local charge_resource = ability_extension:remaining_ability_resource(ABILITY_TYPE)
		- remaining_charges * cost_per_charge

	return math_clamp(charge_resource / cost_per_charge, 0, 1)
end

local function update_numericui_ability_cd(self, ability_extension, ability_bar_widget, ability_text_widget)
	local hide_widgets = (self._show_as_dead or self._dead or self._hogtied)
	local show_ability_text = (mod.setting("ability_cd_text") and ability_text_widget)
	local show_ability_bar = (mod.setting("ability_cd_bar") and ability_bar_widget)

	-- the personal panel has no cooldown widgets, so there is nothing to update
	if not show_ability_text and not show_ability_bar then
		return
	end

	-- a dead teammate has no unit, so no ability extension either
	if hide_widgets or not ability_extension then
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
		regen_progress =
			ability_charge_regen_progress(ability_extension, regen_progress_func, max_charges, remaining_charges)
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

local function update_numericui_peril(self, unit_data_extension, peril_icon_widget, total_max_ammo)
	local warp_charge_component = unit_data_extension:read_component("warp_charge")
	local warp_charge_level = warp_charge_component.current_percentage
	local peril_style = peril_icon_widget.style
	local show_icon = mod.setting("peril_icon")
	local peril_color = nil

	if warp_charge_level > 0.98 then
		peril_color = UIHudSettings.color_tint_ammo_high
	elseif warp_charge_level > 0.75 then
		peril_color = UIHudSettings.color_tint_ammo_medium
	elseif warp_charge_level > 0.5 then
		peril_color = UIHudSettings.color_tint_ammo_low
	else
		peril_color = peril_style.icon_text.default_text_color
	end

	if show_icon and peril_color ~= peril_style.icon_text.text_color then
		peril_style.icon_text.text_color = peril_color
		peril_style.icon_text_stacked.text_color = peril_color
		peril_icon_widget.dirty = true
	end

	if not mod.setting("peril_text") then
		return
	end

	local peril_content = peril_icon_widget.content
	local unavailable = self._show_as_dead or self._dead or self._hogtied
	local peril_percent = not unavailable and math_round(warp_charge_level * 100) or nil
	-- with no ammo text to show, the percent takes the ammo text's slot and the skull keeps its full size
	local in_ammo_slot = total_max_ammo == 0 or not mod.setting("ammo_text")

	-- only re-render the retained widget when the displayed percent or its place changes
	if
		peril_content._numericui_peril_percent ~= peril_percent
		or peril_content._numericui_peril_in_ammo_slot ~= in_ammo_slot
	then
		local text = peril_percent and string_format("%1d%%", peril_percent) or ""

		peril_content._numericui_peril_percent = peril_percent
		peril_content._numericui_peril_in_ammo_slot = in_ammo_slot
		peril_content.peril_ammo_slot_text = in_ammo_slot and text or ""
		-- without the skull, the ammo text carries the percent after a gun's ammo count instead
		peril_content.peril_text = (in_ammo_slot or not show_icon) and "" or text

		if show_icon then
			-- next to a gun's ammo text, the skull shrinks to stack under the percent
			peril_content.icon_text = in_ammo_slot and PERIL_ICON or ""
			peril_content.icon_text_stacked = in_ammo_slot and "" or PERIL_ICON
		end

		peril_icon_widget.dirty = true
	end

	-- checked on its own, as it steps on the unrounded peril and can change within one displayed percent
	if peril_color ~= peril_style.peril_text.text_color then
		peril_style.peril_text.text_color = peril_color
		peril_style.peril_ammo_slot_text.text_color = peril_color
		peril_icon_widget.dirty = true
	end

	if not in_ammo_slot and not show_icon then
		return peril_percent, peril_color
	end
end

local function update_numericui_ammo(self, unit_data_extension, ammo_text_widget, peril_icon_widget)
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

	-- the ammo totals also decide where the peril percent goes. It comes back when it follows the ammo count
	local peril_percent = nil
	local peril_color = nil

	if peril_icon_widget and peril_icon_widget.visible then
		peril_percent, peril_color = update_numericui_peril(self, unit_data_extension, peril_icon_widget, total_max_ammo)
	end

	if not ammo_text_widget then
		return
	end

	local show_as_empty = total_max_ammo == 0 or self._show_as_dead or self._dead or self._hogtied

	-- only re-render the retained widget when the displayed values change
	if
		total_current_ammo ~= self._numericui_ammo_current
		or total_max_ammo ~= self._numericui_ammo_max
		or show_as_empty ~= self._numericui_ammo_empty
		or peril_percent ~= self._numericui_ammo_peril_percent
		or peril_color ~= self._numericui_ammo_peril_color
	then
		self._numericui_ammo_current = total_current_ammo
		self._numericui_ammo_max = total_max_ammo
		self._numericui_ammo_empty = show_as_empty
		self._numericui_ammo_peril_percent = peril_percent
		self._numericui_ammo_peril_color = peril_color

		if show_as_empty then
			-- No ammo or dead
			ammo_text_widget.content.text = ""
		else
			-- Ammo
			local text = nil

			if mod.setting("ammo_as_percent") then
				text = string_format("%1d%%", (total_current_ammo / total_max_ammo) * 100)
			else
				text = string_format("%1d/%1d", total_current_ammo, total_max_ammo)
			end

			-- the peril percent follows in its own colour, on the same line and in the same font
			if peril_percent then
				text = string_format(
					"%s {#color(%d,%d,%d)}%1d%%{#reset()}",
					text,
					peril_color[2],
					peril_color[3],
					peril_color[4],
					peril_percent
				)
			end

			ammo_text_widget.content.text = text
			ammo_text_widget.style.text.text_color = self._widgets_by_name.ammo_status.style.ammo.color
		end
		ammo_text_widget.dirty = true
	end
end

-- an item's material fields that ItemPackage loads as packages named after their value
local ITEM_PACKAGE_MATERIAL_FIELDS = { "hud_icon", "icon", "icon_material", "material_resource" }

local function item_loads_material(item, material)
	for i = 1, #ITEM_PACKAGE_MATERIAL_FIELDS do
		if item[ITEM_PACKAGE_MATERIAL_FIELDS[i]] == material then
			return true
		end
	end

	return false
end

-- The weapon HUD's Blitz icon, and whether it has to be held. Mostly it's an item's hud_icon, which loads with the
-- teammate's loadout. Zealot knives, the Hive Scum flash grenade and the Skitarius force field put no item in the Blitz
-- slot, but their ability names one, which loads the same way. When that item doesn't carry the ability's icon (force
-- field), and for the Arbites whistle, which has no item at all, the icon can only come with the HUD's own packages,
-- which stay loaded as long as the HUD
local function blitz_hud_icon(extensions)
	local visual_loadout_extension = extensions.visual_loadout
	local item = visual_loadout_extension and visual_loadout_extension:item_from_slot(GRENADE_SLOT_NAME)
	local item_icon = item and item.hud_icon

	if item then
		if item_icon and item_icon ~= "" then
			return item_icon, true
		end

		return nil, false
	end

	local ability_extension = extensions.ability
	local ability = ability_extension and ability_extension:equipped_abilities()[GRENADE_ABILITY_TYPE]

	-- an item Blitz whose item hasn't synced yet only has a placeholder icon on its ability
	if not ability or ability.inventory_item_name then
		return nil, false
	end

	local icon = ability.hud_icon ~= "" and ability.hud_icon or nil
	local item_reference = ability.inventory_item_reference
	local referenced_item = item_reference
		and MasterItems.item_exists(item_reference)
		and MasterItems.get_item(item_reference)

	if referenced_item then
		local referenced_icon = referenced_item.hud_icon

		if referenced_icon and referenced_icon ~= "" then
			return referenced_icon, true
		end

		if icon and item_loads_material(referenced_item, icon) then
			return icon, true
		end
	end

	if icon and Application.can_get_resource("material", icon) then
		return icon, false
	end

	return nil, false
end

-- Package references on the item icons the team panels show, per HUD: hud -> icon -> load id. PackageSynchronizer
-- unloads a teammate's icons 3 seconds after they leave or a player takes over their bot, and the game crashes if the
-- HUD's renderer still references one then. Letting go when the panel was destroyed wasn't enough, the renderer could
-- still hold the icon. So an icon stays held until its HUD has destroyed its renderer
local held_blitz_icons = {}

local function hold_blitz_icon(hud, icon)
	local icons = held_blitz_icons[hud]

	if not icons then
		icons = {}
		held_blitz_icons[hud] = icons
	end

	local load_id = icons[icon]

	if not load_id then
		load_id = Managers.package:load(icon, BLITZ_ICON_PACKAGE_REFERENCE)
		icons[icon] = load_id
	end

	return load_id
end

-- runs after the HUD destroyed its elements and its renderer, so nothing can draw the icons any more
mod:hook_safe("UIHud", "destroy", function(self)
	local icons = held_blitz_icons[self]

	if not icons then
		return
	end

	held_blitz_icons[self] = nil

	for _, load_id in pairs(icons) do
		Managers.package:release(load_id)
	end
end)

-- vanilla only sets its icon here, when the Blitz's charge status, visibility or small icon changes
mod:hook(
	"HudElementTeamPlayerPanel",
	"_update_grenade_ability_presentation",
	function(func, self, status, visible, hud_icon, ui_renderer)
		local detailed_icon = nil
		local pending_icon, pending_load_id = nil, nil

		if mod.setting("blitz_hud_icon") then
			local extensions = self:_player_extensions(self._data.player)
			local icon, held = nil, false

			if extensions then
				icon, held = blitz_hud_icon(extensions)
			end

			if held then
				local load_id = hold_blitz_icon(self._parent, icon)

				if Managers.package:has_loaded_id(load_id) then
					detailed_icon = icon
				else
					pending_icon, pending_load_id = icon, load_id
				end
			else
				detailed_icon = icon
			end

			hud_icon = detailed_icon or hud_icon
		end

		func(self, status, visible, hud_icon, ui_renderer)

		self._numericui_blitz_detailed_icon = detailed_icon
		-- vanilla only sets its icon again on a change, so the outline update puts this one in once it has loaded
		self._numericui_blitz_pending_icon = pending_icon
		self._numericui_blitz_pending_load_id = pending_load_id
	end
)

-- Grows vanilla's icon to the detailed size around its centre, or puts it back. Every panel's style is its own copy
local function resize_numericui_blitz_icon(self, icon_widget, detailed)
	local style = icon_widget.style.texture
	local offset = style.offset
	local size = style.size
	local base = self._numericui_blitz_icon_base

	if not base then
		base = { offset[1], offset[2], size[1], size[2] }
		self._numericui_blitz_icon_base = base
	end

	local grow_x = detailed and (BLITZ_ICON_DETAILED_SIZE - base[3]) / 2 or 0
	local grow_y = detailed and (BLITZ_ICON_DETAILED_SIZE - base[4]) / 2 or 0

	offset[1] = base[1] - grow_x
	offset[2] = base[2] - grow_y
	size[1] = base[3] + grow_x * 2
	size[2] = base[4] + grow_y * 2
	icon_widget.dirty = true
	self._numericui_blitz_icon_enlarged = detailed
end

-- Puts in a detailed icon that was still loading, sizes the icon for what it shows, and keeps the outline on it. The
-- outline only shows while the icon shows a detailed one
local function update_numericui_blitz_icon_outline(self, widget, ui_renderer)
	local icon_widget = self._widgets_by_name.throwable
	local icon_content = icon_widget.content
	local pending_icon = self._numericui_blitz_pending_icon

	if pending_icon and Managers.package:has_loaded_id(self._numericui_blitz_pending_load_id) then
		self._numericui_blitz_pending_icon = nil
		self._numericui_blitz_pending_load_id = nil
		self._numericui_blitz_detailed_icon = pending_icon
		icon_content.texture = pending_icon
		icon_widget.dirty = true
	end

	local texture = icon_content.texture
	local detailed = texture == self._numericui_blitz_detailed_icon

	if self._numericui_blitz_icon_enlarged ~= detailed then
		resize_numericui_blitz_icon(self, icon_widget, detailed)
	end

	local visible = detailed and icon_content.visible ~= false
	local content = widget.content

	if visible and content.texture ~= texture then
		content.texture = texture
		widget.dirty = true
	end

	if content.visible ~= visible then
		self:_set_widget_visible(widget, visible, ui_renderer)
	end

	if not visible and content.texture ~= THROWABLE_DEFAULT_ICON then
		content.texture = THROWABLE_DEFAULT_ICON
	end
end

-- The count belongs to vanilla's Blitz icon, so it shows and hides with the icon and takes its colour. Bots and
-- Blitzes without charges, like Smite, get no count, since vanilla doesn't track their charges either
local function update_numericui_blitz_charges(self, player, ability_extension, widget, ui_renderer)
	local count = nil

	if
		self._grenade_ability_visible
		and ability_extension
		and player:is_human_controlled()
		and ability_extension:ability_is_equipped(GRENADE_ABILITY_TYPE)
		and ability_extension:max_ability_charges(GRENADE_ABILITY_TYPE) > 0
	then
		count = ability_extension:remaining_ability_charges(GRENADE_ABILITY_TYPE)
	end

	local visible = count ~= nil
	local content = widget.content

	if content.visible ~= visible then
		self:_set_widget_visible(widget, visible, ui_renderer)
	end

	if not visible then
		return
	end

	local status = self._grenade_ability_status

	-- only re-render the retained widget when the count or the icon's colour changes
	if content._numericui_count ~= count or content._numericui_status ~= status then
		content._numericui_count = count
		content._numericui_status = status
		content.text = string_format("%d", count)
		-- vanilla recolours the icon's colour table in place, so the text shares it
		widget.style.text.text_color = self._widgets_by_name.throwable.style.texture.color
		widget.dirty = true
	end
end

-- The peril widget's visible flag marks a Psyker. The archetype comes from the player's profile, which a bot replacing
-- a leaving player already has while its unit hasn't spawned yet. Until the profile has synced, the widget stays
-- hidden. Returns whether the archetype was known
local function mark_numericui_peril_owner(self, player)
	local peril_icon_widget = self._widgets_by_name.numeric_ui_peril_icon

	if not peril_icon_widget then
		return true
	end

	-- guarded like vanilla's name prefix: player:archetype_name() would index a profile without an archetype
	local profile = player:profile()
	local archetype = profile and profile.archetype
	local archetype_name = archetype and archetype.name

	peril_icon_widget.visible = archetype_name == "psyker"
	peril_icon_widget.content.icon_text = mod.setting("peril_icon") and PERIL_ICON or ""

	return archetype_name ~= nil
end

local function update_numericui_player_features(func, self, dt, t, player, ui_renderer)
	func(self, dt, t, player, ui_renderer)

	if not self._numericui_peril_owner_known then
		self._numericui_peril_owner_known = mark_numericui_peril_owner(self, player)
	end

	local ammo_text_widget = self._widgets_by_name.numeric_ui_ammo_text
	local peril_icon_widget = self._widgets_by_name.numeric_ui_peril_icon
	local extensions = self:_player_extensions(player)
	local unit_data_extension = extensions and extensions.unit_data

	if (ammo_text_widget or peril_icon_widget) and unit_data_extension then
		local elapsed = (self._numericui_ammo_t or AMMO_UPDATE_INTERVAL) + dt

		if elapsed >= AMMO_UPDATE_INTERVAL then
			self._numericui_ammo_t = 0
			update_numericui_ammo(self, unit_data_extension, ammo_text_widget, peril_icon_widget)
		else
			self._numericui_ammo_t = elapsed
		end
	end

	local ability_extension = extensions and extensions.ability

	-- runs without a unit too, so the cooldown widgets hide for a dead teammate
	if mod.setting("ability_cd_text") or mod.setting("ability_cd_bar") then
		update_numericui_ability_cd(
			self,
			ability_extension,
			self._widgets_by_name.ability_bar,
			self._widgets_by_name.ability_text
		)
	end

	local blitz_icon_outline_widget = self._widgets_by_name.numeric_ui_blitz_icon_outline

	if blitz_icon_outline_widget then
		update_numericui_blitz_icon_outline(self, blitz_icon_outline_widget, ui_renderer)
	end

	local blitz_charges_widget = self._widgets_by_name.numeric_ui_blitz_charges

	if blitz_charges_widget then
		update_numericui_blitz_charges(self, player, ability_extension, blitz_charges_widget, ui_renderer)
	end
end

mod:hook("HudElementPersonalPlayerPanel", "_update_player_features", update_numericui_player_features)
mod:hook("HudElementTeamPlayerPanel", "_update_player_features", update_numericui_player_features)

-- vanilla hides its own toughness bars here for a dead or hogtied player. Its content.visible switch leaves
-- widget.visible alone, which marks a Psyker on the peril widget
mod:hook_safe("HudElementTeamPlayerPanel", "_set_dead", function(self, _is_dead, show_as_dead, ui_renderer)
	local widgets_by_name = self._widgets_by_name
	local visible = not show_as_dead

	for i = 1, #COMBAT_WIDGET_NAMES do
		local widget = widgets_by_name[COMBAT_WIDGET_NAMES[i]]

		if widget then
			self:_set_widget_visible(widget, visible, ui_renderer)
		end
	end

	-- the ammo text refreshes on the frame the player comes back instead of up to an interval later
	self._numericui_ammo_t = nil
end)

mod:hook("HudElementTeamPlayerPanel", "init", function(func, self, _parent, _draw_layer, _start_scale, data)
	HudElementTeamPlayerPanelSettings.feature_list.health_text = mod.setting("health_text")
	HudElementTeamPlayerPanelSettings.feature_list.toughness_text = mod.setting("toughness_text")
	HudElementTeamPlayerPanelSettings.feature_list.level = mod.setting("level")

	func(self, _parent, _draw_layer, _start_scale, data)

	-- every panel's style is its own copy, so the shift can't add up. Bots get it too, keeping all rows aligned
	if mod.setting("blitz_charges_text") then
		local ammo_offset = self._widgets_by_name.ammo_status.style.ammo.offset

		ammo_offset[1] = ammo_offset[1] + BLITZ_CHARGES_AMMO_ICON_SHIFT
	end

	self._numericui_peril_owner_known = mark_numericui_peril_owner(self, data.player)
end)
