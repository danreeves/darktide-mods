local mod = get_mod("HUDTweaker")
local hud_elements = mod:persistent_table("hud_elements")
local HUDTweaker = class("HUDTweaker")

local style_tweaks = mod:get("style_tweaks") or {}

local function set_in(tbl, path, val)
	local t = tbl
	for i = 1, #path do
		if i == #path then
			t[path[i]] = val
		else
			if t[path[i]] then
				t = t[path[i]]
			else
				t[path[i]] = {}
				t = t[path[i]]
			end
		end
	end
end

local function set_style_tweak(path, val)
	set_in(style_tweaks, path, val)
	mod:set("style_tweaks", style_tweaks)
end

mod:hook_safe("HudElementBase", "init", function(self)
	if not string.find(self.__class_name, "Handler") then
		hud_elements[self.__class_name] = self
	end
end)

mod:hook("HudElementBase", "update", function(func, self, ...)
	local tweaks = style_tweaks[self.__class_name]
	if tweaks then
		local widgets_by_name = self._widgets_by_name
		for widget_name, widget_styles in pairs(tweaks) do
			local widget = widgets_by_name[widget_name]
			if widget then
				for style_id, custom_styles in pairs(widget_styles) do
					local styles = widget.style[style_id]
					if styles then
						for style_key, value in pairs(custom_styles) do
							if type(value) == "table" then
								for k, v in pairs(value) do
									styles[style_key][k] = v
								end
							else
								styles[style_key] = value
							end
						end
					end
				end
			end
		end
	end
	return func(self, ...)
end)

function HUDTweaker:init()
	self._is_open = false
	self._search = ""
end

function HUDTweaker:open()
	local input_manager = Managers.input
	local name = self.__class_name

	if not input_manager:cursor_active() then
		input_manager:push_cursor(name)
	end

	self._is_open = true
	Imgui.open_imgui()
end

function HUDTweaker:close()
	local input_manager = Managers.input
	local name = self.__class_name

	if input_manager:cursor_active() then
		input_manager:pop_cursor(name)
	end

	self._is_open = false
	Imgui.close_imgui()
end

local function table_to_tree(t, prev_path)
	for key, val in pairs(t) do
		if Imgui.tree_node(key) then
			local typeof = type(val)
			local path = table.clone(prev_path)
			table.insert(path, key)
			if typeof == "table" then
				table_to_tree(val, path)
			else
				local input = nil
				if typeof == "number" then
					input = Imgui.input_int
				elseif typeof == "boolean" then
					input = Imgui.checkbox
				elseif typeof == "string" then
					input = Imgui.input_text
				end

				if input then
					local new_val = input(key, val)
					if new_val ~= val then
						t[key] = new_val
						set_style_tweak(path, new_val)
					end
				else
					Imgui.text(type(val) .. ": " .. tostring(val))
				end
			end
			Imgui.tree_pop()
		end
	end
end

local function find_definitions(t)
	if t._definitions and not table.is_empty(t._definitions) then
		return t._definitions
	end

	for _, val in pairs(t) do
		if type(val) == "table" then
			return find_definitions(val)
		end
	end

	return nil
end

function HUDTweaker:update()
	if not self._is_open then
		return
	end

	Imgui.set_next_window_size(500, 500)
	local _, closed = Imgui.begin_window("HUD Tweaker", "always_auto_resize")

	if closed then
		self:close()
	end

	self._search = Imgui.input_text("Search", self._search)

	for class_name, element in pairs(hud_elements) do
		if self._search and string.find(string.lower(class_name), string.lower(self._search)) or self._search == "" then
			if Imgui.tree_node(class_name) then
				if Imgui.small_button("Reset tweaks") then
					set_style_tweak({ class_name }, nil)
					for _, widget in pairs(element._widgets_by_name) do
						widget.dirty = true
					end
				end

				-- table_to_tree(element._ui_scenegraph, {})

				for widget_name, widget in pairs(element._widgets_by_name) do
					if Imgui.tree_node(widget_name) then
						-- widget.visible = Imgui.checkbox("Visible", widget.visible)

						for _, widget_style in pairs(widget.style) do
							if widget_style.visible == nil then
								widget_style.visible = true
							end
						end

						table_to_tree(widget.style, { class_name, widget_name })

						widget.dirty = true
						Imgui.tree_pop()
					end
				end
				Imgui.tree_pop()
			end
		end
	end

	Imgui.end_window()
end

local hud_tweaker = HUDTweaker:new()

function mod.update()
	hud_tweaker:update()
end

function mod.toggle_hud_tweaker()
	if hud_tweaker._is_open then
		hud_tweaker:close()
	else
		hud_tweaker:open()
	end
end

mod:hook("UIManager", "using_input", function(func, ...)
	return hud_tweaker._is_open or func(...)
end)
