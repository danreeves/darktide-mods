-- Colour and backplate settings for NumericUI texts
-- A text opts in with its two settings in NumericUI_data (color_setting, backplate_setting), a backplate pass next to
-- its text pass (backplate_pass), register(prefix) so its setting changes apply live, and apply() whenever
-- TextStyle.version changes or the text moves, resizes or changes its string.

local mod = get_mod("NumericUI")
local UIRenderer = require("scripts/managers/ui/ui_renderer")

local math_clamp = math.clamp
local math_floor = math.floor
local pairs = pairs
local table_clone = table.clone
local type = type

local BACKPLATE_COLOR_DEFAULT = { 160, 0, 0, 0 } -- ARGB
local BACKPLATE_PADDING_X_DEFAULT = 4
local BACKPLATE_PADDING_Y_DEFAULT = 2
local BACKPLATE_PADDING_MAX = 20

local TextStyle = {
	-- bumped by invalidate() on every change of a registered setting; elements compare it to know when to re-apply
	version = 1,
}

local function _setting_ids(prefix)
	return {
		color = prefix .. "_color",
		backplate = prefix .. "_backplate",
		backplate_color = prefix .. "_backplate_color",
		backplate_padding_x = prefix .. "_backplate_padding_x",
		backplate_padding_y = prefix .. "_backplate_padding_y",
	}
end

TextStyle.color_setting = function(prefix, default_color)
	local ids = _setting_ids(prefix)

	return {
		setting_id = ids.color,
		type = "color",
		tooltip = "text_style_color_description",
		default_value = table_clone(default_color),
		has_alpha = true,
	}
end

TextStyle.backplate_setting = function(prefix)
	local ids = _setting_ids(prefix)

	return {
		setting_id = ids.backplate,
		type = "checkbox",
		tooltip = "text_style_backplate_description",
		default_value = false,
		sub_widgets = {
			{
				setting_id = ids.backplate_color,
				type = "color",
				title = "text_style_backplate_color",
				tooltip = "text_style_backplate_color_description",
				default_value = table_clone(BACKPLATE_COLOR_DEFAULT),
				has_alpha = true,
			},
			{
				setting_id = ids.backplate_padding_x,
				type = "numeric",
				title = "text_style_backplate_padding_x",
				tooltip = "text_style_backplate_padding_x_description",
				default_value = BACKPLATE_PADDING_X_DEFAULT,
				range = { 0, BACKPLATE_PADDING_MAX },
				step_size_value = 1,
			},
			{
				setting_id = ids.backplate_padding_y,
				type = "numeric",
				title = "text_style_backplate_padding_y",
				tooltip = "text_style_backplate_padding_y_description",
				default_value = BACKPLATE_PADDING_Y_DEFAULT,
				range = { 0, BACKPLATE_PADDING_MAX },
				step_size_value = 1,
			},
		},
	}
end

-- Only for text passes without a size of their own, whose box is their scenegraph node: the plate is aligned in that
-- node the way the text is, so it follows the node when it resizes. A text with its own box needs this extended.
TextStyle.backplate_pass = function(text_style, text_value_id, backplate_style_id, layer)
	return {
		pass_type = "rect",
		style_id = backplate_style_id,
		style = {
			visible = false,
			horizontal_alignment = text_style.text_horizontal_alignment,
			vertical_alignment = text_style.text_vertical_alignment,
			size = { 0, 0 },
			offset = { 0, 0, layer },
			color = table_clone(BACKPLATE_COLOR_DEFAULT),
		},
		visibility_function = function(content)
			return content[text_value_id] ~= ""
		end,
	}
end

local registered_setting_ids = {}
local resolved_by_prefix = {}

TextStyle.register = function(prefix)
	local ids = _setting_ids(prefix)

	for _, setting_id in pairs(ids) do
		registered_setting_ids[setting_id] = true
	end

	resolved_by_prefix[prefix] = {
		ids = ids,
		version = 0,
		text_color = { 0, 0, 0, 0 },
		backplate_color = { 0, 0, 0, 0 },
	}
end

TextStyle.is_setting = function(setting_id)
	return registered_setting_ids[setting_id] == true
end

TextStyle.invalidate = function()
	TextStyle.version = TextStyle.version + 1
end

local function _color_channel(value)
	if type(value) ~= "number" then
		return
	end

	return math_floor(math_clamp(value, 0, 255) + 0.5)
end

-- Copies an ARGB colour setting into destination and returns it packed into one number for cheap comparison,
-- or nil when the setting is not a valid ARGB table
local function _read_color(value, destination)
	if type(value) ~= "table" then
		return
	end

	local packed = 0

	for i = 1, 4 do
		local channel = _color_channel(value[i])

		if not channel then
			return
		end

		destination[i] = channel
		packed = packed * 256 + channel
	end

	return packed
end

local function _read_padding(value, default_value)
	if type(value) ~= "number" then
		return default_value
	end

	return math_clamp(value, 0, BACKPLATE_PADDING_MAX)
end

-- The colour setting hands out a fresh table clone on every read, so settings are only re-read after a change
local function _resolve(prefix)
	local resolved = resolved_by_prefix[prefix]
	local version = TextStyle.version

	if resolved.version ~= version then
		local ids = resolved.ids
		local backplate_color = resolved.backplate_color

		resolved.version = version
		-- an invalid text colour leaves the text in the colour the game gives it
		resolved.text_color_packed = _read_color(mod.setting(ids.color), resolved.text_color)
		resolved.backplate = mod.setting(ids.backplate) == true
		resolved.backplate_color_packed = _read_color(mod.setting(ids.backplate_color), backplate_color)
			or _read_color(BACKPLATE_COLOR_DEFAULT, backplate_color)
		resolved.backplate_padding_x =
			_read_padding(mod.setting(ids.backplate_padding_x), BACKPLATE_PADDING_X_DEFAULT)
		resolved.backplate_padding_y =
			_read_padding(mod.setting(ids.backplate_padding_y), BACKPLATE_PADDING_Y_DEFAULT)
	end

	return resolved
end

local function _copy_color(destination, source)
	destination[1] = source[1]
	destination[2] = source[2]
	destination[3] = source[3]
	destination[4] = source[4]
end

-- how far the plate edge sits outside the text edge it is aligned to
local function _alignment_shift(alignment, positive_alignment, negative_alignment, padding)
	if alignment == positive_alignment then
		return padding
	elseif alignment == negative_alignment then
		return -padding
	end

	return 0
end

-- Applies the prefix's colour and backplate settings to one widget. sample_text is the string the plate is sized
-- for; pass the widest string the text can show when it changes often, so the plate does not twitch.
-- Returns true when the widget style changed and needs redrawing.
TextStyle.apply = function(widget, prefix, text_style_id, backplate_style_id, ui_renderer, sample_text)
	local resolved = _resolve(prefix)
	local style = widget.style
	local text_style = style[text_style_id]
	local changed = false
	local text_color_packed = resolved.text_color_packed

	if text_color_packed and text_style._numericui_color ~= text_color_packed then
		_copy_color(text_style.text_color, resolved.text_color)
		text_style._numericui_color = text_color_packed
		changed = true
	end

	local backplate_style = style[backplate_style_id]

	if not backplate_style then
		return changed
	end

	local show_backplate = resolved.backplate

	if backplate_style.visible ~= show_backplate then
		backplate_style.visible = show_backplate
		changed = true
	end

	if not show_backplate then
		return changed
	end

	local backplate_color_packed = resolved.backplate_color_packed

	if backplate_style._numericui_color ~= backplate_color_packed then
		_copy_color(backplate_style.color, resolved.backplate_color)
		backplate_style._numericui_color = backplate_color_packed
		changed = true
	end

	if not sample_text or sample_text == "" then
		return changed
	end

	local font_type = text_style.font_type
	local font_size = text_style.font_size

	if
		backplate_style._numericui_sample ~= sample_text
		or backplate_style._numericui_font_type ~= font_type
		or backplate_style._numericui_font_size ~= font_size
	then
		-- max extents keep the height the same for every string, so the plate only grows sideways
		local text_width, text_height = UIRenderer.text_size(ui_renderer, sample_text, font_type, font_size, nil, nil, true)

		backplate_style._numericui_sample = sample_text
		backplate_style._numericui_font_type = font_type
		backplate_style._numericui_font_size = font_size
		backplate_style._numericui_text_width = text_width
		backplate_style._numericui_text_height = text_height
	end

	local padding_x = resolved.backplate_padding_x
	local padding_y = resolved.backplate_padding_y
	local width = backplate_style._numericui_text_width + padding_x * 2
	local height = backplate_style._numericui_text_height + padding_y * 2
	local text_offset = text_style.offset
	local offset_x = text_offset[1] + _alignment_shift(backplate_style.horizontal_alignment, "right", "left", padding_x)
	local offset_y = text_offset[2] + _alignment_shift(backplate_style.vertical_alignment, "bottom", "top", padding_y)
	local size = backplate_style.size
	local offset = backplate_style.offset

	if size[1] ~= width or size[2] ~= height or offset[1] ~= offset_x or offset[2] ~= offset_y then
		size[1] = width
		size[2] = height
		offset[1] = offset_x
		offset[2] = offset_y
		changed = true
	end

	return changed
end

return TextStyle
