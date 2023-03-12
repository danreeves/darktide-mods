local mod = get_mod("KillfeedImprovements")

local combat_feed_element = {
	use_hud_scale = true,
	class_name = "HudElementCombatFeed",
	filename = "scripts/ui/hud/elements/combat_feed/hud_element_combat_feed",
	visibility_groups = {
		"dead",
		"alive",
		"communication_wheel",
		"tactical_overlay",
	},
}

mod:hook_require("scripts/ui/hud/hud_elements_player_onboarding", function(instance)
	if not table.find_by_key(instance, "class_name", combat_feed_element.class_name) then
		table.insert(instance, combat_feed_element)
	end
end)

local kill_message_localization_key = "loc_hud_combat_feed_kill_message"
local temp_kill_message_localization_params = {
	killer = "n/a",
	victim = "n/a",
}

mod:hook_origin("HudElementCombatFeed", "event_combat_feed_kill", function(self, attacking_unit, attacked_unit)
	if self._mechanism_manager:mechanism_name() == "onboarding" and not mod:get("enable_in_psykanium") then
		return
	end
	local notifications = self._notifications
	local unit_data_extension = ScriptUnit.has_extension(attacked_unit, "unit_data_system")
	local breed_or_nil = unit_data_extension and unit_data_extension:breed()

	if not mod:get(breed_or_nil.name) then
		return
	end

	for _, notification in ipairs(notifications) do
		if notification.breed == breed_or_nil and notification.player == attacking_unit then
			local count = notification.count + 1
			local killer = self:_get_unit_presentation_name(attacking_unit)
			local victim = self:_get_unit_presentation_name(attacked_unit)
			temp_kill_message_localization_params.killer = killer
			temp_kill_message_localization_params.victim = victim
			local text = self:_localize(kill_message_localization_key, true, temp_kill_message_localization_params)
			text = text .. " x" .. tostring(count)

			notification.time = 0
			notification.count = count
			self:_set_text(notification.id, text)
			return
		end
	end

	local killer = self:_get_unit_presentation_name(attacking_unit)
	local victim = self:_get_unit_presentation_name(attacked_unit)
	temp_kill_message_localization_params.killer = killer
	temp_kill_message_localization_params.victim = victim
	local text = self:_localize(kill_message_localization_key, true, temp_kill_message_localization_params)

	local notification = self:_add_combat_feed_message(text)
	notification.count = 1
	notification.breed = breed_or_nil
	notification.player = attacking_unit
end)

-- Modified to return the notification
mod:hook_origin("HudElementCombatFeed", "_add_combat_feed_message", function(self, text)
	local notification, notification_id = self:_add_notification_message("default")

	self:_set_text(notification_id, text)

	return notification, notification_id
end)
