local mod = get_mod("TrueSoloQoL")
local UIWidget = require("scripts/managers/ui/ui_widget")

mod:hook_safe("HudElementTeamPlayerPanel", "update", function(self, dt, t, ui_renderer, render_settings, input_service)
	if self._data.player:type() == "RemotePlayer" then
		self:_destroy_widgets(ui_renderer)
	end
end)
