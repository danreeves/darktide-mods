local mod = get_mod("NumericUI")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local LobbyViewFontStyle = require("scripts/ui/views/lobby_view/lobby_view_font_style")
local Missions = require("scripts/settings/mission/mission_templates")
local MissionTypes = require("scripts/settings/mission/mission_types")
local Zones = require("scripts/settings/zones/zones")
local Circumstances = require("scripts/settings/circumstance/circumstance_templates")

mod:hook_require("scripts/ui/views/mission_intro_view/mission_intro_view_definitions", function(instance)
	local top_scenegraph = nil
	for k, _ in pairs(instance.scenegraph_definition) do
		top_scenegraph = k
		break
	end

	instance.scenegraph_definition.mission_title = {
		vertical_alignment = "top",
		parent = top_scenegraph,
		horizontal_alignment = "left",
		size = {
			1200,
			100,
		},
		position = {
			100,
			65,
			100,
		},
	}

	instance.widget_definitions.mission_title = UIWidget.create_definition({
		{
			value_id = "title",
			style_id = "title",
			pass_type = "text",
			value = "",
			style = LobbyViewFontStyle.title_text_style,
		},
		{
			value = "content/ui/materials/dividers/skull_rendered_left_01",
			style_id = "divider",
			pass_type = "texture",
			style = {
				vertical_alignment = "center",
				size = {
					1200,
					18,
				},
			},
		},
		{
			value_id = "sub_title",
			style_id = "sub_title",
			pass_type = "text",
			value = "",
			style = LobbyViewFontStyle.sub_title_text_style,
		},
	}, "mission_title")
end)

local function draw_mission_title(self)
	if not Managers.mechanism._mechanism then
		return
	end
	local mechanism_data = Managers.mechanism._mechanism._mechanism_data
	local mission_settings = Missions[mechanism_data.mission_name]

	if mission_settings then
		local mission_display_name = mission_settings.mission_name
		local zone_name = mission_settings.zone_id
		local zone_info = Zones[zone_name]
		local zone_display_name = zone_info and zone_info.name
		local mission_type = MissionTypes[mission_settings.mission_type]
		local mission_type_name = mission_type and mission_type.name
		local circumstance_name = nil

		if mechanism_data.circumstance_name ~= "default" then
			circumstance_name = Circumstances[mechanism_data.circumstance_name].ui
					and self:_localize(
						Circumstances[mechanism_data.circumstance_name].ui.display_name
					)
				or mechanism_data.circumstance_name
		end

		local sub_title = mission_type_name and self:_localize(mission_type_name) or ""

		if zone_display_name then
			sub_title = sub_title .. " · " .. self:_localize(zone_display_name) or sub_title
		end

		if circumstance_name then
			sub_title = sub_title .. " · " .. circumstance_name or sub_title
		end

		local widgets_by_name = self._widgets_by_name
		widgets_by_name.mission_title.content.title = mission_display_name and self:_localize(mission_display_name)
			or "N/A"
		widgets_by_name.mission_title.content.sub_title = sub_title or "N/A"
		local title_width = self:_text_size(
			widgets_by_name.mission_title.content.title,
			widgets_by_name.mission_title.style.title.font_type,
			widgets_by_name.mission_title.style.title.font_size
		)
		local end_margin = 10
		widgets_by_name.mission_title.style.divider.size[1] = title_width + end_margin
	end
end

mod:hook_origin("MissionIntroView", "draw", function(self, dt, t, input_service, layer)
	if not mod:get("mission_title_on_intro") then
		self._widgets_by_name.mission_title.visible = false
		self._widgets_by_name.mission_title.dirty = true
	else
		self._widgets_by_name.mission_title.visible = true
		self._widgets_by_name.mission_title.dirty = true
	end

	draw_mission_title(self)

	local render_scale = self._render_scale
	local render_settings = self._render_settings
	local ui_renderer = self._ui_renderer
	render_settings.start_layer = layer
	render_settings.scale = render_scale
	render_settings.inverse_scale = render_scale and 1 / render_scale
	local ui_scenegraph = self._ui_scenegraph

	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, render_settings)
	self:_draw_widgets(dt, t, input_service, ui_renderer)
	UIRenderer.end_pass(ui_renderer)
	self:_draw_elements(dt, t, ui_renderer, render_settings, input_service)
	Managers.ui:render_loading_icon()
end)
