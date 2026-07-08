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
		mod.pending_main_menu_self = self
		mod.pending_play_delay = 1
	end
	state.first_load = false
end)

mod.cancel_auto_character_select = function()
	if state.first_load then
		mod:notify("Automatic character selection cancelled")
		cancel()
	end
end

mod.update = function(dt)
	if mod.pending_play_delay then
		mod.pending_play_delay = mod.pending_play_delay - dt
		if mod.pending_play_delay <= 0 then
			if mod.pending_main_menu_self then
				mod.pending_main_menu_self:_on_play_pressed()
				mod.pending_main_menu_self = nil
				mod.update = nil
			end
			mod.pending_play_delay = nil
		end
	end
end
