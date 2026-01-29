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

-- Save tweak and load
local function set_style_tweak(path, val)
	set_in(style_tweaks, path, val)
	mod:set("style_tweaks", style_tweaks)
end



-- Table that stores external option definitions persistently between reloads.
-- Structure: _custom_options[<hud_element>][<id>] = option_definition
local _custom_options = mod:persistent_table("custom_options")

-- Simple id counter so handles don’t shift after removals.
_custom_options._next_id = _custom_options._next_id or 0

-- Draw helpers for each control type

-- Imgui helpers keyed by `type`
local CONTROL_HANDLERS = {
    button = function(opt, label, element, widget)
        if Imgui.small_button(label) and opt.action then
            opt.action(element, widget)
        end
    end,

    checkbox = function(opt, label)
        local current = opt.get and opt.get() or false
        local new_val = Imgui.checkbox(label, current)
        if new_val ~= current and opt.set then
            opt.set(new_val)
        end
    end,

    slider_int = function(opt, label)
        local val = opt.get and opt.get() or 0
        local new_val = Imgui.slider_int(label, val, opt.min or 0, opt.max or 100)
        if new_val ~= val and opt.set then
            opt.set(new_val)
        end
    end,

    slider_float = function(opt, label)
        local val = opt.get and opt.get() or 0.0
        local new_val = Imgui.slider_float(label, val, opt.min or 0.0, opt.max or 1.0)
        if new_val ~= val and opt.set then
            opt.set(new_val)
        end
    end,

    input_text = function(opt, label)
        local val = opt.get and opt.get() or ""
        local new_val = Imgui.input_text(label, val)
        if new_val ~= val and opt.set then
            opt.set(new_val)
        end
    end,
}


_custom_options._style_index = _custom_options._style_index or {}

-- helper – give it element/widget/style/key to set up the control
function mod.register_style_option(def)
    if type(def) ~= "table" then
        return
    end

    local element = def.hud_element
    local widget = def.widget
    local style_id = def.style_id
    local key = def.key
    if not (element and widget and style_id and key) then
        return
    end

    -- Compose unique index key.
    local idx_key = table.concat({element, widget, style_id, key}, ":")
    if _custom_options._style_index[idx_key] then
        -- Already registered, skip
        return _custom_options._style_index[idx_key]
    end

    local path = {element, widget, style_id, key}

    -- Auto-detect control type
    local value = def.value -- caller may pass current value to avoid lookup later
    local ctrl_type = def.type
    if not ctrl_type then
        if type(value) == "boolean" then
            ctrl_type = "checkbox"
        elseif type(value) == "number" then
            ctrl_type = (value % 1 == 0) and "slider_int" or "slider_float"
        else
            return 
        end
    end

    local option_def = {
        hud_element = element,
        widget      = widget,
        label       = def.label or key,
        type        = ctrl_type,
        min         = def.min,
        max         = def.max,
        get         = function()
            -- navigate style_tweaks else fall back to original value
            local t = style_tweaks
            for i = 1, #path do
                t = t and t[path[i]]
            end
            if t ~= nil then
                return t
            end
            return value
        end,
        set         = function(v)
            set_style_tweak(path, v)
        end,
    }

    local handle = mod.register_option(option_def)

    _custom_options._style_index[idx_key] = handle
    return handle
end

-- Draw one registered option.
local function _draw_registered_option(opt, element, widget)
    -- Imgui not ready? bail.
    if not Imgui then
        return
    end

    if opt.draw then
        opt.draw(element, widget)
        return
    end

    local label = opt.label or "Unnamed"
    local control_type = opt.type or "button"

    local handler = CONTROL_HANDLERS[control_type]
    if handler then
        handler(opt, label, element, widget)
    else
        Imgui.text(string.format("[Unsupported option type: %s]", tostring(control_type)))
    end
end

-- register_option(def_table) -> handle
-- Adds a control described above. Returns a stable handle for later removal.
-- unregister_option(hud_element, handle) removes it again.
function mod.register_option(definition)
    if type(definition) ~= "table" then
        mod:echo("[HUDTweaker] register_option expects a table definition")
        return nil
    end

    if type(definition.hud_element) ~= "string" then
        mod:echo("[HUDTweaker] register_option requires 'hud_element' string field")
        return nil
    end

    -- Generate a stable id so the handle stays valid even when other
    -- options are removed.
    _custom_options._next_id = (_custom_options._next_id or 0) + 1
    local id = _custom_options._next_id

    definition._id = id -- for easy debugging

    -- Bucket options per HUD element.
    _custom_options[definition.hud_element] = _custom_options[definition.hud_element] or {}
    local bucket = _custom_options[definition.hud_element]
    bucket[id] = definition

    return id
end

function mod.unregister_option(hud_element, handle)
    local bucket = _custom_options[hud_element]
    if bucket then
        bucket[handle] = nil
    end
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

						-- Draw custom options registered for this widget (specific)
						local element_options = _custom_options[class_name]
						if element_options then
						    for _, opt in pairs(element_options) do
						        if opt.widget == widget_name then
						            _draw_registered_option(opt, element, widget)
						        end
						    end
						end

						widget.dirty = true
						Imgui.tree_pop()
					end
				end

				-- Draw element level custom options (widget=nil)
				local element_options = _custom_options[class_name]
				if element_options then
				    for _, opt in pairs(element_options) do
				        if not opt.widget then
				            _draw_registered_option(opt, element, nil)
				        end
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
