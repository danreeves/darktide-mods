local mod = get_mod("ShowAllBuffs")
local pt = mod:persistent_table("pt")

require("scripts/extension_systems/buff/buff_extension_base")

local PlayerCharacterConstants = require("scripts/settings/player_character/player_character_constants")
local COMPONENT_KEY_LOOKUP = PlayerCharacterConstants.buff_component_key_lookup

local VisualBuffExtension = class("VisualBuffExtension", "BuffExtensionBase")

VisualBuffExtension.init = function(self, unit, player, world, physics_world, wwise_world)
	local extension_init_context = {
		is_server = true,
		world = world,
		physics_world = physics_world,
		wwise_world = wwise_world,
	}
	local extension_init_data = { player = player }
	local game_object_data_or_game_session = nil
	local nil_or_game_object_id = nil
	VisualBuffExtension.super.init(
		self,
		extension_init_context,
		unit,
		extension_init_data,
		game_object_data_or_game_session,
		nil_or_game_object_id
	)

	self._has_added_custom_buffs = false
end

-- Copied from MinionBuffExtention
VisualBuffExtension.update = function(self, unit, dt, t)
	self:_update_buffs(dt, t)
	self:_move_looping_sfx_sources(unit)
	self:_update_proc_events(t)
	self:_update_stat_buffs_and_keywords(t)
	if not self._has_added_custom_buffs then
		mod._add_custom_buffs()
		self._has_added_custom_buffs = true
	end
end

-- Copied from PlayerUnitBuffExtension
VisualBuffExtension._remove_internally_controlled_buff = function(self, local_index)
	local buff_instance = self._buffs_by_index[local_index]
	local template = buff_instance:template()

	if template.predicted then
		local component_index = buff_instance:component_index()

		self:_remove_predicted_buff(component_index)
	elseif self._is_server then
		self:_remove_rpc_synced_buff(local_index)
	end
end

-- Copied from PlayerUnitBuffExtension
VisualBuffExtension._remove_predicted_buff = function(self, component_index)
	local buff_instance = self._component_buffs[component_index]
	local stack_count = buff_instance:stack_count()
	local component_keys = COMPONENT_KEY_LOOKUP[component_index]

	if stack_count > 1 then
		local buff_component = self._buff_component
		local stack_count_key = component_keys.stack_count_key
		buff_component[stack_count_key] = stack_count - 1
	else
		buff_instance:remove_buff_component()

		self._component_buffs[component_index] = nil
	end

	for index, buff in pairs(self._buffs_by_index) do
		if buff == buff_instance then
			self:_remove_buff(index)

			break
		end
	end
end

-- Copied from PlayerUnitBuffExtension
VisualBuffExtension._remove_rpc_synced_buff = function(self, index)
	self:_remove_buff(index)
end

-- Copied from PlayerUnitBuffExtension
VisualBuffExtension._on_add_buff = function(self, buff_instance)
	local buff_context = self._buff_context
	local player = buff_context.player

	Managers.event:trigger("event_player_buff_added", player, buff_instance)
end

-- Copied from PlayerUnitBuffExtension
VisualBuffExtension._on_remove_buff = function(self, buff_instance)
	local buff_context = self._buff_context
	local player = buff_context.player

	Managers.event:trigger("event_player_buff_removed", player, buff_instance)
end

VisualBuffExtension.clear_buffs = function(self)
	local buffs = self._buffs_by_index

	for index, _ in pairs(buffs) do
		self:_remove_buff(index)
	end
end

VisualBuffExtension.destroy = function(self)
	local buffs = self._buffs_by_index

	for index, _ in pairs(buffs) do
		self:_remove_buff(index)
	end
end

mod:hook_safe("PlayerUnitBuffExtension", "init", function(_self, extension_init_context, unit, extension_init_data)
	if pt.visual_buff_extension then
		pt.visual_buff_extension:destroy()
	end
	pt.visual_buff_extension = VisualBuffExtension:new(
		unit,
		extension_init_data.player,
		extension_init_context.world,
		extension_init_context.physics_world,
		extension_init_context.wwise_world
	)
end)

mod:hook_safe("PlayerUnitBuffExtension", "fixed_update", function(_self, unit, dt, t)
	if pt.visual_buff_extension then
		pt.visual_buff_extension:update(unit, dt, t)
	end
end)

mod:hook_safe("PlayerUnitBuffExtension", "destroy", function()
	if pt.visual_buff_extension then
		pt.visual_buff_extension:destroy()
	end
end)

mod:hook("HudElementPlayerBuffs", "_sync_current_active_buffs", function(func, self, buffs)
	func(self, buffs)
	func(self, pt.visual_buff_extension:buffs())
end)

-- Public function
function mod:add_buff(buff_template)
	local t = Managers.time:time("gameplay")
	pt.visual_buff_extension:_add_buff(buff_template, t)
end

-- Public function
function mod:clear_buffs()
	pt.visual_buff_extension:clear_buffs()
end

-- Public function
function mod:add_proc_event(proc_event, param_table)
	pt.visual_buff_extension:add_proc_event(proc_event, param_table)
end
