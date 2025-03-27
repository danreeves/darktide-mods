local mod = get_mod("KillfeedImprovements")

local kill_message_localization_key = "loc_hud_combat_feed_kill_message"
local temp_kill_message_localization_params = {
	killer = "n/a",
	victim = "n/a",
}

mod:hook("HudElementCombatFeed", "event_combat_feed_kill", function(func, self, attacking_unit, attacked_unit)
	func(self, attacking_unit, attacked_unit)

	if type(attacked_unit) == "string" then
		-- scoreboard mod compatibility
		return
	end

	local notifications = self._notifications
	local new_notification = notifications[1]
	local unit_data_extension = ScriptUnit.has_extension(attacked_unit, "unit_data_system")
	local breed_or_nil = unit_data_extension and unit_data_extension:breed()

	if not breed_or_nil or not mod:get(breed_or_nil.name) then
		return
	end

	if new_notification == nil then
		return
	end

	new_notification.count = 1
	new_notification.breed = breed_or_nil
	new_notification.player = attacking_unit

	for _, notification in ipairs(notifications) do
		if
			notification.breed == breed_or_nil -- same breed
			and notification.player == attacking_unit -- same player
			and notification.id ~= new_notification.id -- not the same notification
		then
			new_notification.count = notification.count + 1
			self:_remove_notification(notification.id)
		end
	end

	if new_notification.count > 1 then
		local killer = self:_get_unit_presentation_name(attacking_unit)
		local victim = self:_get_unit_presentation_name(attacked_unit)
		temp_kill_message_localization_params.killer = killer
		temp_kill_message_localization_params.victim = victim
		local text = self:_localize(kill_message_localization_key, true, temp_kill_message_localization_params)
		text = text .. " x" .. tostring(new_notification.count)
		self:_set_text(new_notification.id, text)
	end
end)
