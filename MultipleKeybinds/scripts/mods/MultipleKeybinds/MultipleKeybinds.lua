local mod = get_mod("MultipleKeybinds")
local InputUtils = require("scripts/managers/input/input_utils")

local alias_array_index = 4

local cancel_keys = {
	"keyboard_esc",
}
local reserved_keys = {}
local devices = {
	"mouse",
	"keyboard",
}

local input_manager = Managers.input

mod:hook_require("scripts/settings/options/keybind_settings", function(instance)
	for i, setting in ipairs(instance.settings) do
		if setting.widget_type == "keybind" and not setting.modded then
			local alias = input_manager:alias_object(setting.service_type)
			local duplicate_setting = table.merge(table.clone(setting), {
				modded = true,
				alias_array_index = alias_array_index,
				on_activated = function(new_value)
					for j = 1, #cancel_keys do
						local cancel_key = cancel_keys[j]

						if cancel_key == new_value.main then
							return true
						end
					end

					for j = 1, #reserved_keys do
						local reserved_key = reserved_keys[j]

						if reserved_key == new_value.main then
							return false
						end
					end

					alias:set_keys_for_alias(setting.alias_name, alias_array_index, devices, new_value)
					input_manager:apply_alias_changes(setting.service_type)
					input_manager:save_key_mappings(setting.service_type)

					Managers.input:load_settings()
					return true
				end,
				get_function = function()
					local key_info = alias:get_keys_for_alias(setting.alias_name, alias_array_index, devices)

					return key_info
				end,
			})
			table.insert(instance.settings, i + 1, duplicate_setting)
		end
	end
end)

local OptionsViewContentBlueprints = require("scripts/ui/views/options_view/options_view_content_blueprints")
mod:hook_safe(
	OptionsViewContentBlueprints.keybind,
	"init",
	function(_parent, widget, entry, _callback_name, _changed_callback_name)
		local content = widget.content
		local hotspot = content.hotspot
		hotspot.right_pressed_callback = callback(mod, "cb_keybind_rightclicked", entry)
	end
)

function mod:cb_keybind_rightclicked(entry)
	if mod:get("unset_on_rightclick") then
		local alias = input_manager:alias_object(entry.service_type)
		alias:set_keys_for_alias(entry.alias_name, entry.alias_array_index or 1, devices, {})
		input_manager:apply_alias_changes(entry.service_type)
		input_manager:save_key_mappings(entry.service_type)
		Managers.input:load_settings()
	end
end

mod:hook("InputAliases", "set_keys_for_alias", function(func, self, name, index, device_types, new_key_info)
	local alias_row = self._aliases[name]
	if index == alias_array_index then
		local value = InputUtils.make_string(new_key_info)
		alias_row[index] = value
	else
		func(self, name, index, device_types, new_key_info)
	end
end)

mod:hook("InputAliases", "get_keys_for_alias", function(func, self, name, index, device_types)
	if index == alias_array_index then
		local alias_row = self._aliases[name]
		local key_info2 = {}
		local element = alias_row[index]
		if not element then
			return
		end
		key_info2.main, key_info2.enablers, key_info2.disablers = InputUtils.split_key(element)
		return key_info2
	end

	return func(self, name, index, device_types)
end)

mod:hook("InputAliases", "overrides", function(func, self)
	local overrides = func(self)
	local default_aliases = self._default_aliases
	local aliases = self._aliases
	local index = alias_array_index

	for alias_name, alias_info in pairs(aliases) do
		local default = default_aliases[alias_name][index]
		local value = alias_info[index]
		if value ~= default then
			overrides[alias_name] = overrides[alias_name] or {}
			overrides[alias_name][tonumber(index)] = value
		end
	end

	return overrides
end)
