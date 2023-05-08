-- DontStartEmptyGames
-- Description: Return to the hub if the countdown reaches 1 second and you have no teammates
-- Author: raindish
local mod = get_mod("DontStartEmptyGames")

mod:hook_safe("ConstantMissionLobbyStatus", "_event_voting_started", function(self)
	self._started_leave = false
end)

mod:hook_safe("ConstantMissionLobbyStatus", "_set_start_time", function(self, time)
	if time < 1 then
		local num_in_party = 0
		for _, slot_widget in ipairs(self._slot_widgets) do
			if slot_widget.content.occupied then
				num_in_party = num_in_party + 1
			end
		end

		if num_in_party == 1 and self._started_leave == false then
			self._started_leave = true
			mod:echo("Leaving empty lobby")
			Managers.multiplayer_session:leave("leave_mission")
		end
	end
end)
