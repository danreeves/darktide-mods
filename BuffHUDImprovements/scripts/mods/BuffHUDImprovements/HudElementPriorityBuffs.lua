local mod = get_mod("BuffHUDImprovements")

-- Required to exist before sub-classing it
require("scripts/ui/hud/elements/player_buffs/hud_element_player_buffs_polling")

local HudElementPriorityBuffs = class("HudElementPriorityBuffs", "HudElementPlayerBuffs")

function HudElementPriorityBuffs:event_player_buff_added(player, buff_instance)
	if not self._player or self._player ~= player then
		return
	end

	local buff_name = buff_instance._template_name
	local is_priority = mod:get(buff_name .. "_priority")
	local add_buff = buff_instance:has_hud()

	if add_buff and is_priority then
		self:_add_buff(buff_instance)
	end
end

return HudElementPriorityBuffs
