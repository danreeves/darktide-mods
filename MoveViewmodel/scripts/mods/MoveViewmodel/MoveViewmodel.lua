local mod = get_mod("MoveViewmodel")
local FirstPersonAnimationVariables = require("scripts/utilities/first_person_animation_variables")
local WeaponTemplate = require("scripts/utilities/weapon/weapon_template")

local Editor = class("MoveViewmodelEditor")

function Editor:init()
	self._is_open = false
end

function Editor:open()
	local input_manager = Managers.input
	local name = self.__class_name

	if not input_manager:cursor_active() then
		input_manager:push_cursor(name)
	end

	self._is_open = true
	Imgui.open_imgui()
end

function Editor:close()
	local input_manager = Managers.input
	local name = self.__class_name

	if input_manager:cursor_active() then
		input_manager:pop_cursor(name)
	end

	self._is_open = false
	Imgui.close_imgui()
end

local function _weapon_name()
	local player = Managers.player:local_player(1)
	local unit_data_extension = ScriptUnit.has_extension(player.player_unit, "unit_data_system")
	local weapon_action_component = unit_data_extension:read_component("weapon_action")
	local weapon_template = WeaponTemplate.current_weapon_template(weapon_action_component)
	local weapon_name = weapon_template.name
	return weapon_name
end

local function _get(key)
	local weapon_name = _weapon_name()
	local setting_key = weapon_name .. "_" .. key
	return mod:get(setting_key)
end

local function _set(key, val)
	local weapon_name = _weapon_name()
	local setting_key = weapon_name .. "_" .. key
	return mod:set(setting_key, val)
end

function Editor:slider(key)
	local val = _get(key)
	local new_val = Imgui.slider_float(string.upper(key), val, -1, 1)
	if val ~= new_val then
		_set(key, new_val)
	end
end

function Editor:checkbox(label, key)
	local val = _get(key)
	local new_val = Imgui.checkbox(label, val)
	if val ~= new_val then
		_set(key, new_val)
	end
end

function Editor:update()
	if not self._is_open then
		return
	end

	-- Imgui.set_next_window_size(500, 500)
	local _, closed = Imgui.begin_window("Move Viewmodel", "always_auto_resize")

	if closed then
		self:close()
	end

	self:checkbox("Reset on ADS", "reset_on_ads")
	self:slider("x")
	self:slider("y")
	self:slider("z")
	if Imgui.button("Reset to defaults") then
		_set("x", 0)
		_set("y", 0)
		_set("z", 0)
		_set("reset_on_ads", true)
	end

	Imgui.end_window()
end

local editor = Editor:new()

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

mod:hook("PlayerUnitFirstPersonExtension", "update_unit_position", function(func, self, unit, dt, t)
	func(self, unit, dt, t)

	local player = self._player

	if self._is_local_unit and player:is_human_controlled() then
		local first_person_unit = self._first_person_unit
		local unit_data_extension = self._unit_data_extension
		local state_machine_lerp_values = self._state_machine_lerp_values
		local alternate_fire_component = unit_data_extension:read_component("alternate_fire")
		local input_extension = ScriptUnit.extension(unit, "input_system")
		local position = Unit.local_position(first_person_unit, 1)
		local is_aiming_down_sights = alternate_fire_component and alternate_fire_component.is_active

		if is_aiming_down_sights and _get("reset_on_ads") then
			return
		end

		local yaw, pitch, roll = input_extension:get_orientation()
		local look_rotation = Quaternion.from_yaw_pitch_roll(yaw, pitch, roll)

		local rotated_vector = Quaternion.rotate(look_rotation, Vector3(_get("x"), _get("y"), _get("z")))

		local offset_position = position + rotated_vector

		Unit.set_local_position(first_person_unit, 1, offset_position)
		FirstPersonAnimationVariables.update(
			dt,
			t,
			first_person_unit,
			unit_data_extension,
			self._weapon_extension,
			state_machine_lerp_values
		)
		World.update_unit_and_children(self._world, first_person_unit)
	end
end)
