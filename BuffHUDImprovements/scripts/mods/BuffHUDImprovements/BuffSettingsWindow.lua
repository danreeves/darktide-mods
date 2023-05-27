local mod = get_mod("BuffHUDImprovements")
local BuffTemplates = require("scripts/settings/buff/buff_templates")
local MasterItems = require("scripts/backend/master_items")

local BuffSettingsWindow = class("ModBuffSettingsWindow")

function BuffSettingsWindow:init()
	self._is_open = false
	self._items = {}
	self._icon_cache = {}
	self._buffs = {}
	self._num_buffs = 0
	self._page = 1
	self._search = ""
end

function BuffSettingsWindow:open()
	local input_manager = Managers.input
	local name = self.__class_name

	if not input_manager:cursor_active() then
		input_manager:push_cursor(name)
	end

	self._items = MasterItems.get_cached()

	if self._num_buffs == 0 then
		for _, buff_template in pairs(BuffTemplates) do
			local hud_icon = self:_get_icon(buff_template)
			if hud_icon then
				self._num_buffs = self._num_buffs + 1
				self._buffs[buff_template.name] = buff_template
			end
		end
	end

	self._is_open = true
	Imgui.open_imgui()
end

function BuffSettingsWindow:close()
	local input_manager = Managers.input
	local name = self.__class_name

	if input_manager:cursor_active() then
		input_manager:pop_cursor(name)
	end

	self._is_open = false
	Imgui.close_imgui()
end

function BuffSettingsWindow:_get_icon(buff_template)
	if buff_template.hide_icon_in_hud then
		return nil
	end

	if buff_template.hud_icon then
		return buff_template.hud_icon
	end

	local buff_name = buff_template.name

	local cached_icon = self._icon_cache[buff_name]
	if cached_icon then
		return cached_icon
	end

	if string.find(buff_name, "_parent") then
		buff_name = string.gsub(buff_name, "_parent", "")
	end

	for _, item in pairs(self._items) do
		if item.trait == buff_name then
			if item.icon and item.icon ~= "" then
				self._icon_cache[buff_template.name] = item.icon
				return item.icon
			end
		end
	end

	return nil
end

function BuffSettingsWindow:checkbox(_label, key)
	-- make the label unique else imgui gets confused
	-- big space to hide the unwanted bit off screen
	local label = _label .. "                                    " .. key
	local val = mod:get(key)
	local new_val = Imgui.checkbox(label, val)
	if val ~= new_val then
		mod:set(key, new_val)
	end
end

function BuffSettingsWindow:update()
	if self._is_open then
		local _, closed = Imgui.begin_window("Buff Settings", "always_auto_resize")
		if closed then
			self:close()
		end

		local _search = Imgui.input_text("Search", self._search)
		if _search ~= self._search then
			self._search = _search
			self._page = 1
		end

		local min = self._page
		local max = self._page + 8

		local i = 1
		for _, buff_template in pairs(self._buffs) do
			if self._search == "" or #self._search > 0 and string.find(buff_template.name, self._search) then
				local hud_icon = self:_get_icon(buff_template)
				if i >= min and i <= max then
					-- if hud_icon then
					Imgui.columns(2)
					Imgui.set_column_width(80, 0)
					if hud_icon then
						Imgui.image(hud_icon, 64, 64)
					else
						Imgui.text(buff_template.name)
					end
					if Imgui.is_item_hovered() then
						Imgui.begin_tool_tip()
						Imgui.text(buff_template.name)
						Imgui.end_tool_tip()
					end
					Imgui.next_column()
					self:checkbox("Priority", buff_template.name .. "_priority")
					self:checkbox("Hidden", buff_template.name .. "_hidden")
					Imgui.next_column()
					-- end
				end
				i = i + 1
			end
		end
		Imgui.columns(1)
		self._page = Imgui.slider_int("Page", self._page, 1, math.max(1, math.min(i - 9, self._num_buffs - 8)))

		Imgui.separator()
		if Imgui.button("Prioritise all negative buffs") then
			self:_prioritise_all_negative()
		end

		if Imgui.button("Prioritise all blessings") then
			self:_prioritise_all_blessings()
		end

		if Imgui.button("Hide all buffs") then
			self:_hide_all()
		end

		if Imgui.button("Reset all settings") then
			self:_reset_all()
		end

		Imgui.end_window()
	end
end

function BuffSettingsWindow:_prioritise_all_blessings()
	for _, item in pairs(self._items) do
		if item.item_type == "TRAIT" then
			local buff_name = item.trait

			if self._buffs[buff_name] then
				mod:set(buff_name .. "_priority", true)
				mod:set(buff_name .. "_hidden", false)
			end

			buff_name = buff_name .. "_parent"

			if self._buffs[buff_name] then
				mod:set(buff_name .. "_priority", true)
				mod:set(buff_name .. "_hidden", false)
			end
		end
	end
	mod:echo("Set all blessing buffs to priority buff bar")
end

function BuffSettingsWindow:_prioritise_all_negative()
	for _, buff_template in pairs(self._buffs) do
		if buff_template.is_negative then
			mod:set(buff_template.name .. "_priority", true)
		end
	end
	mod:echo("Set all negative buffs to priority buff bar")
end

function BuffSettingsWindow:_hide_all()
	for _, buff_template in pairs(self._buffs) do
		mod:set(buff_template.name .. "_priority", false)
		mod:set(buff_template.name .. "_hidden", true)
	end
	mod:echo("Reset all buff settings")
end

function BuffSettingsWindow:_reset_all()
	for _, buff_template in pairs(self._buffs) do
		mod:set(buff_template.name .. "_priority", false)
		mod:set(buff_template.name .. "_hidden", false)
	end
	mod:echo("Reset all buff settings")
end

return BuffSettingsWindow
