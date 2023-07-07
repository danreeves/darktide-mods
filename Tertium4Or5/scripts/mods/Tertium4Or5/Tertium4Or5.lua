local mod = get_mod("Tertium4Or5")
local WeaponTemplates = require("scripts/settings/equipment/weapon_templates/weapon_templates")
local ProfileUtils = require("scripts/utilities/profile_utils")
local profiles = mod:persistent_table("profiles")

for _, weapon_template in pairs(WeaponTemplates) do
	if table.array_contains(weapon_template.keywords, "ranged") then
		local attack_meta_data = {}
		for action_name, config in pairs(weapon_template.actions) do
			if config.start_input == "shoot" or config.start_input == "shoot_pressed" then
				attack_meta_data.fire_action_name = action_name
			end

			if config.start_input == "zoom" or config.start_input == "charge" then
				attack_meta_data.aim_action_name = action_name
			end

			if
				config.start_input == "zoom_shoot"
				or config.start_input == "zoom_shoot_pressed"
				or config.start_input == "shoot_pressed"
			then
				attack_meta_data.aim_fire_action_name = action_name
			end

			if config.start_input == "vent" or config.start_input == "zoom_release" then
				attack_meta_data.unaim_action_name = action_name
			end
		end
		weapon_template.attack_meta_data = attack_meta_data
	end
end

mod:hook("ProfilesService", "fetch_all_profiles", function(func, ...)
	local profiles_promise = func(...)

	profiles_promise:next(function(data)
		table.clear(mod.character_options)
		table.insert(mod.character_options, {
			text = "None",
			value = "none",
		})
		for _, profile in pairs(data.profiles) do
			profile.original_name = profile.name
			profiles[profile.character_id] = profile

			table.insert(mod.character_options, {
				text = profile.original_name,
				value = profile.character_id,
			})
		end
	end)

	return profiles_promise
end)

mod:hook(ProfileUtils, "generate_random_name", function(func, profile)
	if profile.original_name then
		return profile.original_name
	end
	return func(profile)
end)

mod:hook("BotSynchronizerHost", "add_bot", function(func, self, local_player_id, player_profile)
	local num_bots = self:num_bots()
	local char_setting = "character_" .. num_bots + 1
	local char_id_or_none = mod:get(char_setting)

	if char_id_or_none == "none" then
		return func(self, local_player_id, player_profile)
	end

	local profile = profiles[char_id_or_none]

	if profile then
		return func(self, local_player_id, profile)
	end

	-- fallback
	return func(self, local_player_id, player_profile)
end)

function mod.on_game_state_changed(status, state)
	if status == "enter" and state == "StateLoading" then
		local data_service = Managers.data_service
		if data_service then
			local profiles_service = data_service.profiles
			if profiles_service then
				profiles_service:fetch_all_profiles()
			end
		end
	end
end

-- mod.on_game_state_changed("enter", "StateLoading")

mod:hook("PlayerUnitSpawnManager", "_num_available_bot_slots", function(func, self, ...)
	local num = func(self, ...)
	if mod:get("four_bots") then
		return num + 1
	end
	return num
end)

mod:hook_require(
	"scripts/ui/hud/elements/team_panel_handler/hud_element_team_panel_handler_settings",
	function(settings)
		if mod:get("four_bots") then
			settings.max_panels = 5
		else
			settings.max_panels = 4
		end
	end
)

-- mod:hook("HudElementTeamPanelHandler", "_setup_position_scenegraphs", function(func, self)
-- 	if mod:get("four_bots") then
-- 		self._max_panels = 4
-- 	else
-- 		self._max_panels = 3
-- 	end
-- 	return func(self)
-- end)
