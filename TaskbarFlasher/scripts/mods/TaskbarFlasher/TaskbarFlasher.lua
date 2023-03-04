-- Taskbar Flasher
-- Description: Flash the taskbar icon when loading screens end or the AFK warning pops up
-- Author: raindish
local mod = get_mod("TaskbarFlasher")

mod.maybe_flash_window = function()
	local can_flash_window = _G.Window ~= nil and Window.flash_window ~= nil and not Window.has_focus()

	if can_flash_window then
		Window.flash_window(nil, "start", 5)
	end
end

-- On load
mod:hook("LoadingView", "on_exit", function(func, ...)
	if mod:get("flash_on_load") then
		mod.maybe_flash_window()
	end
	return func(...)
end)

-- On afk
mod:hook("AFKChecker", "rpc_enable_inactivity_warning", function(func, ...)
	if mod:get("flash_on_afk") then
		mod.maybe_flash_window()
	end
	return func(...)
end)

mod:hook("LobbyView", "on_enter", function(func, ...)
	if mod:get("flash_on_load") then
		mod.maybe_flash_window()
	end
	return func(...)
end)

mod.on_game_state_changed = function(status, state)
	if status == "enter" and state == "GameplayStateRun" then
		if mod:get("flash_on_load") then
			mod.maybe_flash_window()
		end
	end
end
