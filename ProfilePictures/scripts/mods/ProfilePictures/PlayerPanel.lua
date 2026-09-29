local mod = get_mod("ProfilePictures")
local UIWidget = require("scripts/managers/ui/ui_widget")

local _apply_profile_image = mod.apply_profile_image
local location_enabled = mod.location_enabled
local player_panel_settings = mod.player_panel_settings

local hud_types = {
	"PersonalPlayerPanel",
	"PersonalPlayerPanelHub",
	"TeamPlayerPanel",
	"TeamPlayerPanelHub",
}

local DEFINITION_PATHS = {
	"scripts/ui/hud/elements/personal_player_panel/hud_element_personal_player_panel_definitions",
	"scripts/ui/hud/elements/personal_player_panel_hub/hud_element_personal_player_panel_hub_definitions",
	"scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions",
	"scripts/ui/hud/elements/team_player_panel_hub/hud_element_team_player_panel_hub_definitions",
}

local PORTRAIT_MATERIAL = "content/ui/materials/base/ui_portrait_frame_base"
-- Vanilla's portrait without a render. It still draws a skull placeholder in the middle, so it's no frame layer.
local NO_RENDER_MATERIAL = "content/ui/materials/base/ui_portrait_frame_base_no_render"

-- An older frame's texture is see-through in the middle, so drawn on its own it frames the picture layer below
local FRAME_TEXTURE_MATERIAL = "content/ui/materials/base/ui_default_base"
local DEFAULT_FRAME_TEXTURE = "content/ui/textures/nameplates/portrait_frames/default"

-- The portrait material only draws the middle of its quad, about x 10-80 and y 12-89 of 90x100
local WINDOW_WIDTH = 70 / 90
local WINDOW_TOP = 12 / 100
local WINDOW_HEIGHT = 77 / 100

-- Just narrower than tall, so the middle the material draws comes out square and the picture isn't stretched
local PICTURE_ASPECT = WINDOW_HEIGHT / WINDOW_WIDTH

-- Vanilla draws the frame at 0 and the status icon above it, so the picture and the background square behind it go below
local PICTURE_Z = -1
local BACKGROUND_Z = -2

local WHITE = { 255, 255, 255, 255 }

-- Panels whose portrait is split, so a settings change reaches the ones on screen. Weak, so it never keeps a destroyed panel alive.
local split_panels = setmetatable({}, { __mode = "k" })

-- Reads nothing but its arguments, so a copy that a previous load left in the cached definitions still works. The square only fills in around a smaller picture inside the frame, so it goes with the frame, whether this mod or HUD Tweaker hides that.
local function _background_visible(_content, style)
	return style.color[1] > 0 and style.parent.texture.visible ~= false
end

-- The vanilla pass becomes the frame layer, and these go under it. HUD Tweaker only edits style fields that already exist, so both define their size and offset.
local function _add_profile_picture_passes(instance)
	local player_icon = instance.widget_definitions.player_icon

	-- The definitions stay cached across a mod reload, so only add the passes once
	if not player_icon or player_icon.style.profile_picture then
		return
	end

	local icon_size = instance.scenegraph_definition.player_icon.size

	UIWidget.add_definition_pass(player_icon, {
		pass_type = "rect",
		style_id = "profile_picture_background",
		visibility_function = _background_visible,
		style = {
			color = { 0, 0, 0, 0 },
			size = { icon_size[1], icon_size[2] },
			offset = { 0, 0, BACKGROUND_Z },
		},
	})
	UIWidget.add_definition_pass(player_icon, {
		pass_type = "texture",
		style_id = "profile_picture",
		value_id = "profile_picture",
		value = NO_RENDER_MATERIAL,
		style = {
			-- The frame layer draws the frame, so this one keeps its frame slot empty
			material_values = {
				portrait_frame_texture = "",
				use_placeholder_texture = 0,
			},
			-- Starts transparent, so a panel draws as vanilla until it has a portrait to split off
			color = { 0, 255, 255, 255 },
			size = { icon_size[1], icon_size[2] },
			offset = { 0, 0, PICTURE_Z },
		},
	})
end

-- The panel's player icon, while the panel is alive and the icon has the picture layer
local function _player_icon_widget(self)
	if self.__deleted or self.destroyed then
		return nil
	end

	local widgets_by_name = self._widgets_by_name
	local widget = widgets_by_name and widgets_by_name.player_icon

	if widget and widget.style.profile_picture then
		return widget
	end

	return nil
end

local function _holds_portrait(widget)
	return widget.style.profile_picture.material_values.texture_icon ~= nil
end

local function _copy_color(destination, source)
	destination[1] = source[1]
	destination[2] = source[2]
	destination[3] = source[3]
	destination[4] = source[4]
end

-- Leaves only the frame on the vanilla pass. An older frame and a bot's default frame are drawn from their texture, which is see-through in the middle. A newer frame is a material of its own and only loses the portrait. Vanilla's shading for a downed or dead player only ever darkens the portrait, so the frame keeps its colour.
local function _strip_frame_layer(widget)
	local content = widget.content
	local material_values = widget.style.texture.material_values
	local texture = content.texture

	if texture == PORTRAIT_MATERIAL or texture == NO_RENDER_MATERIAL or texture == FRAME_TEXTURE_MATERIAL then
		content.texture = FRAME_TEXTURE_MATERIAL
		-- Vanilla keeps writing the frame into portrait_frame_texture, which the plain material doesn't have, so it moves over each time
		material_values.texture_map = material_values.portrait_frame_texture or material_values.texture_map or DEFAULT_FRAME_TEXTURE
		material_values.portrait_frame_texture = nil
		-- Vanilla's shading lives on in the picture layer, so none of it reaches the frame
		material_values.desaturation = 0
		material_values.intensity = 1
	else
		material_values.texture_map = nil
	end

	material_values.use_placeholder_texture = 0
	material_values.texture_icon = nil
end

-- Hands the vanilla pass back the portrait material vanilla shows without a render, with the frame where vanilla keeps it
local function _restore_frame_layer(widget)
	local content = widget.content
	local style = widget.style
	local material_values = style.texture.material_values
	local picture_values = style.profile_picture.material_values

	if content.texture == FRAME_TEXTURE_MATERIAL then
		content.texture = NO_RENDER_MATERIAL
	end

	-- The picture layer holds vanilla's shading, which the plain frame had set aside
	material_values.desaturation = picture_values.desaturation
	material_values.intensity = picture_values.intensity

	-- Vanilla may already have put its own material back, which still needs the frame
	if material_values.texture_map then
		material_values.portrait_frame_texture = material_values.portrait_frame_texture or material_values.texture_map
		material_values.texture_map = nil
	end
end

-- A character render keeps the panel's own quad, as vanilla draws it
local function _set_render_geometry(self, style)
	local icon_size = self._ui_scenegraph.player_icon.size
	local picture_style = style.profile_picture
	local size = picture_style.size
	local offset = picture_style.offset

	size[1] = icon_size[1]
	size[2] = icon_size[2]
	offset[1] = 0
	offset[2] = 0
end

-- A picture gets a centred layer the height of the panel's quad, scaled by Profile picture size. The background square is the middle a full size picture draws.
local function _set_picture_geometry(self, style)
	local icon_size = self._ui_scenegraph.player_icon.size
	local icon_width = icon_size[1]
	local icon_height = icon_size[2]
	local height = icon_height * player_panel_settings.picture_scale
	local width = height * PICTURE_ASPECT
	local picture_style = style.profile_picture
	local size = picture_style.size
	local offset = picture_style.offset

	size[1] = width
	size[2] = height
	offset[1] = (icon_width - width) * 0.5
	offset[2] = (icon_height - height) * 0.5

	local background_style = style.profile_picture_background
	local side = icon_height * WINDOW_HEIGHT

	size = background_style.size
	offset = background_style.offset
	size[1] = side
	size[2] = side
	offset[1] = (icon_width - side) * 0.5
	offset[2] = icon_height * WINDOW_TOP
end

-- The chosen colour, greyed and darkened the way the portrait material shades the picture of a downed or dead player
local function _set_background_color(style)
	local picture_values = style.profile_picture.material_values
	local desaturation = picture_values.desaturation or 0
	local intensity = picture_values.intensity or 1
	local background_color = player_panel_settings.background_color
	local red = background_color[2]
	local green = background_color[3]
	local blue = background_color[4]
	local grey = (red + green + blue) / 3
	local color = style.profile_picture_background.color

	color[1] = 255
	color[2] = (red + (grey - red) * desaturation) * intensity
	color[3] = (green + (grey - green) * desaturation) * intensity
	color[4] = (blue + (grey - blue) * desaturation) * intensity
end

local function _finish_split(self, widget)
	widget.style.texture.visible = player_panel_settings.portrait_frames
	split_panels[self] = true
	widget.dirty = true
end

-- Moves the character render vanilla just gave the frame layer onto the picture layer, keeping vanilla's quad and tint, so bots and players without a picture look as before
local function _show_render(self, widget)
	local style = widget.style
	local frame_style = style.texture
	local frame_values = frame_style.material_values
	local picture_style = style.profile_picture
	local picture_values = picture_style.material_values

	picture_values.use_placeholder_texture = 0
	picture_values.rows = frame_values.rows
	picture_values.columns = frame_values.columns
	picture_values.grid_index = frame_values.grid_index
	picture_values.texture_icon = frame_values.texture_icon
	widget.content.profile_picture = PORTRAIT_MATERIAL
	_copy_color(picture_style.color, frame_style.color)
	style.profile_picture_background.color[1] = 0

	_set_render_geometry(self, style)
	_strip_frame_layer(widget)
	_finish_split(self, widget)
end

-- The picture is square and drawn in a layer of its own, so it isn't stretched, and the tint of your own mission panel only reaches the frame
local function _show_picture(self, widget, texture)
	local style = widget.style

	_apply_profile_image(widget, "profile_picture", texture)

	widget.content.profile_picture = PORTRAIT_MATERIAL
	_copy_color(style.profile_picture.color, WHITE)

	_set_picture_geometry(self, style)
	_set_background_color(style)
	_strip_frame_layer(widget)
	_finish_split(self, widget)
end

-- Switching to the material that skips the portrait gives the pass a fresh material, so no render target stays referenced
local function _clear_picture_layer(widget)
	local style = widget.style
	local picture_style = style.profile_picture

	widget.content.profile_picture = NO_RENDER_MATERIAL
	picture_style.material_values.texture_icon = nil
	picture_style.color[1] = 0
	style.profile_picture_background.color[1] = 0
	widget.dirty = true
end

local function _load_portrait_icon(self)
	if not location_enabled.player_hud then
		return
	end

	local player = self._player
	local player_info = mod.player_info_for_player(player)

	mod.load_profile_image(player_info, function(texture)
		if self.__deleted or self.destroyed or self._player ~= player then
			return
		end

		self._profile_picture_texture = texture

		local widget = _player_icon_widget(self)

		if widget then
			_show_picture(self, widget, texture)
		end
	end, true)
end

-- Vanilla puts the character render on the frame layer once it finishes loading, so split it off again
local function _cb_set_player_icon(self)
	local widget = _player_icon_widget(self)

	if not widget then
		return
	end

	local texture = self._profile_picture_texture

	if texture then
		_show_picture(self, widget, texture)
	else
		_show_render(self, widget)
	end
end

-- Vanilla drops the render and puts its no-render material back on the frame layer. A profile picture stays, so the frame is taken off that material again, anything else goes with the render.
local function _cb_unset_player_icon(self)
	local widget = _player_icon_widget(self)

	if not widget then
		return
	end

	if self._profile_picture_texture then
		_strip_frame_layer(widget)
		widget.dirty = true
	else
		_clear_picture_layer(widget)
		_restore_frame_layer(widget)
	end
end

-- Runs at the start of every portrait load, so the previous player's picture never carries over. Until the next portrait lands the panel looks as vanilla's does while it loads.
local function _unload_portrait_icon(self)
	self._profile_picture_texture = nil

	local widget = _player_icon_widget(self)

	if widget then
		_clear_picture_layer(widget)
		_restore_frame_layer(widget)
	end
end

-- Vanilla rewrites the frame layer when a frame item loads or unloads, or a new portrait is requested, so take the portrait off it again while the picture layer holds one
local function _restrip_frame_layer(self)
	local widget = _player_icon_widget(self)

	if widget and _holds_portrait(widget) then
		_strip_frame_layer(widget)
		widget.dirty = true
	end
end

-- Vanilla greys the frame layer for a downed or dead player, so the picture layer and the background square follow it
local function _set_shadowing_portrait(self)
	local widget = _player_icon_widget(self)

	if not widget then
		return
	end

	local style = widget.style
	local frame_values = style.texture.material_values
	local picture_values = style.profile_picture.material_values

	picture_values.desaturation = frame_values.desaturation
	picture_values.intensity = frame_values.intensity

	if widget.content.texture == FRAME_TEXTURE_MATERIAL then
		frame_values.desaturation = 0
		frame_values.intensity = 1
	end

	if self._profile_picture_texture then
		_set_background_color(style)
	end

	widget.dirty = true
end

-- Portrait frames, Profile picture size and Profile picture background are plain style values here, so they reach the panels on screen straight away
function mod.refresh_player_panels()
	local portrait_frames = player_panel_settings.portrait_frames

	for panel in pairs(split_panels) do
		local widget = _player_icon_widget(panel)

		if widget then
			local style = widget.style

			style.texture.visible = portrait_frames

			if panel._profile_picture_texture then
				_set_picture_geometry(panel, style)
				_set_background_color(style)
			end

			widget.dirty = true
		else
			split_panels[panel] = nil
		end
	end
end

-- The hooks that keep the layers in step stop with the mod, so each split panel goes back to vanilla's single pass
function mod.merge_player_panel_layers()
	for panel in pairs(split_panels) do
		local widget = _player_icon_widget(panel)

		if widget then
			local style = widget.style
			local frame_style = style.texture

			_restore_frame_layer(widget)

			if _holds_portrait(widget) then
				local content = widget.content
				local frame_values = frame_style.material_values
				local picture_values = style.profile_picture.material_values

				if content.texture == NO_RENDER_MATERIAL then
					content.texture = PORTRAIT_MATERIAL
				end

				frame_values.use_placeholder_texture = 0
				frame_values.rows = picture_values.rows
				frame_values.columns = picture_values.columns
				frame_values.grid_index = picture_values.grid_index
				frame_values.texture_icon = picture_values.texture_icon
			end

			frame_style.visible = nil

			_clear_picture_layer(widget)
		end

		split_panels[panel] = nil
	end
end

for _, hud_type in ipairs(hud_types) do
	local class_name = "HudElement" .. hud_type

	mod:hook_safe(class_name, "_load_portrait_icon", _load_portrait_icon)
	mod:hook_safe(class_name, "_cb_set_player_icon", _cb_set_player_icon)
	mod:hook_safe(class_name, "_cb_unset_player_icon", _cb_unset_player_icon)
	mod:hook_safe(class_name, "_unload_portrait_icon", _unload_portrait_icon)
	mod:hook_safe(class_name, "_request_player_icon", _restrip_frame_layer)
	mod:hook_safe(class_name, "_cb_set_player_frame", _restrip_frame_layer)
	mod:hook_safe(class_name, "_unload_portrait_frame", _restrip_frame_layer)
	mod:hook_safe(class_name, "_set_shadowing_portrait", _set_shadowing_portrait)
end

for _, definition_path in ipairs(DEFINITION_PATHS) do
	mod:hook_require(definition_path, _add_profile_picture_passes)
end
