-- LogMeIn
-- Description: Automatically hits space for you at the title screen
-- Author: raindish
local mod = get_mod("LogMeIn")

local state = mod:persistent_table("state")

state.first_load = state.first_load

if state.first_load == nil then
	state.first_load = true
end

local function cancel()
	state.first_load = false
	mod.cancel_auto_character_select = function() end
end

mod:hook_safe(TitleView, "on_enter", function(self)
	self:_continue()
end)

mod:hook_safe("MainMenuView", "_set_waiting_for_profiles", function(self, waiting)
	if mod:get("auto_character_select") and state.first_load and not waiting then
		cancel()
		self:_on_play_pressed()
	end
	state.first_load = false
end)

mod.cancel_auto_character_select = function()
	if state.first_load then
		mod:notify("Automatic character selection cancelled")
		cancel()
	end
end
