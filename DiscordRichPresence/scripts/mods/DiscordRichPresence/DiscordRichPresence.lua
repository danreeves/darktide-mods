local mod = get_mod("DiscordRichPresence")
local SoloPlay = get_mod("SoloPlay")

local PresenceSettings = require("scripts/settings/presence/presence_settings")
local Missions = require("scripts/settings/mission/mission_templates")
local Archetypes = require("scripts/settings/archetype/archetypes")
local DangerSettings = require("scripts/settings/difficulty/danger_settings")

if not DarktideDiscord then
	mod:echo("Discord plugin missing.")
	return
end

function mod.get_mission_name()
	if not Managers.mechanism._mechanism then
		return
	end
	local mechanism_data = Managers.mechanism._mechanism._mechanism_data
	local mission_settings = Missions[mechanism_data.mission_name]

	if mission_settings then
		return Localize(mission_settings.mission_name)
	end
end

local function is_soloplay()
	if SoloPlay and SoloPlay.is_soloplay() then
		return true
	end
	return false
end

local function set_presence()
	if not Managers.presence then
		return
	end

	local presence = Managers.presence._myself
	local activity_id = presence:activity_id()

	local num_party_members = presence:num_party_members()

	-- Start the activity timer
	DarktideDiscord.set_start_time()

	-- I want to show map name so this needs a special case
	if activity_id == "mission" or is_soloplay() then
		local mission_name = mod.get_mission_name()
		DarktideDiscord.set_details(mission_name)

		local current_difficulty = Managers.state
				and Managers.state.difficulty
				and Managers.state.difficulty:get_difficulty()
			or 0
		local danger_settings = DangerSettings.by_index[current_difficulty]
		if danger_settings then
			local difficulty_text = Localize(danger_settings.display_name)
			DarktideDiscord.set_state(difficulty_text)
		end
	else
		local settings = PresenceSettings.settings[activity_id]
		local activity = Managers.localization:localize(settings.hud_localization)
		DarktideDiscord.set_details(activity)

		local state = num_party_members > 1 and "In Strike Team" or "Playing alone"
		DarktideDiscord.set_state(state)
	end

	local num_mission_members = presence:num_mission_members()
	local party_size = math.max(num_party_members, num_mission_members)
	DarktideDiscord.set_party_size(party_size, 4)

	local player = Managers.player:local_player(1)
	local profile = player:profile()
	local name = player:name()
	local level = profile.current_level
	local archetype_name = player:archetype_name()
	local archetype = Archetypes[archetype_name]
	local specialization_name = profile.specialization
	local specialization = archetype.specializations[specialization_name]
	local details = string.format(
		"%s - %s %s %d",
		name,
		Localize(archetype.archetype_name),
		Localize(specialization.title),
		level
	)
	DarktideDiscord.set_class(archetype_name, details)

	DarktideDiscord.update()
end

mod:hook_safe("PresenceManager", "_update_my_presence", set_presence)

function mod.on_game_state_changed()
	local presence = Managers.presence._myself
	local activity_id = presence:activity_id()
	if activity_id == "mission" or is_soloplay() then
		local challenge = Managers.state and Managers.state.difficulty and Managers.state.difficulty:get_difficulty()
			or 0
		local danger_settings = DangerSettings.by_index[challenge]
		if danger_settings then
			local difficulty_text = Localize(danger_settings.display_name)
			DarktideDiscord.set_state(difficulty_text)
			DarktideDiscord.update()
		end
	end
end
