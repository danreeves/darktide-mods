local mod = get_mod("BuffHUDImprovements")
local buff_classes = require("scripts/settings/buff/buff_classes")

mod:hook("HudElementPlayerBuffs", "event_player_buff_added", function(func, self, player, buff_instance)
	local buff_name = buff_instance._template_name
	local is_hidden = mod:get(buff_name .. "_hidden")
	local is_priority = mod:get(buff_name .. "_priority")

	if is_hidden or is_priority then
		return
	end

	return func(self, player, buff_instance)
end)

local function get_hud_data_hook(func, self)
	local hud_data = func(self)

	local buff_name = self._template_name
	local is_hidden = mod:get(buff_name .. "_hidden")

	if is_hidden then
		hud_data.show = false
	end

	return hud_data
end

for _, buff_class in pairs(buff_classes) do
	mod:hook(buff_class, "get_hud_data", get_hud_data_hook)
end
