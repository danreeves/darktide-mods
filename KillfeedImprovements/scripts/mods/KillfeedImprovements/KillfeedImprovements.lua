local mod = get_mod("KillfeedImprovements")

local filter_teammate_kills = false
local merge_kills = true
local alignment = "left"
local cached_is_in_psykanium = nil
local cached_local_player = nil

local function cache_settings()
	filter_teammate_kills = mod:get("filter_teammate_kills")
	merge_kills = mod:get("merge_kills")
	alignment = mod:get("alignment")
end

mod.on_all_mods_loaded = cache_settings
mod.on_setting_changed = cache_settings

mod.on_game_state_changed = function(status, state)
	if state == "GameplayStateRun" then
		if status == "enter" then
			cached_is_in_psykanium = Managers.state.game_mode:game_mode_name() == "shooting_range"
			cached_local_player = Managers.player:local_player(1)
		elseif status == "exit" then
			cached_is_in_psykanium = nil
			cached_local_player = nil
		end
	end
end

local kill_message_localization_key = "loc_hud_combat_feed_kill_message"
local temp_kill_message_localization_params = {
	killer = "n/a",
	victim = "n/a",
}

mod:hook("HudElementCombatFeed", "event_combat_feed_kill", function(func, self, attacking_unit, attacked_unit)
	if filter_teammate_kills and attacking_unit and type(attacking_unit) ~= "string" then
		local local_unit = cached_local_player and cached_local_player.player_unit
		if attacking_unit ~= local_unit then
			for _, player in pairs(Managers.player:players()) do
				if player.player_unit == attacking_unit then
					return
				end
			end
		end
	end

	func(self, attacking_unit, attacked_unit)

	if type(attacked_unit) == "string" then
		-- scoreboard mod compatibility
		return
	end

	if merge_kills then
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
	end
end)

mod:hook("HudElementCombatFeed", "_create_widget", function(func, self, name, widget_definition)
	widget_definition.style.text.text_horizontal_alignment = alignment
	widget_definition.style.text.horizontal_alignment = alignment

	return func(self, name, widget_definition)
end)

mod:hook_require("scripts/ui/hud/hud_elements_player_onboarding", function(instance)
	if not table.find_by_key(instance, "class_name", "HudElementCombatFeed") then
		table.insert(instance, {
			class_name = "HudElementCombatFeed",
			filename = "scripts/ui/hud/elements/combat_feed/hud_element_combat_feed",
			use_hud_scale = true,
			visibility_groups = {
				"dead",
				"alive",
				"communication_wheel",
				"tactical_overlay",
			},
		})
	end
end)

mod:hook("HudElementCombatFeed", "_enabled", function(func, ...)
	if cached_is_in_psykanium then
		return mod:get("enable_in_psykanium")
	end
	return func(...)
end)
