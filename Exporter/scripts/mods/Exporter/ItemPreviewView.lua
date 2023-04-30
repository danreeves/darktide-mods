local mod = get_mod("Exporter")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local BaseView = require("scripts/ui/views/base_view") -- needs to be required before creating a class from it
local generate_blueprints_function = require("scripts/ui/view_content_blueprints/item_blueprints")

local size = {
	1920,
	1080,
}
local item_blueprints = generate_blueprints_function(size)
local template = item_blueprints.item_icon

local BLACK = { 255, 0, 0, 0 }
local WHITE = { 255, 255, 255, 255 }

local passes = {
	{
		pass_type = "rect",
		style_id = "bg",
		style = {
			color = BLACK,
			size = {
				1920,
				1080,
			},
		},
	},
	{
		value_id = "icon",
		style_id = "icon",
		pass_type = "texture_uv",
		value = "content/ui/materials/icons/items/containers/item_container_landscape",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "center",
			material_values = {},
			size = {
				1920,
				1080,
			},
			offset = {
				0,
				0,
				0,
			},
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
		},
	},
}

local ItemPreviewView = class("ItemPreviewView", "BaseView")

function ItemPreviewView:init(settings, context)
	local definitions = {
		scenegraph_definition = {
			screen = UIWorkspaceSettings.screen,
		},
		widget_definitions = {},
	}
	ItemPreviewView.super.init(self, definitions, settings)

	self._item_master_list = Managers.backend.interfaces.master_data:items_cache():get_cached()
	self._next = pairs(self._item_master_list)
	self._current_item_key = nil
	self._weapon_widget = nil
	self._color_index = 1

	self._take_screenshot = false

	self:_next_item()
end

function ItemPreviewView:_next_item()
	local list = self._item_master_list
	local next = self._next
	local current_key = self._current_item_key

	local key = next(list, current_key)

	while not self:_is_wieldable(list[key]) do
		key = next(list, key)
		if key == nil then
			Managers.ui:close_view("item_preview_view")
			break
		end
	end

	self._current_item_key = key
end

function ItemPreviewView:_is_wieldable(item)
	if item.item_type == "WEAPON_SKIN" or item.item_type == "GADGET" then
		return true
	end
	if item.item_type == "WEAPON_MELEE" or item.item_type == "WEAPON_RANGED" then
		if item.slots and #item.slots > 0 then
			if item.archetypes and item.archetypes[1] ~= "npc" then
				return true
			end
		end
	end
	return false
end

function ItemPreviewView:_setup_weapon_widget()
	local optional_style = {}
	local scenegraph_id = "screen"
	local widget_definition = UIWidget.create_definition(passes, scenegraph_id, nil, size, optional_style)
	local weapon_widget = self:_create_widget("weapon_widget", widget_definition)

	self._weapon_widget = weapon_widget
end

function ItemPreviewView:_load_icon()
	local list = self._item_master_list
	local key = self._current_item_key
	local item = list[key]
	if not item then
		return
	end

	if not self._weapon_widget then
		self:_setup_weapon_widget()
	end

	local weapon_widget = self._weapon_widget

	template.unload_icon(self, weapon_widget, nil, self._ui_renderer)

	-- typo. missing ogryn in name
	if item.preview_item == "content/items/weapons/player/melee/powermaul_p1_m1" then
		item.preview_item = "content/items/weapons/player/melee/ogryn_powermaul_p1_m1"
	end

	-- og club p2 m2 not in item list
	local og_club_2 = "content/items/weapons/player/melee/ogryn_club_p1_m2"
	if item.preview_item == og_club_2 and not list[og_club_2] then
		item.preview_item = "content/items/weapons/player/melee/ogryn_club_p1_m1"
	end

	local config = {
		item = item,
	}

	-- template.init(self, weapon_widget, config, nil, nil, self._ui_renderer)
	template.load_icon(self, weapon_widget, config)
end

function ItemPreviewView:_screenshot()
	if self._current_item_key == nil then
		return
	end
	local key = self._current_item_key:gsub("/", "-")
	local user_dir = os.getenv("USERPROFILE")
	local color = self._color_index % 2 == 0 and "white" or "black"
	local path = string.format("%s\\Desktop\\images\\%s_%s.dds", user_dir, key, color)
	Application.save_render_target("back_buffer", path)
end

function ItemPreviewView:_draw_widgets(dt, t, input_service, ui_renderer)
	ItemPreviewView.super._draw_widgets(self, dt, t, input_service, ui_renderer)

	if self._weapon_widget then
		UIWidget.draw(self._weapon_widget, ui_renderer)
	end
end

function ItemPreviewView:_advance_slide()
	self._color_index = self._color_index + 1

	if self._color_index % 2 == 0 then
		self._weapon_widget.style.bg.color = WHITE
	else
		self._weapon_widget.style.bg.color = BLACK
		self:_next_item()
		self:_load_icon()
	end
end

function ItemPreviewView:update(dt, t, input_service)
	if input_service:get("close_view") then
		Managers.ui:close_view("item_preview_view")
	end

	-- if input_service:get("next") then
	-- 	self:_screenshot()
	-- 	self:_advance_slide()
	-- end

	if not self._weapon_widget then
		self:_load_icon()
	end

	local widget = self._weapon_widget

	if self._take_screenshot then
		self._take_screenshot = false
		self:_screenshot()
		self:_advance_slide()
	else
		if widget.style.icon.material_values.use_placeholder_texture == 0 then
			self._take_screenshot = true
		end
	end

	return ItemPreviewView.super.update(self, dt, t, input_service)
end

return ItemPreviewView
