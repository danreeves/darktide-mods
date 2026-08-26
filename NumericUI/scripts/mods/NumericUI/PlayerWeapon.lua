-- Show maximum ammo
-- Description: Adds your max ammo to your HUD
-- Author: groundskeeper Willie, raindish

local mod = get_mod("NumericUI")
local PLAYER_WEAPON_HUD_DEF_PATH = "scripts/ui/hud/elements/player_weapon/hud_element_player_weapon_definitions"

local backups = mod:persistent_table("player_weapon_hud_backups")

local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local HudElementTeamPlayerPanelSettings =
	require("scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_settings")
local HudElementPlayerWeaponHandlerSettings =
	require("scripts/ui/hud/elements/player_weapon_handler/hud_element_player_weapon_handler_settings")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local FixedFrame = require("scripts/utilities/fixed_frame")

local math_abs = math.abs
local math_floor = math.floor
local math_huge = math.huge
local math_min = math.min
local math_round = math.round
local string_format = string.format
local table_clone = table.clone
local table_insert = table.insert
local table_merge_recursive = table.merge_recursive
local table_remove = table.remove

local AMMO_ICON_MATERIAL = "content/ui/materials/hud/icons/party_ammo"

local ammo_gained_cumulative = false --When true, will use a single widget to show multiple ammo increments
local ammo_gained_data = {
	widget_name = "ammo_gained_1",
	amount = 0,
	display_t = 0,
	offset = { -100.0, 10.0, 10.0 },
	offset_mod = { 0.1, 0.25 },
	offset_slow_mod = { 0.04, 0.2 },
	alpha_multiplier = 1,
}

-- Templates for the ammo-gained widget pool. Every HudElementPlayerWeapon gets its own copy,
-- because there is one element per weapon slot and each owns its own ammo_gained_* widgets.
local ammo_gained_widget_templates = {}

-- "ammo_text_" .. i built once instead of every frame
local _ammo_text_widget_names = {}

local AMMO_TEXT_FONT_SIZE_DEFAULT = 16
local AMMO_TEXT_OFFSET_X_DEFAULT = 80
local AMMO_TEXT_OFFSET_Y_DEFAULT = -16

local BLITZ_COOLDOWN_FONT_SIZE_DEFAULT = 30
local BLITZ_COOLDOWN_X_OFFSET_DEFAULT = -80
local BLITZ_COOLDOWN_Y_OFFSET_DEFAULT = 0
local BLITZ_BUFF_SCAN_INTERVAL = 0.5

local blitz_icon_size = HudElementPlayerWeaponHandlerSettings.icon_size
local blitz_cooldown_style = table_clone(UIFontSettings.hud_body)

blitz_cooldown_style.horizontal_alignment = "right"
blitz_cooldown_style.vertical_alignment = "center"
blitz_cooldown_style.text_horizontal_alignment = "center"
blitz_cooldown_style.text_vertical_alignment = "center"
blitz_cooldown_style.size = { blitz_icon_size[1], blitz_icon_size[2] }
blitz_cooldown_style.font_size = BLITZ_COOLDOWN_FONT_SIZE_DEFAULT
-- drawn above the blitz icon (z 4) and the vanilla cooldown gradient (z 3)
blitz_cooldown_style.offset = { 0, 0, 11 }

local directional_magnitude = 200
for i = 1, 4 do
	directional_magnitude = directional_magnitude * -1

	table_insert(ammo_gained_widget_templates, table_clone(ammo_gained_data))
	ammo_gained_widget_templates[i].widget_name = "ammo_gained_" .. i
	ammo_gained_widget_templates[i].offset_mod[1] = ammo_gained_data.offset_mod[1] + 5 * (i / directional_magnitude)
	ammo_gained_widget_templates[i].offset_mod[2] =
		math_abs(ammo_gained_data.offset_mod[2] + (i / directional_magnitude))
	ammo_gained_widget_templates[i].offset_slow_mod[1] = ammo_gained_data.offset_slow_mod[1]
		+ 5 * (i / directional_magnitude)
	ammo_gained_widget_templates[i].offset_slow_mod[2] =
		math_abs(ammo_gained_data.offset_slow_mod[2] + (i / directional_magnitude))
end

mod:hook_require(PLAYER_WEAPON_HUD_DEF_PATH, function(instance)
	backups.definitions = backups.definitions or table_clone(instance)

	instance.widget_definitions.ammo_icon = UIWidget.create_definition({
		{
			value_id = "ammo_icon",
			style_id = "ammo_icon",
			pass_type = "texture",
			-- this gets set later because it's a retained UI and there would be a static copy otherwise
			-- value = "content/ui/materials/hud/icons/party_ammo",
			value = "content/ui/materials/hud/icons/weapon_icon_container",
			retained_mode = false,
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				size = HudElementTeamPlayerPanelSettings.ammo_size,
				color = UIHudSettings.color_tint_main_1,
				offset = {
					0,
					0,
					6,
				},
			},
		},
	}, "background")

	instance.widget_definitions.ammo_gained_1 = UIWidget.create_definition({
		{
			value_id = "ammo_gained",
			style_id = "ammo_gained",
			pass_type = "text",
			value = "",
			retained_mode = false,
			style = {
				size = { 100, 20 },
				font_size = 35,
				vertical_alignment = "top",
				horizontal_alignment = "left",
				default_font_size = UIHudSettings.color_tint_main_1,
				text_color = UIHudSettings.player_status_colors["hogtied"], -- AKA green
				offset = { -100, 10, 10 },
			},
		},
	}, "weapon")

	instance.widget_definitions.ammo_gained_2 = UIWidget.create_definition({
		{
			value_id = "ammo_gained",
			style_id = "ammo_gained",
			pass_type = "text",
			value = " ",
			retained_mode = false,
			style = {
				size = { 100, 20 },
				font_size = 35,
				vertical_alignment = "top",
				horizontal_alignment = "left",
				default_font_size = UIHudSettings.color_tint_main_1,
				text_color = UIHudSettings.player_status_colors["hogtied"], -- AKA green
				offset = { -100, 10, 10 },
			},
		},
	}, "weapon")

	instance.widget_definitions.ammo_gained_3 = UIWidget.create_definition({
		{
			value_id = "ammo_gained",
			style_id = "ammo_gained",
			pass_type = "text",
			value = " ",
			retained_mode = false,
			style = {
				size = { 100, 20 },
				font_size = 35,
				vertical_alignment = "top",
				horizontal_alignment = "left",
				default_font_size = UIHudSettings.color_tint_main_1,
				text_color = UIHudSettings.player_status_colors["hogtied"], -- AKA green
				offset = { -100, 10, 10 },
			},
		},
	}, "weapon")

	instance.widget_definitions.ammo_gained_4 = UIWidget.create_definition({
		{
			value_id = "ammo_gained",
			style_id = "ammo_gained",
			pass_type = "text",
			value = " ",
			retained_mode = false,
			style = {
				size = { 100, 20 },
				font_size = 35,
				vertical_alignment = "top",
				horizontal_alignment = "left",
				default_font_size = UIHudSettings.color_tint_main_1,
				text_color = UIHudSettings.player_status_colors["hogtied"], -- AKA green
				offset = { -100, 10, 10 },
			},
		},
	}, "weapon")

	instance.widget_definitions.grenade_gained = UIWidget.create_definition({
		{
			value_id = "grenade_gained",
			style_id = "grenade_gained",
			pass_type = "text",
			value = "",
			retained_mode = false,
			style = {
				size = { 100, 20 },
				font_size = 35,
				vertical_alignment = "top",
				horizontal_alignment = "left",
				default_font_size = UIHudSettings.color_tint_main_1,
				text_color = UIHudSettings.player_status_colors["hogtied"], -- AKA green
				offset = { 120, -110, 10 },
			},
		},
	}, "weapon")

	instance.widget_definitions.blitz_cooldown = UIWidget.create_definition({
		{
			value_id = "blitz_cooldown",
			style_id = "blitz_cooldown",
			pass_type = "text",
			value = "",
			style = blitz_cooldown_style,
		},
	}, "background")

	local spare_ammo_style = table_clone(backups.definitions.widget_definitions.ammo_text_1.style.ammo_spare_1)
	local modifier = 0.8

	for i = 1, NetworkConstants.clips_in_use.max_size do
		_ammo_text_widget_names[i] = "ammo_text_" .. i

		local ammo_text_widget_orig = backups.definitions.widget_definitions["ammo_text_" .. i]
		if ammo_text_widget_orig then
			local ammo_text_widget = table_clone(ammo_text_widget_orig)
			UIWidget.add_definition_pass(ammo_text_widget, {
				value_id = "max_ammo",
				style_id = "max_ammo",
				pass_type = "text",
				value = "",
				style = table_merge_recursive(spare_ammo_style, {
					font_size = spare_ammo_style.font_size * modifier,
					default_font_size = spare_ammo_style.default_font_size * modifier,
					focused_font_size = spare_ammo_style.focused_font_size * modifier,
				}),
			})
			instance.widget_definitions["ammo_text_" .. i] = ammo_text_widget
		end
	end
end)

local function display_grenade_gained(dt, widget, data)
	if data.amount == 0 then
		return false
	end

	local display_t = data.display_t
	local widget_cleared = false

	if display_t < 1.5 then
		widget.style.grenade_gained.offset[2] = widget.style.grenade_gained.offset[2] - (0.1 / display_t)
		widget.style.grenade_gained.offset[1] = widget.style.grenade_gained.offset[1] - (0.2 / display_t)
		data.display_t = display_t + dt
	elseif display_t < 2.5 then
		widget.style.grenade_gained.offset[2] = widget.style.grenade_gained.offset[2] - (0.1 / display_t)
		widget.style.grenade_gained.offset[1] = widget.style.grenade_gained.offset[1] - (0.15 / display_t)
		widget.alpha_multiplier = 2.5 - display_t
		data.display_t = display_t + dt
	else
		widget.style.grenade_gained.offset = { 120, -110, 10 }
		data.display_t = 0
		data.amount = 0
		widget.alpha_multiplier = 1
		widget.content.grenade_gained = " "
		widget_cleared = true
	end

	widget.dirty = true
	return widget_cleared
end

local function display_ammo_gained(dt, widget, data)
	--[[
	Display an ammo_gained widget based on the information in data, as it is manipulated by the delta time.
	Will display an ammo gained widget for 1.5s, then an additional 1s as it fades. Returns true if the
	widget is no longer displayed, and false if it still requires additional display cycles.

	dt: time since previous update loop
	widget: The ammo_gained widget you wish to update
	data: A block of data containing information about the widget and how it should be updated. Formatted as follows:
	{
		widget_name = string, --The name of the widget
		amount = number, --The amount of ammo to be displayed
		display_t = number, --How long the widget has already been displayed
		offset = {number, number, number}, --The default offset the widget should reset to and start from
		offset_mod = {number, number}, --How the widget offset should be modified in the first 1.5s
		offset_slow_mod = {number, number}, --How the widget offset should be modified in the last 1s
		alpha_multiplier = number --The widget's alpha multiplier (i.e, how visible it should be)
	}
	]]

	if data.amount == 0 then
		return true
	end

	local display_t = data.display_t
	local widget_cleared = false

	if display_t < 1.5 then
		widget.style.ammo_gained.offset[2] = widget.style.ammo_gained.offset[2] - (data.offset_mod[2] / display_t)
		widget.style.ammo_gained.offset[1] = widget.style.ammo_gained.offset[1] - (data.offset_mod[1] / display_t)
		data.display_t = display_t + dt
	elseif display_t < 2.5 then
		widget.style.ammo_gained.offset[2] = widget.style.ammo_gained.offset[2] - (data.offset_slow_mod[2] / display_t)
		widget.style.ammo_gained.offset[1] = widget.style.ammo_gained.offset[1] - (data.offset_slow_mod[1] / display_t)
		data.alpha_multiplier = 2.5 - display_t
		data.display_t = display_t + dt
	else
		widget.style.ammo_gained.offset = table_clone(data.offset)
		data.display_t = 0
		data.amount = 0
		data.alpha_multiplier = 1
		widget.content.ammo_gained = " "
		widget_cleared = true
	end

	widget.alpha_multiplier = data.alpha_multiplier
	widget.dirty = true
	return widget_cleared
end

local function _element_state(self)
	if self._numericui_ammo_available then
		return
	end

	local available = {}

	for i = 1, #ammo_gained_widget_templates do
		available[i] = table_clone(ammo_gained_widget_templates[i])
	end

	self._numericui_ammo_available = available
	self._numericui_ammo_active = {}
	self._numericui_ammo_cumulative = table_clone(ammo_gained_data)
	self._numericui_grenade = {
		amount = 0,
		display_t = 0,
	}
end

local function _update_max_ammo_style(self)
	if not mod.setting("max_ammo_text") then
		return
	end

	local max_ammo_font_size = mod.setting("ammo_text_font_size") or AMMO_TEXT_FONT_SIZE_DEFAULT
	local max_ammo_offset_x = mod.setting("ammo_text_offset_x") or AMMO_TEXT_OFFSET_X_DEFAULT
	local max_ammo_offset_y = mod.setting("ammo_text_offset_y") or AMMO_TEXT_OFFSET_Y_DEFAULT
	local widgets_by_name = self._widgets_by_name

	for i = 1, NetworkConstants.clips_in_use.max_size do
		local ammo_text_widget = widgets_by_name[_ammo_text_widget_names[i]]

		if ammo_text_widget then
			local style = ammo_text_widget.style
			local max_ammo_style = style.max_ammo
			local base_y = style.ammo_amount_4.offset[2]

			-- only touch the style when a setting or the clip counter position changes
			if
				max_ammo_style._numericui_font_size ~= max_ammo_font_size
				or max_ammo_style._numericui_offset_x ~= max_ammo_offset_x
				or max_ammo_style._numericui_offset_y ~= max_ammo_offset_y
				or max_ammo_style._numericui_base_y ~= base_y
			then
				max_ammo_style._numericui_font_size = max_ammo_font_size
				max_ammo_style._numericui_offset_x = max_ammo_offset_x
				max_ammo_style._numericui_offset_y = max_ammo_offset_y
				max_ammo_style._numericui_base_y = base_y
				max_ammo_style.font_size = max_ammo_font_size
				max_ammo_style.default_font_size = max_ammo_font_size
				max_ammo_style.focused_font_size = max_ammo_font_size
				max_ammo_style.drop_shadow = true
				-- anchor from the default font size so changing the font size
				-- only resizes the text instead of also moving it
				max_ammo_style.offset[1] = AMMO_TEXT_FONT_SIZE_DEFAULT * 2
					+ (max_ammo_offset_x - AMMO_TEXT_OFFSET_X_DEFAULT)
				max_ammo_style.offset[2] = base_y
					+ AMMO_TEXT_FONT_SIZE_DEFAULT * 1.1
					+ (max_ammo_offset_y - AMMO_TEXT_OFFSET_Y_DEFAULT)
				ammo_text_widget.dirty = true
			end
		end
	end
end

local function _update_max_ammo_text(self, total_current, total_max)
	local slot_component = self._slot_component
	local max_reserve = slot_component and slot_component.max_ammunition_reserve
	local show_max_ammo_text = mod.setting("max_ammo_text")
	local show_as_percent = show_max_ammo_text and mod.setting("show_max_ammo_as_percent")
	local widgets_by_name = self._widgets_by_name

	_update_max_ammo_style(self)

	for i = 1, NetworkConstants.clips_in_use.max_size do
		local ammo_text_widget = widgets_by_name[_ammo_text_widget_names[i]]

		if ammo_text_widget then
			local content = ammo_text_widget.content

			if show_max_ammo_text and max_reserve then
				local max_ammo_value

				if show_as_percent then
					if total_max and total_max > 0 then
						max_ammo_value = math_floor(math_min(total_current / total_max * 100, 100))
					else
						max_ammo_value = 0
					end
				else
					max_ammo_value = max_reserve
				end

				-- only rebuild the string when the displayed value changes
				if content._numericui_max_ammo_value ~= max_ammo_value then
					content._numericui_max_ammo_value = max_ammo_value

					if show_as_percent then
						content.max_ammo = string_format("%d%%", max_ammo_value)
					else
						content.max_ammo = string_format("/%d", max_ammo_value)
					end

					ammo_text_widget.dirty = true
				end
			elseif content.max_ammo ~= "" then
				content._numericui_max_ammo_value = nil
				content.max_ammo = ""
				ammo_text_widget.dirty = true
			end
		end
	end

	self._numericui_max_reserve = max_reserve
end

local function _update_ammo_icon_color(self, total_current, total_max)
	if not mod.setting("show_ammo_icon") then
		return
	end

	local icon_widget = self._widgets_by_name.ammo_icon

	if not icon_widget then
		return
	end

	if icon_widget.content.ammo_icon ~= AMMO_ICON_MATERIAL then
		icon_widget.content.ammo_icon = AMMO_ICON_MATERIAL
		icon_widget.dirty = true
	end

	local weapon_ammo_fraction = 0

	if total_max and total_max > 0 then
		weapon_ammo_fraction = total_current / total_max
	end

	local color

	if weapon_ammo_fraction > 0.66 then
		color = UIHudSettings.color_tint_main_1
	elseif weapon_ammo_fraction > 0.33 then
		color = UIHudSettings.color_tint_ammo_low
	elseif weapon_ammo_fraction > 0 then
		color = UIHudSettings.color_tint_ammo_medium
	else
		color = UIHudSettings.color_tint_ammo_high
	end

	if color ~= icon_widget.style.ammo_icon.color then
		icon_widget.style.ammo_icon.color = color
		icon_widget.dirty = true
	end
end

mod:hook_safe("HudElementPlayerWeapon", "_set_ammo_amount", function(self, amount, total_max_amount)
	-- called once from init with (nil, nil), before any clip data exists
	if not amount then
		return
	end

	local uses_ammo = self._uses_ammo and not self._infinite_ammo

	if not uses_ammo or self._uses_weapon_special_charges then
		return
	end

	_element_state(self)

	local show_munitions_gained = mod.setting("show_munitions_gained")

	if self._ability and self._ability.ability_type then
		-- grenades and other ability charges
		local prev_charges = self._numericui_prev_grenade or amount

		if show_munitions_gained and amount > prev_charges then
			local grenade = self._numericui_grenade

			grenade.pending = (grenade.pending or 0) + (amount - prev_charges)
		end

		self._numericui_prev_grenade = amount

		return
	end

	local slot_component = self._slot_component
	local max_reserve = slot_component and slot_component.max_ammunition_reserve

	if not max_reserve or max_reserve <= 0 then
		return
	end

	self._numericui_total_current = amount
	self._numericui_total_max = total_max_amount

	local max_clip = self._max_ammunition_clips[1] or 0
	self._numericui_ammo_len = max_clip >= 10 and 3 or 2

	_update_max_ammo_text(self, amount, total_max_amount)
	_update_ammo_icon_color(self, amount, total_max_amount)

	mod._pickup_preview_dirty = true

	local prev_ammo = self._numericui_prev_ammo or amount

	if show_munitions_gained and amount > prev_ammo then
		self._numericui_pending_ammo_gain = (self._numericui_pending_ammo_gain or 0) + (amount - prev_ammo)
	end

	self._numericui_prev_ammo = amount
end)

mod:hook_safe("HudElementPlayerWeapon", "set_wield_anim_progress", function(self, _progress, ui_renderer)
	_update_max_ammo_style(self)

	local ammo_len = self._numericui_ammo_len

	if not ammo_len or not mod.setting("show_ammo_icon") then
		return
	end

	local widgets_by_name = self._widgets_by_name
	local icon_widget = widgets_by_name.ammo_icon
	local ammo_text_widget = widgets_by_name.ammo_text_1

	if not icon_widget or not ammo_text_widget then
		return
	end

	local amount_style = ammo_text_widget.style.ammo_amount_1
	local font_size = amount_style.font_size
	local anchor_x = ammo_text_widget.offset[1]
	local anchor_y = ammo_text_widget.offset[2]

	if
		ammo_len == self._numericui_icon_len
		and font_size == self._numericui_icon_font_size
		and anchor_x == self._numericui_icon_anchor_x
		and anchor_y == self._numericui_icon_anchor_y
	then
		return
	end

	self._numericui_icon_len = ammo_len
	self._numericui_icon_font_size = font_size
	self._numericui_icon_anchor_x = anchor_x
	self._numericui_icon_anchor_y = anchor_y

	local text_width, text_height = UIRenderer.text_size(ui_renderer, "0", amount_style.font_type, font_size)
	local gap_size = font_size * 0.25
	local icon_size = 12
	local char_gap = (ammo_len - 1) * gap_size

	icon_widget.offset[1] = anchor_x - ((text_width * ammo_len) + char_gap)
	icon_widget.offset[2] = anchor_y - text_height + icon_size
	icon_widget.dirty = true
end)

local function _step_ammo_gained(self, dt, gained)
	local widgets_by_name = self._widgets_by_name

	if ammo_gained_cumulative then
		local data = self._numericui_ammo_cumulative

		if gained then
			data.amount = data.amount + gained
			widgets_by_name.ammo_gained_1.content.ammo_gained = "+" .. data.amount
			data.display_t = (data.display_t + dt) / 2
		end

		display_ammo_gained(dt, widgets_by_name.ammo_gained_1, data)

		return
	end

	local available = self._numericui_ammo_available
	local active = self._numericui_ammo_active

	if gained then
		local widget_data

		if #available > 0 then
			widget_data = table_remove(available)
		else
			-- If more than 4 widgets are already being shown, we reset and use the oldest one.
			widget_data = table_remove(active, 1)
			widget_data.alpha_multiplier = 1
			widgets_by_name[widget_data.widget_name].style.ammo_gained.offset = table_clone(widget_data.offset)
		end

		widget_data.display_t = dt
		widget_data.amount = gained
		table_insert(active, widget_data)
		widgets_by_name[widget_data.widget_name].content.ammo_gained = "+" .. widget_data.amount
	end

	for i = #active, 1, -1 do
		local widget_data = active[i]

		if display_ammo_gained(dt, widgets_by_name[widget_data.widget_name], widget_data) then
			table_insert(available, table_remove(active, i))
		end
	end
end

local function _step_grenade_gained(self, dt)
	local grenade = self._numericui_grenade
	local widget = self._widgets_by_name.grenade_gained

	if grenade.pending then
		grenade.amount = grenade.amount + grenade.pending
		grenade.pending = nil
		widget.content.grenade_gained = "+" .. grenade.amount
		grenade.display_t = (grenade.display_t + dt) / 2
	end

	display_grenade_gained(dt, widget, grenade)
end

local function _blitz_counter_extra_width(self)
	local max_ammunition_clips = self._max_ammunition_clips
	local max_charges = max_ammunition_clips and max_ammunition_clips[1]

	if not max_charges or max_charges < 10 then
		return 0
	end

	local ammo_text_widget = self._widgets_by_name[_ammo_text_widget_names[1]]
	local amount_style = ammo_text_widget and ammo_text_widget.style.ammo_amount_1

	if not amount_style then
		return 0
	end

	local extra_digits = max_charges < 100 and 1 or 2
	local digit_width = math_round(amount_style.font_size * 0.55)

	return extra_digits * digit_width
end

local function _update_blitz_cooldown_style(self, widget)
	local font_size = mod.setting("blitz_cooldown_font_size") or BLITZ_COOLDOWN_FONT_SIZE_DEFAULT
	local x_offset = (mod.setting("blitz_cooldown_x_offset") or BLITZ_COOLDOWN_X_OFFSET_DEFAULT)
		- _blitz_counter_extra_width(self)
	local y_offset = mod.setting("blitz_cooldown_y_offset") or BLITZ_COOLDOWN_Y_OFFSET_DEFAULT
	local height_offset = (self._height_offset or 0) + y_offset
	local offset = widget.offset
	local style = widget.style.blitz_cooldown

	if style._numericui_font_size ~= font_size then
		style._numericui_font_size = font_size
		style.font_size = font_size
		widget.dirty = true
	end

	if offset[1] ~= x_offset then
		offset[1] = x_offset
		widget.dirty = true
	end

	if offset[2] ~= height_offset then
		offset[2] = height_offset
		widget.dirty = true
	end
end

local function _find_blitz_replenishment_buff(buff_extension)
	local buffs = buff_extension:buffs()

	for i = 1, #buffs do
		local buff = buffs[i]
		local template_data = buff._template_data

		if template_data and template_data.missing_charges then
			return buff
		end
	end
end

local function _blitz_replenishment_cooldown(self, dt)
	local buff = self._numericui_blitz_buff
	local scan_delay = (self._numericui_blitz_buff_scan or 0) - dt

	if not buff or scan_delay <= 0 then
		local buff_extension = self._parent:get_player_extension(self._data.player, "buff_system")

		buff = buff_extension and _find_blitz_replenishment_buff(buff_extension)
		scan_delay = BLITZ_BUFF_SCAN_INTERVAL
		self._numericui_blitz_buff = buff
	end

	self._numericui_blitz_buff_scan = scan_delay

	local template_data = buff and buff._template_data
	local next_charge_t = template_data and (template_data.next_grenade_t or template_data.next_knife_t)

	if not next_charge_t then
		return
	end

	local remaining = next_charge_t - FixedFrame.get_latest_fixed_time()

	if remaining <= 0 then
		return
	end

	local total = template_data.grenade_replenishment_cooldown or template_data.cooldown

	return remaining, total and total > 0 and remaining / total or nil
end

local function _blitz_remaining_cooldown(self, dt)
	local ability_extension = self._ability_extension
	local ability_type = self._ability.ability_type

	if not ability_type or not ability_extension then
		return
	end

	if
		ability_extension:remaining_ability_charges(ability_type)
		>= ability_extension:max_ability_charges(ability_type)
	then
		return
	end

	local remaining = ability_extension:remaining_ability_cooldown(ability_type)

	if remaining and remaining > 0 and remaining ~= math_huge then
		return remaining, self._cooldown_progress
	end

	return _blitz_replenishment_cooldown(self, dt)
end

local function _update_blitz_cooldown_text(self, dt)
	local widget = self._widgets_by_name.blitz_cooldown

	if not widget then
		return
	end

	local content = widget.content
	local cooldown_format = mod.setting("blitz_cooldown_format")
	local new_text

	if cooldown_format ~= "time" and cooldown_format ~= "percent" then
		content._numericui_last_value = nil
		new_text = " "
	else
		local remaining, progress = _blitz_remaining_cooldown(self, dt)

		if not remaining then
			content._numericui_last_value = nil
			new_text = " "
		else
			_update_blitz_cooldown_style(self, widget)

			if cooldown_format == "percent" then
				if progress then
					local percent = math_floor((1 - progress) * 100)

					if content._numericui_last_value ~= percent then
						content._numericui_last_value = percent
						new_text = string_format("%d%%", percent)
					end
				else
					content._numericui_last_value = nil
					new_text = " "
				end
			elseif remaining <= 1 then
				content._numericui_last_value = nil
				new_text = string_format("%.1f", remaining)
			else
				local seconds = math_floor(remaining)

				if content._numericui_last_value ~= seconds then
					content._numericui_last_value = seconds
					new_text = string_format("%d", seconds)
				end
			end
		end
	end

	if new_text and content.blitz_cooldown ~= new_text then
		content.blitz_cooldown = new_text
		widget.dirty = true
	end
end

local function _update_blitz_background_progress(self)
	if not mod.setting("disable_blitz_background_progress") then
		return
	end

	local background_widget = self._widgets_by_name.background
	local glow_style = background_widget and background_widget.style.background_glow

	if glow_style and glow_style.scale[2] ~= 0 then
		glow_style.uvs[2][2] = 0
		glow_style.scale[2] = 0
		background_widget.dirty = true
	end
end

mod:hook_safe("HudElementPlayerWeapon", "update", function(self, dt)
	local cached_max_reserve = self._numericui_max_reserve

	if cached_max_reserve then
		local slot_component = self._slot_component

		if slot_component and slot_component.max_ammunition_reserve ~= cached_max_reserve then
			_update_max_ammo_text(self, self._numericui_total_current, self._numericui_total_max)
		end
	end

	local gained = self._numericui_pending_ammo_gain
	local active = self._numericui_ammo_active

	if gained or (active and #active > 0) then
		self._numericui_pending_ammo_gain = nil
		_step_ammo_gained(self, dt, gained)
	end

	local grenade = self._numericui_grenade

	if grenade and (grenade.pending or grenade.amount ~= 0) then
		_step_grenade_gained(self, dt)
	end

	if self._ability then
		_update_blitz_cooldown_text(self, dt)
		_update_blitz_background_progress(self)
	end
end)
