local mod = get_mod("BuffHUDImprovements")

-- Required to exist before sub-classing it
require("scripts/ui/hud/elements/player_buffs/hud_element_player_buffs_polling")
local PlayerBuffDefinitions = require("scripts/ui/hud/elements/player_buffs/hud_element_player_buffs_definitions")

local HudElementPriorityBuffs = class("HudElementPriorityBuffs", "HudElementPlayerBuffs")

function HudElementPriorityBuffs:init(parent, draw_layer, start_scale, definitions)
	HudElementPriorityBuffs.super.init(self, parent, draw_layer, start_scale, table.clone(PlayerBuffDefinitions))

	self._player = parent:player()
	self._active_buffs_data = {}
	self._active_positive_buffs = 0
	self._active_negative_buffs = 0

	self:_update_buff_alignments(true)
end

function HudElementPriorityBuffs:update(dt, t, ui_renderer, render_settings, input_service)
	HudElementPriorityBuffs.super.update(self, dt, t, ui_renderer, render_settings, input_service)
end

function HudElementPriorityBuffs:event_player_buff_added(player, buff_instance)
	if not self._player or self._player ~= player then
		return
	end

	local buff_name = buff_instance._template_name
	local is_priority = mod:get(buff_name .. "_priority")
	local add_buff = buff_instance:has_hud()

	if add_buff and is_priority then
		mod:echo("Adding priority buff")
		self:_add_buff(buff_instance)
	end
end

return HudElementPriorityBuffs
