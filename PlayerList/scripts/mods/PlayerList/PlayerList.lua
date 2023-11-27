local mod = get_mod("PlayerList")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local ProfileUtils = require("scripts/utilities/profile_utils")
local Breeds = require("scripts/settings/breed/breeds")
local PlayerCharacterOptionsViewSettings =
	require("scripts/ui/views/player_character_options_view/player_character_options_view_settings")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local ContentBlueprints = require("scripts/ui/views/lobby_view/lobby_view_content_blueprints")
local CharacterSheet = require("scripts/utilities/character_sheet")
local TalentBuilderViewSettings = require("scripts/ui/views/talent_builder_view/talent_builder_view_settings")
local TalentLayoutParser = require("scripts/ui/views/talent_builder_view/utilities/talent_layout_parser")

local class_loadout = {
	ability = {},
	blitz = {},
	aura = {},
}
local loadout_presentation_order = {
	"ability",
	"blitz",
	"aura",
}
local loadout_to_type = {
	ability = "ability",
	blitz = "tactical",
	aura = "aura",
}

local portrait_size = { 150, 150 }
local function player_panel(scenegraph_id)
	local character_name_style = table.clone(UIFontSettings.body)
	character_name_style.text_horizontal_alignment = "center"
	character_name_style.text_vertical_alignment = "top"
	character_name_style.horizontal_alignment = "center"
	character_name_style.offset = {
		0,
		150,
		0,
	}

	local character_title_style = table.clone(UIFontSettings.body_small)
	character_title_style.text_horizontal_alignment = "center"
	character_title_style.text_vertical_alignment = "top"
	character_title_style.horizontal_alignment = "center"
	character_title_style.offset = {
		0,
		175,
		0,
	}
	return UIWidget.create_definition({
		{
			value_id = "character_insignia",
			style_id = "character_insignia",
			pass_type = "texture",
			value = "content/ui/materials/base/ui_default_base",
			style = {
				horizontal_alignment = "center",
				size = {
					40,
					100,
				},
				offset = {
					-85,
					0,
					2,
				},
				material_values = {},
			},
			visibility_function = function(_content, style)
				return not not style.material_values.texture_map
			end,
		},
		{
			pass_type = "texture",
			value_id = "character_portrait",
			style_id = "character_portrait",
			value = "content/ui/materials/icons/items/containers/item_container_landscape",
			style = {
				horizontal_alignment = "center",
				uvs = {
					{
						0,
						0,
					},
					{
						1,
						1,
					},
				},
				size = portrait_size,
				color = {
					255,
					255,
					255,
					255,
				},
				material_values = {},
			},
		},
		{
			style_id = "character_name",
			pass_type = "text",
			value = "",
			value_id = "character_name",
			style = character_name_style,
		},
		{
			style_id = "character_title",
			pass_type = "text",
			value = "",
			value_id = "character_title",
			style = character_title_style,
		},
	}, scenegraph_id)
end

local screen_size = UIWorkspaceSettings.screen.size
local player_list_size = { screen_size[1] * 0.6, screen_size[2] }
local player_panel_size = { player_list_size[1] / 3, player_list_size[2] * 0.8 }
mod:hook_require("scripts/ui/hud/elements/tactical_overlay/hud_element_tactical_overlay_definitions", function(instance)
	instance.scenegraph_definition.mod_player_list = {
		parent = "background",
		vertical_alignment = "center",
		horizontal_alignment = "right",
		size = player_list_size,
		position = { -screen_size[1] * 0.1, 0, 1 },
	}
	instance.scenegraph_definition.mod_player_list_1 = {
		parent = "mod_player_list",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = player_panel_size,
		position = { 0, 0, 1 },
	}
	instance.scenegraph_definition.mod_player_list_2 = {
		parent = "mod_player_list",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = player_panel_size,
		position = { 0, 0, 1 },
	}
	instance.scenegraph_definition.mod_player_list_3 = {
		parent = "mod_player_list",
		vertical_alignment = "center",
		horizontal_alignment = "right",
		size = player_panel_size,
		position = { 0, 0, 1 },
	}

	instance.widget_definitions.talent_tooltip = UIWidget.create_definition(
		{
			{
				pass_type = "rect",
				style = {
					color = {
						220,
						0,
						0,
						0,
					},
				},
			},
			{
				value = "content/ui/materials/backgrounds/default_square",
				style_id = "background",
				pass_type = "texture",
				style = {
					color = Color.terminal_background(nil, true),
				},
			},
			{
				value = "content/ui/materials/gradients/gradient_vertical",
				style_id = "background_gradient",
				pass_type = "texture",
				style = {
					vertical_alignment = "center",
					horizontal_alignment = "center",
					color = Color.terminal_background_gradient(180, true),
					offset = {
						0,
						0,
						1,
					},
				},
			},
			{
				value = "content/ui/materials/frames/dropshadow_medium",
				style_id = "outer_shadow",
				pass_type = "texture",
				style = {
					vertical_alignment = "center",
					horizontal_alignment = "center",
					scale_to_material = true,
					color = Color.black(200, true),
					size_addition = {
						20,
						20,
					},
					offset = {
						0,
						0,
						3,
					},
				},
			},
			{
				value = "content/ui/materials/frames/frame_tile_2px",
				style_id = "frame",
				pass_type = "texture",
				style = {
					vertical_alignment = "center",
					horizontal_alignment = "center",
					color = Color.terminal_frame(nil, true),
					offset = {
						0,
						0,
						2,
					},
				},
			},
			{
				value = "content/ui/materials/frames/frame_corner_2px",
				style_id = "corner",
				pass_type = "texture",
				style = {
					vertical_alignment = "center",
					horizontal_alignment = "center",
					color = Color.terminal_corner(nil, true),
					offset = {
						0,
						0,
						3,
					},
				},
			},
			{
				value_id = "title",
				pass_type = "text",
				style_id = "title",
				value = "n/a",
				style = {
					text_vertical_alignment = "center",
					horizontal_alignment = "center",
					font_size = 24,
					text_horizontal_alignment = "left",
					vertical_alignment = "top",
					font_type = "proxima_nova_bold",
					text_color = Color.terminal_text_header(255, true),
					color = {
						100,
						255,
						200,
						50,
					},
					size = {
						nil,
						0,
					},
					offset = {
						0,
						0,
						5,
					},
					size_addition = {
						-40,
						0,
					},
				},
			},
			{
				value_id = "description",
				pass_type = "text",
				style_id = "description",
				value = "n/a",
				style = {
					font_size = 20,
					text_vertical_alignment = "center",
					horizontal_alignment = "center",
					text_horizontal_alignment = "left",
					vertical_alignment = "top",
					font_type = "proxima_nova_bold",
					text_color = Color.terminal_text_body(255, true),
					size = {
						nil,
						0,
					},
					offset = {
						0,
						0,
						5,
					},
					color = {
						100,
						100,
						255,
						0,
					},
					size_addition = {
						-40,
						0,
					},
				},
			},
			{
				value_id = "talent_type_title",
				pass_type = "text",
				style_id = "talent_type_title",
				value = "",
				style = {
					font_size = 16,
					horizontal_alignment = "center",
					text_vertical_alignment = "center",
					text_horizontal_alignment = "left",
					vertical_alignment = "top",
					font_type = "proxima_nova_bold",
					text_color = Color.terminal_text_body_sub_header(255, true),
					size = {
						nil,
						0,
					},
					offset = {
						0,
						0,
						5,
					},
					size_addition = {
						-40,
						0,
					},
				},
			},
		},
		"mod_player_list",
		{
			visible = false,
		}
	)

	instance.widget_definitions.player_panel_1 = player_panel("mod_player_list_1")
	instance.widget_definitions.player_panel_2 = player_panel("mod_player_list_2")
	instance.widget_definitions.player_panel_3 = player_panel("mod_player_list_3")
end)

mod.slots = {}

function mod:_load_portrait_icon(slot, widget)
	mod:echo("_load_portrait_icon")
	local profile = slot.profile
	local load_cb = callback(self, "_cb_set_player_icon", widget)
	local unload_cb = callback(self, "_cb_unset_player_icon", widget)

	local slot_name = "inspect_pose"
	local profile_archetype = profile.archetype
	local archetype_name = profile_archetype.name
	local breed_name = profile_archetype and profile_archetype.breed or profile.breed
	local breed_settings = Breeds[breed_name]
	local animation_event_by_archetype = PlayerCharacterOptionsViewSettings.animation_event_by_archetype
	local animation_event = animation_event_by_archetype[archetype_name]
	local portrait_state_machine = breed_settings.portrait_state_machine
	local size_multiplier = 2
	local render_context = {
		camera_focus_slot_name = slot_name,
		state_machine = portrait_state_machine,
		animation_event = animation_event,
		size = {
			portrait_size[1] * size_multiplier,
			portrait_size[2] * size_multiplier,
		},
	}

	local icon_load_id = Managers.ui:load_profile_portrait(profile, load_cb, render_context, unload_cb)
	slot.icon_load_id = icon_load_id
	local loadout = profile.loadout
	local frame_item = loadout and loadout.slot_portrait_frame

	if frame_item then
		local cb = callback(self, "_cb_set_player_frame", widget)
		slot.frame_load_id = Managers.ui:load_item_icon(frame_item, cb)
	end

	local insignia_item = loadout and loadout.slot_insignia

	if insignia_item then
		local cb = callback(self, "_cb_set_player_insignia", widget)
		slot.insignia_load_id = Managers.ui:load_item_icon(insignia_item, cb)
	end
end

function mod:_cb_set_player_icon(widget, grid_index, rows, columns, render_target)
	mod:echo("_cb_set_player_icon")
	local material_values = widget.style.character_portrait.material_values
	material_values.use_placeholder_texture = 0
	material_values.rows = rows
	material_values.columns = columns
	material_values.grid_index = grid_index - 1
	material_values.use_render_target = 1
	material_values.render_target = render_target
end

function mod:_cb_unset_player_icon(widget)
	mod:echo("_cb_unset_player_icon")
	local material_values = widget.style.character_portrait.material_values
	material_values.use_placeholder_texture = 0
	material_values.rows = nil
	material_values.columns = nil
	material_values.grid_index = nil
	material_values.texture_icon = nil
	widget.content.character_portrait = "content/ui/materials/base/ui_portrait_frame_base_no_render"
end

function mod:_cb_set_player_frame(widget, item)
	mod:echo("_cb_set_player_frame")
	local material_values = widget.style.character_portrait.material_values
	material_values.portrait_frame_texture = item.icon
end

function mod:_cb_set_player_insignia(widget, item)
	widget.dirty = true
	widget.style.character_insignia.material_values.texture_map = item.icon
end

function mod:_sync_player_slots(unique_id, player, tactical_overlay)
	local _i, slot = table.find_by_key(mod.slots, "unique_id", unique_id)
	if not slot then
		local first_available_slot = #mod.slots + 1
		if first_available_slot <= 3 then
			mod.slots[first_available_slot] = {
				index = first_available_slot,
				unique_id = unique_id,
				profile = player:profile(),
				talent_widgets = {},
			}
			mod:_setup_talents_widgets(tactical_overlay, mod.slots[first_available_slot])
		end
	end
end

local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIFonts = require("scripts/managers/ui/ui_fonts")
local function _get_text_height(ui_renderer, text, text_style, optional_text_size)
	local text_options = UIFonts.get_font_options_by_style(text_style)
	local text_height = UIRenderer.text_height(
		ui_renderer,
		text,
		text_style.font_type,
		text_style.font_size,
		optional_text_size or text_style.size,
		text_options
	)

	return text_height
end

function mod:_update_slots(tactical_overlay, ui_renderer)
	local widgets_by_name = tactical_overlay._widgets_by_name

	for i, slot in ipairs(mod.slots) do
		local widget_name = "player_panel_" .. i
		local widget = widgets_by_name[widget_name]
		if widget then
			if not slot.icon_load_id then
				mod:_load_portrait_icon(slot, widget)
			end
			local profile = slot.profile

			local character_name = ProfileUtils.character_name(profile)
			local character_level = tostring(profile.current_level) .. " "
			widget.content.character_name = string.format("%s %s", character_level, character_name)

			local character_title = ProfileUtils.character_title(profile)
			widget.content.character_title = character_title

			local hovered_slot, hovered_talent = nil

			for _, talent_widget in ipairs(slot.talent_widgets) do
				UIWidget.draw(talent_widget, ui_renderer)

				local is_hover = not hovered_slot
					and talent_widget.content.hotspot
					and (talent_widget.content.hotspot.is_hover or talent_widget.content.hotspot.is_selected)

				if is_hover then
					hovered_slot = slot

					CharacterSheet.class_loadout(profile, class_loadout)

					local loadout_id = talent_widget.content.loadout_id
					local loadout = class_loadout[loadout_id]
					hovered_talent = {
						talent = loadout.talent,
						loadout_id = loadout_id,
						slot = i,
					}
				end
			end

			local talent_tooltip = widgets_by_name.talent_tooltip
			if hovered_talent then
				local loadout = hovered_talent
				self._hovered_slot_talent_data = loadout

				local content = talent_tooltip.content
				local style = talent_tooltip.style
				content.title = "title"
				content.description = "<<UNASSIGNED TALENT NODE>>"
				local talent = hovered_talent.talent

				if talent then
					mod:echo("hovered talent")
					local dummy_tooltip_text_size = {
						400,
						20,
					}
					local text_vertical_offset = 14
					local points_spent = 1
					local node_type = loadout_to_type[hovered_talent.loadout_id]
					local node_settings = TalentBuilderViewSettings.settings_by_node_type[node_type]
					content.talent_type_title = Localize(node_settings.display_name) or ""
					local talent_type_title_height = _get_text_height(
						ui_renderer,
						content.talent_type_title,
						style.talent_type_title,
						dummy_tooltip_text_size
					)
					style.talent_type_title.offset[2] = text_vertical_offset
					style.talent_type_title.size[2] = talent_type_title_height
					text_vertical_offset = text_vertical_offset + talent_type_title_height
					local description =
						TalentLayoutParser.talent_description(talent, points_spent, Color.ui_terminal(255, true))
					local localized_title = tactical_overlay:_localize(talent.display_name)
					content.title = localized_title
					content.description = description
					-- local widget_width, _ =
					-- tactical_overlay:_scenegraph_size(talent_tooltip.scenegraph_id, tactical_overlay._ui_scenegraph)
					local text_size_addition = style.title.size_addition
					local widget_width = 250
					dummy_tooltip_text_size[1] = widget_width + text_size_addition[1]
					local title_height =
						_get_text_height(ui_renderer, content.title, style.title, dummy_tooltip_text_size)
					style.title.offset[2] = text_vertical_offset
					style.title.size[2] = title_height
					text_vertical_offset = text_vertical_offset + title_height + 10
					local description_height =
						_get_text_height(ui_renderer, content.description, style.description, dummy_tooltip_text_size)
					style.description.offset[2] = text_vertical_offset
					style.description.size[2] = description_height
					text_vertical_offset = text_vertical_offset + description_height
					content.exculsive_group_description = ""
					text_vertical_offset = text_vertical_offset + 20

					-- self:_set_scenegraph_size(widget.scenegraph_id, nil, text_vertical_offset, self._ui_scenegraph)
				end
				-- self:_update_talent_tooltip_position()

				talent_tooltip.content.visible = true
				talent_tooltip.alpha_multiplier = 1
			else
				-- Hide the current tooltip
				-- talent_tooltip.content.visible = false
				-- talent_tooltip.alpha_multiplier = 0
			end
		end
	end
end

function mod:_setup_talents_widgets(tactical_overlay, slot)
	local search_slot = {
		{
			id = "talent_1",
			size = ContentBlueprints.talent.size,
			offset_height = 200,
			offset_width = (player_panel_size[1] / 2)
				- (ContentBlueprints.talent.size[1] / 2)
				- ContentBlueprints.talent.size[1],
		},
		{
			id = "talent_2",
			size = ContentBlueprints.talent.size,
			offset_height = 200,
			offset_width = (player_panel_size[1] / 2) - (ContentBlueprints.talent.size[1] / 2),
		},
		{
			id = "talent_3",
			size = ContentBlueprints.talent.size,
			offset_height = 200,
			offset_width = (player_panel_size[1] / 2)
				- (ContentBlueprints.talent.size[1] / 2)
				+ ContentBlueprints.talent.size[1],
		},
	}
	local scenegraph_id = "mod_player_list_" .. slot.index
	local profile = slot.profile

	for i = 1, #slot.talent_widgets do
		local talent_widgets = slot.talent_widgets[i]

		tactical_overlay:_unregister_widget_name(talent_widgets.name)
	end

	CharacterSheet.class_loadout(profile, class_loadout)

	local settings_by_node_type = TalentBuilderViewSettings.settings_by_node_type

	for i = 1, #search_slot do
		local data = search_slot[i]
		local loadout_id = loadout_presentation_order[i]
		local loadout = class_loadout[loadout_id]
		local node_type = loadout_to_type[loadout_id]
		local template = ContentBlueprints.talent
		local node_type_settings = settings_by_node_type[node_type]
		local config = {
			loadout = loadout,
			node_type_settings = node_type_settings,
			loadout_id = loadout_id,
		}
		local size = template.size or data.size
		local pass_template_function = template.pass_template_function
		local pass_template = pass_template_function and pass_template_function(self, config) or template.pass_template
		local optional_style = template.style or {}
		local widget_definition = pass_template
			and UIWidget.create_definition(pass_template, scenegraph_id, nil, size, optional_style)

		if widget_definition then
			local name_talent = string.format("slot_%s_%s", slot.index, data.id)
			local talent_widget = tactical_overlay:_create_widget(name_talent, widget_definition)
			local init = template.init

			if init then
				init(self, talent_widget, config)
			end

			talent_widget.original_offset = {
				data.offset_width,
				data.offset_height,
				0,
			}
			talent_widget.offset = {
				data.offset_width,
				data.offset_height,
				0,
			}
			slot.talent_widgets[i] = talent_widget
		end
	end
end

mod:hook_safe("HudElementTacticalOverlay", "init", function()
	mod:echo("init overlay")
	mod.slots = {}
end)

mod:hook_safe("HudElementTacticalOverlay", "update", function(self, dt, t, ui_renderer, render_settings, input_service)
	local input_manager = Managers.input
	local name = self.__class_name

	if self._active then
		if not input_manager:cursor_active() then
			input_manager:push_cursor(name)
			local position = Vector3(0.5, 0.5, 0)
			input_manager:set_cursor_position(name, position)
		end
	else
		if input_manager:cursor_active() then
			input_manager:pop_cursor(name)
		end
	end

	if self._active then
		local player_manager = Managers.player
		local players = player_manager:players()

		for unique_id, player in pairs(players) do
			mod:_sync_player_slots(unique_id, player, self)
		end

		mod:_update_slots(self, ui_renderer)
	end
end)
