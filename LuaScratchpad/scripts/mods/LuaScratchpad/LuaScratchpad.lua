local mod = get_mod("LuaScratchpad")

local LuaScratchpad = class("LuaScratchpad")
local first_run = true

function LuaScratchpad:init()
	self._is_open = false
	self._lua_string = "local mod = get_mod('LuaScratchpad'); mod:echo('hi')"
	self._global = "Managers"
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

	Imgui.set_next_window_size(500, 750)
	if first_run then
		Imgui.set_next_window_pos(50, 50)
		first_run = false
	end
	local _, closed = Imgui.begin_window("Lua Scratchpath", "always_auto_resize")

	if closed then
		self:close()
	end

	Imgui.push_item_width(500 - 16)
	self._lua_string = Imgui.input_text_multiline("", self._lua_string)

	if Imgui.button("Run lua", 500 - 16) then
		Mods.lua.loadstring(self._lua_string)()
	end

	self._global = Imgui.input_text("inspect", self._global)
	local global_script = Mods.lua.loadstring("return " .. self._global)
	local global = nil
	if global_script then
		global = global_script()
	end

	if Imgui.tree_node(self._global, true) then
		if global then
			table_to_tree(global)
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

mod:hook("UIManager", "using_input", function(func, ...)
	return editor._is_open or func(...)
end)
