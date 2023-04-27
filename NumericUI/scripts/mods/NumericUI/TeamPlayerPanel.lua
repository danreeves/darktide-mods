local mod = get_mod("NumericUI")
local TEAM_HUD_DEF_PATH = "scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions"

local backups = mod:persistent_table("team_hud_backups")
backups.team_hud_definitions = backups.team_hud_definitions or mod:original_require(TEAM_HUD_DEF_PATH)

local UIWidget = require("scripts/managers/ui/ui_widget")
local HudElementTeamPlayerPanelSettings = require(
	"scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_settings"
)
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local FixedFrame = require("scripts/utilities/fixed_frame")

-- Force team hud for yourself
if false then
	mod:hook_origin(
		"HudElementTeamPanelHandler",
		"_add_panel",
		function(self, unique_id, ui_renderer, fixed_scenegraph_id)
			local PlayerCompositions = require("scripts/utilities/players/player_compositions")
			local HudElementPersonalPlayerPanelHub = require(
				"scripts/ui/hud/elements/personal_player_panel_hub/hud_element_personal_player_panel_hub"
			)
			local HudElementTeamPlayerPanelHub = require(
				"scripts/ui/hud/elements/team_player_panel_hub/hud_element_team_player_panel_hub"
			)
			local HudElementTeamPlayerPanel = require(
				"scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel"
			)
			local player_composition_name = self._player_composition_name
			local player = PlayerCompositions.player_from_unique_id(player_composition_name, unique_id)
			local scale = ui_renderer.scale or 1
			local scenegraph_id = fixed_scenegraph_id or self:_get_available_scenegraph()
			local draw_layer = self._draw_layer
			local parent = self._parent
			local is_my_player = self._my_player == player
			local data = {
				synced = false,
				unique_id = unique_id,
				player = player,
				is_my_player = is_my_player,
				local_player = self._my_player,
				scenegraph_id = scenegraph_id,
				using_fixed_scenegraph_id = fixed_scenegraph_id ~= nil,
			}
			local panel = nil
			local host_type = Managers.connection:host_type()
			local game_mode_name = Managers.state.game_mode and Managers.state.game_mode:game_mode_name()
			local is_in_hub = host_type == "hub_server" or game_mode_name == "hub"
			local is_in_training_grounds = game_mode_name == "shooting_range"

			if is_in_training_grounds then
				if is_my_player then
					panel = HudElementTeamPlayerPanel:new(parent, draw_layer, scale, data)
				else
					panel = HudElementTeamPlayerPanelHub:new(parent, draw_layer, scale, data)
				end
			elseif is_in_hub then
				if is_my_player then
					panel = HudElementPersonalPlayerPanelHub:new(parent, draw_layer, scale, data)
				else
					panel = HudElementTeamPlayerPanelHub:new(parent, draw_layer, scale, data)
				end
			else
				panel = HudElementTeamPlayerPanel:new(parent, draw_layer, scale, data)
			end

			data.panel = panel
			self._player_panels_array[#self._player_panels_array + 1] = data
			self._player_panel_by_unique_id[unique_id] = data
			self._unique_id_by_scenegraph[scenegraph_id] = unique_id
			self._num_panels = self._num_panels + 1
		end
	)
end

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

local ability_max_cooldown = {} -- "player ID -> max cooldown"
local ability_cooldown_timer = {} -- "player ID -> cooldown timer"
local throwable_block_size = {HudElementTeamPlayerPanelSettings.throwable_size[1], 3}
local throwable_show_number = false
local throwable_show_bars = false

mod:hook_require(TEAM_HUD_DEF_PATH, function(instance)

	if mod:get("grenades_count") then 
		instance.widget_definitions.team_throwable_text = UIWidget.create_definition({
			{
				value = " ",
				style_id = "text",
				value_id = "text",
				pass_type = "text",
				visible = false,
				style = {
					vertical_alignment = "bottom",
					horizontal_alignment = "right",
					text_horizontal_alignment = "right",
					offset = {0, -20, 0 },
					font_type = "machine_medium",
					font_size = 17,--HudElementTeamPlayerPanelSettings.throwable_size[1],
					text_color = UIHudSettings.color_tint_main_1,
					character_spacing = 0.05,
				},
			}, 
		}, "toughness_bar")

		instance.widget_definitions.team_throwable_icon = UIWidget.create_definition({
			{
				value = "content/ui/materials/hud/icons/weapon_icon_container",
				style_id = "icon_1",
				value_id = "icon_1",
				pass_type = "texture",
				visible = false,
				style = {
					vertical_alignment = "bottom",
					horizontal_alignment = "right",
					offset = { 0, -11, 0 },
					size = HudElementTeamPlayerPanelSettings.throwable_size,
					color = UIHudSettings.color_tint_main_1,
				},
			},
			{
				value = "content/ui/materials/hud/icons/weapon_icon_container",
				style_id = "icon_2",
				value_id = "icon_2",
				pass_type = "texture",
				visible = false,
				style = {
					vertical_alignment = "bottom",
					horizontal_alignment = "right",
					offset = { 0, -11, 0 },
					size = HudElementTeamPlayerPanelSettings.throwable_size,
					color = UIHudSettings.color_tint_main_1,
				},
			},
			{
				value = "content/ui/materials/hud/icons/weapon_icon_container",
				style_id = "icon_3",
				value_id = "icon_3",
				pass_type = "texture",
				visible = false,
				style = {
					vertical_alignment = "bottom",
					horizontal_alignment = "right",
					offset = { 0, -11, 0 },
					size = HudElementTeamPlayerPanelSettings.throwable_size,
					color = UIHudSettings.color_tint_main_1,
				},
			},
			{
				value = "content/ui/materials/hud/icons/weapon_icon_container",
				style_id = "icon_4",
				value_id = "icon_4",
				pass_type = "texture",
				visible = false,
				style = {
					vertical_alignment = "bottom",
					horizontal_alignment = "right",
					offset = { 0, -11, 0 },
					size = HudElementTeamPlayerPanelSettings.throwable_size,
					color = UIHudSettings.color_tint_main_1,
				},
			},
		}, "toughness_bar")
	else
		instance.widget_definitions.team_throwable_icon = nil
		instance.widget_definitions.team_throwable_text = nil
	end

	if mod:get("health_text") or mod:get("toughness_text") then
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

	if mod:get("ability_cd_text") then
		instance.widget_definitions.ability_text = UIWidget.create_definition({
			{
				value_id = "text",
				style_id = "text",
				pass_type = "text",
				value = "",
				style = table.merge_recursive(table.clone(tough_text_style), {
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

	if mod:get("ability_cd_bar") then
		instance.widget_definitions.ability_bar = UIWidget.create_definition({
			{
				value = "content/ui/materials/backgrounds/default_square",
				style_id = "texture",
				pass_type = "texture",
				style = {
					vertical_alignment = "center",
					horizontal_alignment = "left",
					offset = {
						0,
						20,
						4,
					},
					size = { bar_size[1], 3 },
					color = UIHudSettings.color_tint_secondary_1,
				},
			},
			{
				value = "content/ui/materials/backgrounds/default_square",
				style_id = "texture_background",
				pass_type = "texture",
				style = {
					vertical_alignment = "center",
					horizontal_alignment = "left",
					offset = {
						0,
						20,
						0,
					},
					size = { bar_size[1], 2 },
					color = UIHudSettings.color_tint_0,
				},
			},
		}, "toughness_bar")
	else
		instance.widget_definitions.ability_bar = nil
	end

	if mod:get("ammo_text") or mod:get("peril_icon") then
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

	if mod:get("ammo_text") then
		instance.widget_definitions.numeric_ui_ammo_text = UIWidget.create_definition({
			{
				value_id = "text",
				style_id = "text",
				pass_type = "text",
				value = "<ammo_count>",
				style = {
					default_font_size = 17,
					font_size = 17,
					text_vertical_alignment = "center",
					text_horizontal_alignment = "left",
					vertical_alignment = "center",
					offset = { 60, -16, 3 },
					size = { bar_size[1] * 1.5, bar_size[2] },
					font_type = "machine_medium",--hud_body_font_settings.font_type,
					text_color = UIHudSettings.color_tint_main_2,
					default_text_color = UIHudSettings.color_tint_main_2,
					character_spacing = 0.03,
				},
			},
		}, "toughness_bar")
	else
		instance.widget_definitions.numeric_ui_ammo_text = nil
	end

	if mod:get("health_text") then
		instance.widget_definitions.health_text = UIWidget.create_definition({
			{
				value_id = "text_3",
				style_id = "text_3",
				pass_type = "text",
				value = "0",
				style = table.merge_recursive(table.clone(health_text_style), {
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
				style = table.merge_recursive(table.clone(health_text_style), {
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
				style = table.merge_recursive(table.clone(health_text_style), {
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

	if mod:get("toughness_text") then
		instance.widget_definitions.toughness_text = UIWidget.create_definition({
			{
				value_id = "text_3",
				style_id = "text_3",
				pass_type = "text",
				value = "0",
				style = table.merge_recursive(table.clone(tough_text_style), {
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
				style = table.merge_recursive(table.clone(tough_text_style), {
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
				style = table.merge_recursive(table.clone(tough_text_style), {
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

local TEAM_PANEL_DEF_PATH = "scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions"
local function hud_init_with_features(
	func,
	self,
	parent,
	draw_layer,
	start_scale,
	data,
	definition_path,
	definition_settings
)
	if data.player:is_human_controlled() then
		if definition_path == TEAM_PANEL_DEF_PATH then
			definition_settings.feature_list.health_text = mod:get("health_text")
			definition_settings.feature_list.toughness_text = mod:get("toughness_text")
		end
		definition_settings.feature_list.level = mod:get("level")
	end

	return func(self, parent, draw_layer, start_scale, data, definition_path, definition_settings)
end

local function update_numericui_ability_cd(self, player, ability_bar_widget, ability_text_widget, ability_component, dt)
	if not ability_cooldown_timer[player:name()] then
		ability_cooldown_timer[player:name()] = 0
	end

	local hide_widgets = (self._show_as_dead or self._dead or self._hogtied)
	local show_ability_text = (mod:get("ability_cd_text") and ability_text_widget)
	local show_ability_bar = (mod:get("ability_cd_bar") and ability_bar_widget)

	if hide_widgets then
		if show_ability_text then
			ability_text_widget.dirty = ability_text_widget.visible
			ability_text_widget.visible = false
		end

		if show_ability_bar then
			ability_bar_widget.dirty = ability_bar_widget.visible
			ability_bar_widget.visible = false
		end

		return
	end

	if ability_component.num_charges > 0 and ability_cooldown_timer[player:name()] > 0 then
		ability_cooldown_timer[player:name()] = 0

		if show_ability_text then
			ability_text_widget.visible = false
			ability_text_widget.dirty = true
		end

		if show_ability_bar then
			ability_bar_widget.style.texture.color = UIHudSettings.color_tint_secondary_1
			ability_bar_widget.style.texture.size[1] = bar_size[1]
			ability_bar_widget.dirty = true
		end
	elseif ability_component.num_charges > 0 and ability_cooldown_timer[player:name()] == 0 then
		if show_ability_text then
			if show_ability_text.visible then
				show_ability_text.visible = false
				show_ability_text.dirty = true
			end
		end

		if show_ability_bar then
			if not ability_bar_widget.visible then
				ability_bar_widget.visible = true
				ability_bar_widget.dirty = true
			end

			if ability_bar_widget.style.texture.size[1] ~= bar_size[1] then
				ability_bar_widget.style.texture.color = UIHudSettings.color_tint_secondary_1
				ability_bar_widget.style.texture.size[1] = bar_size[1]
				ability_bar_widget.dirty = true
			end
		end
	elseif
		(ability_cooldown_timer[player:name()] == 0)
		or (ability_cooldown_timer[player:name()] > ability_max_cooldown[player:name()])
	then
		local fixed_frame_t = FixedFrame.get_latest_fixed_time()
		local time_remaining = math.max(ability_component.cooldown - fixed_frame_t, 0)
		ability_max_cooldown[player:name()] = time_remaining
		ability_cooldown_timer[player:name()] = dt

		if show_ability_text then
			ability_text_widget.visible = true
			ability_text_widget.content.text = string.format("%03d", time_remaining)
			ability_text_widget.dirty = true
		end

		if show_ability_bar then
			ability_bar_widget.style.texture.color = Color.terminal_background_gradient_selected(255, true)
			ability_bar_widget.style.texture.size[1] = bar_size[1]
				* (ability_cooldown_timer[player:name()] / ability_max_cooldown[player:name()])
			ability_bar_widget.visible = true
			ability_bar_widget.dirty = true
		end
	elseif ability_cooldown_timer[player:name()] > 0 then
		ability_cooldown_timer[player:name()] = ability_cooldown_timer[player:name()] + dt

		if show_ability_text then
			local cd_timer = ability_max_cooldown[player:name()] - ability_cooldown_timer[player:name()]
			ability_text_widget.content.text = string.format("%03d", cd_timer)
			ability_text_widget.dirty = true
		end

		if show_ability_bar then
			ability_bar_widget.style.texture.color = Color.terminal_background_gradient_selected(255, true)
			local cd_progress = math.clamp(
				ability_cooldown_timer[player:name()] / ability_max_cooldown[player:name()],
				0,
				1.0
			)
			ability_bar_widget.style.texture.size[1] = bar_size[1] * cd_progress
			ability_bar_widget.dirty = true
		end
	end
end

mod:hook("HudElementPlayerPanelBase", "init", hud_init_with_features)

mod:hook_safe("HudElementPlayerPanelBase", "destroy", function(self)
	if not self._data.player:is_human_controlled() then
		return
	end

	local player_extensions = self:_player_extensions(self._data.player)

	if mod:get("ability_cd_bar") or mod:get("ability_cd_text") then
		local ability_text_widget = self._widgets_by_name.ability_text
		local ability_bar_widget = self._widgets_by_name.ability_bar

		if player_extensions then
			local unit_data_extension = player_extensions.unit_data
			if unit_data_extension then
				local ability_component = unit_data_extension:read_component("combat_ability")
				ability_cooldown_timer[self._data.player:name()] = nil
				if ability_component then
					ability_max_cooldown[self._data.player:name()] = nil
				end
			end
		end

		if mod:get("ability_cd_text") and ability_text_widget then
			self._widgets_by_name.ability_text.visible = false
			self._widgets_by_name.ability_text.dirty = true
		end

		if mod:get("ability_cd_bar") and ability_bar_widget then
			self._widgets_by_name.ability_bar_widget.visible = false
			self._widgets_by_name.ability_bar_widget.dirty = true
		end
	end
end)

local function update_numericui_player_features(func, self, dt, t, player, ui_renderer)
	func(self, dt, t, player, ui_renderer)

	if not player:is_human_controlled() then
		return
	end

	local ammo_text_widget = self._widgets_by_name.numeric_ui_ammo_text
	local peril_icon_widget = self._widgets_by_name.numeric_ui_peril_icon
	local extensions = self:_player_extensions(player)
	local unit_data_extension = extensions and extensions.unit_data

	if ammo_text_widget then
		local peril_color = nil
		local warp_charge_level = nil

		if unit_data_extension then
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

				if mod:get("peril_icon") and peril_color ~= peril_icon_widget.style.icon_text.text_color then
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
					local max_clip = inventory_component.max_ammunition_clip or 0
					local max_reserve = inventory_component.max_ammunition_reserve or 0
					local current_clip = inventory_component.current_ammunition_clip or 0
					local current_reserve = inventory_component.current_ammunition_reserve or 0
					total_current_ammo = total_current_ammo + current_clip + current_reserve
					total_max_ammo = total_max_ammo + max_clip + max_reserve
				end
			end

			if total_max_ammo == 0 or self._show_as_dead or self._dead or self._hogtied then
				-- No ammo or dead
				ammo_text_widget.content.text = ""
			elseif
				total_max_ammo == 0
				and (peril_icon_widget and peril_icon_widget.visible)
				and mod:get("peril_text")
			then
				-- Ammo text as peril percent
				ammo_text_widget.content.text = string.format("%1d%%", math.round(warp_charge_level * 100))
				ammo_text_widget.style.text.text_color = peril_color
			else
				-- Ammo
				if mod:get("ammo_as_percent") then
					ammo_text_widget.content.text = string.format("%1d%%", (total_current_ammo / total_max_ammo) * 100)
				else
					ammo_text_widget.content.text = string.format("%1d/%1d", total_current_ammo, total_max_ammo)
				end
				ammo_text_widget.style.text.text_color = self._widgets_by_name.ammo_status.style.ammo.color
			end
			ammo_text_widget.dirty = true
		end
	end

	if mod:get("ability_cd_text") or mod:get("ability_cd_bar") then
		if extensions then
			local ability_component = unit_data_extension:read_component("combat_ability")
			update_numericui_ability_cd(
				self,
				player,
				self._widgets_by_name.ability_bar,
				self._widgets_by_name.ability_text,
				ability_component,
				dt
			)
		end
	end
end

mod:hook("HudElementPersonalPlayerPanel", "_update_player_features", update_numericui_player_features)
mod:hook("HudElementTeamPlayerPanel", "_update_player_features", update_numericui_player_features)

mod:hook_safe("HudElementTeamPlayerPanel", "init", function(self, _parent, _draw_layer, _start_scale, data)
	if not data.player:is_human_controlled() then
		if self._widgets_by_name.numeric_ui_ammo_text then
			self._widgets_by_name.numeric_ui_ammo_text.content.text = " "
		end

		if self._widgets_by_name.ability_bar then
			self._widgets_by_name.ability_bar.visible = false
		end

		if self._widgets_by_name.team_throwable_icon then
			self._widgets_by_name.team_throwable_icon.visible = false
		end

		return
	end

	local player_extensions = self:_player_extensions(data.player)

	if player_extensions then
		
		local ability_extension = player_extensions.ability
		local unit_data_extension = player_extensions.unit_data

		if ability_extension and unit_data_extension and mod:get("grenades_count") then
			local archetype = unit_data_extension:archetype_name()
			local throwable_size = HudElementTeamPlayerPanelSettings.throwable_size

			--shift all top icons, remove old grenade
			self._widgets_by_name.throwable.visible = false
			self._widgets_by_name.throwable.dirty = true
			
			if self._widgets_by_name.ammo_status then
				self._widgets_by_name.ammo_status.style.ammo.offset[1] = self._widgets_by_name.ammo_status.style.ammo.offset[1] - throwable_size[1]
			end

			if self._widgets_by_name.pocketable then
				self._widgets_by_name.pocketable.style.texture.offset[1] = self._widgets_by_name.pocketable.style.texture.offset[1] - throwable_size[1]
			end

			if self._widgets_by_name.numeric_ui_ammo_text then
				self._widgets_by_name.numeric_ui_ammo_text.style.text.offset[1] = self._widgets_by_name.numeric_ui_ammo_text.style.text.offset[1] - throwable_size[1]
			end
			self.prev_grenade_charges = nil
							
			if archetype ~= "psyker" then
				
				local max_throwables_charges = ability_extension:max_ability_charges("grenade_ability") or 1
				local remaining_throwables_charges = ability_extension:remaining_ability_charges("grenade_ability") or 0
				local remaining_throwable_ratio = 1

				if max_throwables_charges ~= 0 then
					remaining_throwable_ratio = remaining_throwables_charges/max_throwables_charges
				end

				local grenades_count_format = mod:get("grenades_count_format")
				local empty_thowable_color = UIHudSettings.color_tint_main_3
				local throwable_color = nil

				if remaining_throwable_ratio == 0 then
					throwable_color = UIHudSettings.color_tint_ammo_high
					empty_thowable_color = Color.dark_red(255, true)
				elseif remaining_throwable_ratio <= .49 then
					throwable_color = UIHudSettings.color_tint_ammo_medium
				elseif remaining_throwable_ratio <= .74 then
					throwable_color = UIHudSettings.color_tint_ammo_low
				else
					throwable_color = UIHudSettings.color_tint_main_1
				end

				if grenades_count_format == "icons" then
					self._widgets_by_name.team_throwable_text.visible = false
					local throwable_icons_widget = self._widgets_by_name.team_throwable_icon
					local icon_gap = 3
					local x_offset = 0

					for i = 1, max_throwables_charges do
						
						throwable_icons_widget.style["icon_"..i].size = { 13, 14 }
						throwable_icons_widget.style["icon_"..i].offset[1] = throwable_icons_widget.style["icon_"..i].offset[1] - x_offset
						
						x_offset = x_offset + throwable_size[1] - icon_gap

						if i > remaining_throwables_charges then
							throwable_icons_widget.style["icon_"..i].color = empty_thowable_color
						else
							throwable_icons_widget.style["icon_"..i].color = throwable_color
						end

						throwable_icons_widget.content["icon_"..i] = "content/ui/materials/hud/icons/party_throwable"
					end

					throwable_icons_widget.visible = true
					throwable_icons_widget.dirty = true

				elseif grenades_count_format == "number" then
					self._widgets_by_name.team_throwable_icon.visible = false
					local throwable_number_widget = self._widgets_by_name.team_throwable_text
					local throwable_widget = self._widgets_by_name.throwable

					if archetype ~= "psyker" then
						throwable_widget.visible = true
						throwable_widget.style.texture.offset[1] = 135
						throwable_widget.style.text_color = throwable_color	
						throwable_number_widget.style.text.text_color = throwable_color
						throwable_number_widget.content.text = remaining_throwables_charges .. "/" .. max_throwables_charges
						
					end

					throwable_number_widget.dirty = true
					throwable_widget.dirty = true
				end

				self.prev_grenade_charges = remaining_throwables_charges
			end
		end

		
		if unit_data_extension then
			if mod:get("ability_cd_bar") or mod:get("ability_cd_text") then
				local ability_component = unit_data_extension:read_component("combat_ability")
				ability_cooldown_timer[data.player:name()] = 0

				if ability_component then
					local time = Managers.time:time("gameplay")
					local time_remaining = ability_component.cooldown - time
					ability_max_cooldown[data.player:name()] = time_remaining
				end
			end

			local archetype = unit_data_extension:archetype_name()
			local peril_icon_widget = self._widgets_by_name.numeric_ui_peril_icon

			if mod:get("peril_icon") then
				peril_icon_widget.content.icon_text = "" -- this boxed questionmark is the character for the peril icon
				peril_icon_widget.visible = (archetype == "psyker")
			elseif mod:get("ammo_text") then
				peril_icon_widget.content.icon_text = ""
				peril_icon_widget.visible = (archetype == "psyker") -- I use the "visible" flag to determine if it's a psyker
			end
		end
	end
end)
