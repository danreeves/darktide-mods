local mod = get_mod("TrueSoloQoL")
local PlayerMovement = require("scripts/utilities/player_movement")

mod:hook("PlayerUnitSpawnManager", "_num_available_bot_slots", function(func, ...)
	if mod:get("disable_bots") then
		return 0
	end
	return func(...)
end)

function mod.toggle_pause()
	if Managers.state.game_session:is_server() then
		local time = Managers.time
		local timer = "gameplay"

		if time:local_scale(timer) == 0 then
			time:set_local_scale(timer, 1)
		else
			time:set_local_scale(timer, 0)
		end
	end
end

mod:command("pause", mod:localize("toggle_pause"), function()
	mod.toggle_pause()
end)

function mod.restart_level()
	local mechanism_manager = Managers.mechanism

	local mechanism_name = mechanism_manager:mechanism_name()
	local mission_context = mechanism_manager._mechanism._context

	mechanism_manager:change_mechanism(mechanism_name, mission_context)
	mechanism_manager:trigger_event("all_players_ready")
end

mod:command("restart", mod:localize("restart_level"), mod.restart_level)

mod:hook_safe("GameModeCoopCompleteObjective", "init", function(self)
	self._settings.mission_end_grace_time_disabled = 3
	self._settings.mission_end_grace_time_dead = 3
end)

mod:hook("GameModeCoopCompleteObjective", "evaluate_end_conditions", function(func, self, ...)
	if mod:get("auto_restart") then
		local t = Managers.time:time("gameplay")
		local failure_conditions_met = self:_failure_conditions_met()
		if self._is_server and failure_conditions_met and self._end_t ~= nil and self._end_t < t then
			mod.restart_level()
			return false
		end
	end
	return func(self, ...)
end)

mod:hook("CinematicSceneSystem", "_can_play", function(func, self, cinematic_name, ...)
	if cinematic_name == "intro_abc" and mod:get("skip_cutscene") then
		return false
	end
	return func(self, cinematic_name, ...)
end)

local function position_at_cursor(local_player)
	local viewport_name = local_player.viewport_name

	local camera_position = Managers.state.camera:camera_position(viewport_name)
	local camera_rotation = Managers.state.camera:camera_rotation(viewport_name)
	local camera_direction = Quaternion.forward(camera_rotation)

	local range = 500

	local world = Managers.world:world("level_world")
	local physics_world = World.get_data(world, "physics_world")

	local new_position
	local result = PhysicsWorld.immediate_raycast(
		physics_world,
		camera_position,
		camera_direction,
		range,
		"all",
		"types",
		"statics",
		"collision_filter",
		"filter_player_character_shooting_raycast_statics"
	)

	if result then
		local num_hits = #result

		for i = 1, num_hits, 1 do
			local hit = result[i]
			local hit_actor = hit[4]
			local hit_unit = Actor.unit(hit_actor)
			local player_unit = local_player.player_unit
			local ray_hit_self = player_unit and (hit_unit == player_unit)

			if not ray_hit_self then
				new_position = hit[1]
				break
			end
		end
	end

	return new_position
end

function mod.teleport_to_cursor()
	local player = Managers.player:local_player(1)
	local unit = player.player_unit
	local position = position_at_cursor(player)
	if position then
		PlayerMovement.teleport_fixed_update(unit, position)
	end
end
