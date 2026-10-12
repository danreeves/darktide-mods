local mod = get_mod("Tertium4Or5")
local WeaponTemplates = require("scripts/settings/equipment/weapon_templates/weapon_templates")
local ProfileUtils = require("scripts/utilities/profile_utils")
local profiles = mod:persistent_table("profiles")
local Personalities = require("scripts/settings/character/personalities")
local BotSpawning = require("scripts/managers/bot/bot_spawning")

local VANILLA_NUM_BOTS = 3
local NUM_VANILLA_BOT_PROFILES = 6

-- The "Enable 4 bots" checkbox became the num_bots slider
if mod:get("four_bots") ~= nil then
	if mod:get("four_bots") then
		mod:set("num_bots", 4)
	end
	mod:set("four_bots", nil)
end

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

			local gender_text = mod:localize("gender_female_abbreviation")
			if profile.gender == "male" then
				gender_text = mod:localize("gender_male_abbreviation")
			end

			local archetype = profile.archetype
			local archetype_raw_name = Localize(archetype.archetype_name)
			local archetype_name = archetype_raw_name:sub(1, 1):upper() .. archetype_raw_name:sub(2)

			local personality_name = Localize(Personalities[profile.lore.backstory.personality].display_name)

			table.insert(mod.character_options, {
				text = profile.original_name .. " " .. gender_text .. " " .. personality_name .. " " .. archetype_name,
				value = profile.character_id,
			})
		end
	end)

	return profiles_promise
end)

mod:hook(ProfileUtils, "bot_character_name", function(func, profile)
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
	return func(self, ...) + mod:get("num_bots") - VANILLA_NUM_BOTS
end)

-- Vanilla gives each initial bot one of its 6 bot profiles and errors past 6,
-- so leave the rest queued for _handle_bot_spawning, which spawns one per frame
mod:hook("PlayerUnitSpawnManager", "_handle_initial_bot_spawning", function(func, self)
	local num_overflow_bots = math.max(self._queued_bots_n - NUM_VANILLA_BOT_PROFILES, 0)
	self._queued_bots_n = self._queued_bots_n - num_overflow_bots
	func(self)
	self._queued_bots_n = self._queued_bots_n + num_overflow_bots
end)

-- _handle_bot_spawning passes nil once all 6 vanilla bot profiles are in use; reuse one of them
mod:hook(BotSpawning, "spawn_bot_character", function(func, profile_name)
	if not profile_name then
		profile_name = BotSpawning.get_bot_config_identifier() .. "_bot_" .. math.random(NUM_VANILLA_BOT_PROFILES)
	end
	return func(profile_name)
end)

mod:hook_require(
	"scripts/ui/hud/elements/team_panel_handler/hud_element_team_panel_handler_settings",
	function(settings)
		-- Sized for the num_bots maximum: this runs once per game launch, and slots without a player draw nothing
		settings.max_panels = mod.max_bots + 1
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
