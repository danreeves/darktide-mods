-- LogMeIn
-- Description: Automatically hits space for you at the title screen
-- Author: raindish
local mod = get_mod("LogMeIn")

_G._LogMeIn_first_load = _G.first_load == nil and true or _G.first_load

mod:hook_safe(TitleView, "on_enter", function(self)
    self:_continue()
end)

mod:hook_safe("MainMenuView", "_set_waiting_for_characters", function(self, waiting)
    if _G._LogMeIn_first_load and not waiting then
        _G._LogMeIn_first_load = false
        self:_on_play_pressed()
    end
end)

mod.cancel_auto_character_select = function()
    if _G._LogMeIn_first_load then
        _G._LogMeIn_first_load = false
        mod:notify("Automatic character selection cancelled")
    end

    mod.cancel_auto_character_select = function()
    end
end
