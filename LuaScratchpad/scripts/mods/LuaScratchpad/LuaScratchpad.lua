local mod = get_mod("LuaScratchpad")

local LuaScratchpad = class("LuaScratchpad")
local ui_scale = mod:get("ui_scale")
local WIDTH = 500
local HEIGHT = 750
local OFFSET = 50
local PADDING = 16
local first_run = true
local window_width = math.min(WIDTH * ui_scale, RESOLUTION_LOOKUP.width - OFFSET)
local window_height = math.min(HEIGHT * ui_scale, RESOLUTION_LOOKUP.height - OFFSET)
local padded_width = window_width - PADDING

function LuaScratchpad:init()
	self._is_open = false
	self._lua_string = "local mod = get_mod('LuaScratchpad'); mod:echo('hi')"
	self._global = "Managers"
	self._inspect_value = nil
end

function LuaScratchpad:open()
	local input_manager = Managers.input
	local name = self.__class_name

	if not input_manager:cursor_active() then
		input_manager:push_cursor(name)
	end

	self._is_open = true
	Imgui.open_imgui()
end

function LuaScratchpad:close()
	local input_manager = Managers.input
	local name = self.__class_name

	if input_manager:cursor_active() then
		input_manager:pop_cursor(name)
	end

	self._is_open = false
	Imgui.close_imgui()
end

local function table_to_tree(tbl)
	for key, value in pairs(tbl) do
		if Imgui.tree_node(key) then
			local typeof = type(value)

			if typeof == "table" then
				table_to_tree(value)
			else
				Imgui.text(key .. ": " .. tostring(value))
			end

			Imgui.tree_pop()
		end
	end
end

function LuaScratchpad:update()
	if not self._is_open then
		return
	end

	Imgui.set_next_window_size(window_width, window_height)
	if first_run then
		Imgui.set_next_window_pos(OFFSET, OFFSET)
		first_run = false
	end
	local _, closed = Imgui.begin_window("Lua Scratchpad", "always_auto_resize")

	if closed then
		self:close()
	end

	Imgui.set_window_font_scale(ui_scale)

	Imgui.push_item_width(padded_width)
	self._lua_string = Imgui.input_text_multiline("", self._lua_string)

	if Imgui.button("Run lua", padded_width) then
		Mods.lua.loadstring(self._lua_string)()
	end

	local inspect_label
	local inspect_value

	if self._inspect_value then
		inspect_label = "Inspecting.."
		inspect_value = self._inspect_value
	else
		self._global = Imgui.input_text("inspect", self._global)
		inspect_label = self._global
		local global_script = Mods.lua.loadstring("return " .. self._global)
		if global_script then
			inspect_value = global_script()
		end
	end

	if Imgui.tree_node(inspect_label, true) then
		if inspect_value then
			table_to_tree(inspect_value)
		else
			Imgui.text("nil")
		end
		Imgui.tree_pop()
	end

	Imgui.end_window()
end

local editor = LuaScratchpad:new()

function mod.update()
	editor:update()
end

function mod.toggle_editor()
	if editor._is_open then
		editor:close()
	else
		editor:open()
	end
end

function mod.inspect(...)
	if editor then
		editor._inspect_value = select("#", ...) > 1 and {...} or ...
		if not editor._is_open then
			editor:open()
		end
	end
end

mod:hook("UIManager", "using_input", function(func, ...)
	return editor._is_open or func(...)
end)
