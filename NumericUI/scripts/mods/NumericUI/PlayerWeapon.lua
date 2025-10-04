-- Show maximum ammo
-- Description: Adds your max ammo to your HUD
-- Author: groundskeeper Willie, raindish

local mod = get_mod("NumericUI")
local Ammo = require("scripts/utilities/ammo")
local PLAYER_WEAPON_HUD_DEF_PATH = "scripts/ui/hud/elements/player_weapon/hud_element_player_weapon_definitions"

local backups = mod:persistent_table("player_weapon_hud_backups")
backups.definitions = backups.definitions or table.clone(mod:original_require(PLAYER_WEAPON_HUD_DEF_PATH))

local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local HudElementTeamPlayerPanelSettings = require(
	"scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_settings"
)

--Init global vars for mod: "show_munitions_gained"
local prev_clip_ammo_char_len = 0 -- Tells where ammo icon should be generated
local prev_font_size = nil -- checks to see if the font was changed in some way
local prev_grenade_charges = 0 --Keeps track of grenade amount in the previous loop.
local grenade_gained_display_t = 0 --keeps track of how long the grenade gained widget has been displayed
local grenade_gained_amount = 0 --Keeps track of the amount of grenades gained
local ammo_gained_cumulative = false --When true, will use a single widget to show multiple ammo increments
local ammo_gained_available_widgets = {} --List of non-active ammo-gained widgets (for non-cumulative display)
local ammo_gained_active_widgets = {}
local ammo_gained_data = {
	widget_name = "ammo_gained_1",
	amount = 0,
	display_t = 0,
	offset = { -100.0, 10.0, 10.0 },
	offset_mod = { 0.1, 0.25 },
	offset_slow_mod = { 0.04, 0.2 },
	alpha_multiplier = 1,
}

local directional_magnitude = 200
for i = 1, 4 do
	directional_magnitude = directional_magnitude * -1

	table.insert(ammo_gained_available_widgets, table.clone(ammo_gained_data))
	ammo_gained_available_widgets[i].widget_name = "ammo_gained_" .. i
	ammo_gained_available_widgets[i].offset_mod[1] = ammo_gained_data.offset_mod[1] + 5 * (i / directional_magnitude)
	ammo_gained_available_widgets[i].offset_mod[2] = math.abs(
		ammo_gained_data.offset_mod[2] + (i / directional_magnitude)
	)
	ammo_gained_available_widgets[i].offset_slow_mod[1] = ammo_gained_data.offset_slow_mod[1]
		+ 5 * (i / directional_magnitude)
	ammo_gained_available_widgets[i].offset_slow_mod[2] = math.abs(
		ammo_gained_data.offset_slow_mod[2] + (i / directional_magnitude)
	)
end

mod:hook_require(PLAYER_WEAPON_HUD_DEF_PATH, function(instance)
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

	local ammo_text_widget = table.clone(backups.definitions.widget_definitions.ammo_text)
	local spare_ammo_style = table.clone(backups.definitions.widget_definitions.ammo_text.style.ammo_spare_1)
	local modifier = 0.8
	UIWidget.add_definition_pass(ammo_text_widget, {
		value_id = "max_ammo",
		style_id = "max_ammo",
		pass_type = "text",
		value = "",
		style = table.merge_recursive(spare_ammo_style, {
			font_size = spare_ammo_style.font_size * modifier,
			default_font_size = spare_ammo_style.default_font_size * modifier,
			focused_font_size = spare_ammo_style.focused_font_size * modifier,
		}),
	})
	instance.widget_definitions.ammo_text = ammo_text_widget
end)

local function display_grenade_gained(dt, widget)
	if grenade_gained_amount == 0 then
		return false
	end

	local display_t = grenade_gained_display_t
	local widget_cleared = false

	if display_t < 1.5 then
		widget.style.grenade_gained.offset[2] = widget.style.grenade_gained.offset[2] - (0.1 / display_t)
		widget.style.grenade_gained.offset[1] = widget.style.grenade_gained.offset[1] - (0.2 / display_t)
		grenade_gained_display_t = display_t + dt
	elseif display_t < 2.5 then
		widget.style.grenade_gained.offset[2] = widget.style.grenade_gained.offset[2] - (0.1 / display_t)
		widget.style.grenade_gained.offset[1] = widget.style.grenade_gained.offset[1] - (0.15 / display_t)
		widget.alpha_multiplier = 2.5 - display_t
		grenade_gained_display_t = display_t + dt
	else
		widget.style.grenade_gained.offset = { 120, -110, 10 }
		grenade_gained_display_t = 0
		grenade_gained_amount = 0
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
		widget.style.ammo_gained.offset = table.clone(data.offset)
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

mod:hook_safe("HudElementPlayerWeapon", "update", function(self, _dt, _t, ui_renderer)
	local uses_ammo = self._uses_ammo and not self._infinite_ammo
	local ability_type = self._ability and self._ability.ability_type

	if not ability_type then
		local slot_component = self._slot_component

		if slot_component and uses_ammo then
			local ammo_text_widget = self._widgets_by_name.ammo_text
			local icon_widget = self._widgets_by_name.ammo_icon

			local max_clip = Ammo.max_ammo_in_clips(slot_component) or 0
			local max_reserve = slot_component.max_ammunition_reserve or 0
			local current_clip = Ammo.current_ammo_in_clips(slot_component) or 0
			local current_reserve = slot_component.current_ammunition_reserve or 0

			local total_current_ammo = current_clip + current_reserve
			local total_max_ammo = max_clip + max_reserve

			if ammo_text_widget then
				local content = ammo_text_widget.content
				local style = ammo_text_widget.style
				ammo_text_widget.content.max_ammo = ""

				if mod:get("max_ammo_text") and max_reserve then
					local display_text = ""
					if mod:get("show_max_ammo_as_percent") then
						display_text = string.format("%d%%", math.min(total_current_ammo / total_max_ammo * 100, 100))
					else
						display_text = string.format("/%d", max_reserve)
					end
					content.max_ammo = display_text

					style.max_ammo.offset[1] = style.max_ammo.offset[1] + style.max_ammo.font_size * 2
					style.max_ammo.offset[2] = style.max_ammo.offset[2] + style.max_ammo.font_size * 1.1
					style.max_ammo.drop_shadow = true
				end

				if mod:get("show_ammo_icon") and icon_widget and max_reserve then
					icon_widget.content.ammo_icon = "content/ui/materials/hud/icons/party_ammo"

					local color = nil
					local weapon_ammo_fraction = 0

					if total_max_ammo > 0 then
						weapon_ammo_fraction = total_current_ammo / total_max_ammo
					end

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

					local ammo_len = max_clip < 10 and 2 or 3
					local font_size = ammo_text_widget.style.ammo_amount_1.font_size
					if ammo_len ~= prev_clip_ammo_char_len or prev_font_size ~= font_size then
						local font_type = ammo_text_widget.style.ammo_amount_1.font_type
						local text_width, text_height = UIRenderer.text_size(ui_renderer, "0", font_type, font_size)
						local gap_size = font_size * 0.25
						local icon_size = 12
						local char_gap = (ammo_len - 1) * gap_size
						local x_offset = ammo_text_widget.offset[1] - ((text_width * ammo_len) + char_gap)
						local y_offset = ammo_text_widget.offset[2] - text_height + icon_size

						icon_widget.offset[1] = x_offset
						icon_widget.offset[2] = y_offset

						icon_widget.dirty = true
						prev_clip_ammo_char_len = ammo_len
						prev_font_size = font_size
					end
				end
			end

			if mod:get("show_munitions_gained") then --this one checks for ammo gained
				local total_ammo = self._total_ammo
				local prev_ammo = self._prev_ammo or self._total_ammo

				if ammo_gained_cumulative then
					local ammo_gained_widget = self._widgets_by_name.ammo_gained_1

					if total_ammo > prev_ammo then
						ammo_gained_data.amount = total_ammo - prev_ammo + ammo_gained_data.amount
						ammo_gained_widget.content.ammo_gained = "+" .. ammo_gained_data.amount
						ammo_gained_data.display_t = (ammo_gained_data.display_t + _dt) / 2
					end

					display_ammo_gained(_dt, self._widgets_by_name["ammo_gained_1"], ammo_gained_data)
				else
					if total_ammo > prev_ammo then
						local widget_data

						if #ammo_gained_available_widgets > 0 then
							widget_data = table.remove(ammo_gained_available_widgets)
						else
							widget_data = table.remove(ammo_gained_active_widgets, 1) -- If more than 4 widgets are already being shown, we reset and use the oldest one.
							widget_data.alpha_multiplier = 1
							self._widgets_by_name[widget_data.widget_name].style.ammo_gained.offset = table.clone(
								widget_data.offset
							)
						end

						widget_data.display_t = _dt
						widget_data.amount = total_ammo - prev_ammo
						table.insert(ammo_gained_active_widgets, widget_data)
						self._widgets_by_name[widget_data.widget_name].content.ammo_gained = "+" .. widget_data.amount
					end

					for i = #ammo_gained_active_widgets, 1, -1 do
						local ammo_gained_widget = self._widgets_by_name[ammo_gained_active_widgets[i].widget_name]

						local widget_cleared = display_ammo_gained(
							_dt,
							self._widgets_by_name[ammo_gained_active_widgets[i].widget_name],
							ammo_gained_active_widgets[i]
						)

						if widget_cleared then
							local widget_temp = table.remove(ammo_gained_active_widgets, i)
							table.insert(ammo_gained_available_widgets, widget_temp)
						end
					end
				end

				self._prev_ammo = total_ammo
			end
		end
	elseif mod:get("show_munitions_gained") and uses_ammo then --This one checks for grenades gained
		local grenade_gained_widget = self._widgets_by_name.grenade_gained
		local total_ammo = self._total_ammo

		if total_ammo > prev_grenade_charges then
			grenade_gained_amount = total_ammo - prev_grenade_charges + grenade_gained_amount
			grenade_gained_widget.content.grenade_gained = "+" .. grenade_gained_amount
			grenade_gained_display_t = (grenade_gained_display_t + _dt) / 2
		end

		display_grenade_gained(_dt, self._widgets_by_name.grenade_gained)
		prev_grenade_charges = total_ammo
	end
end)
