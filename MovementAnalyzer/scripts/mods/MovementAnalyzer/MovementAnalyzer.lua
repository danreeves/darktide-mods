local mod_name = "MovementAnalyzer"
local mod = get_mod(mod_name)

-- Your mod code goes here.
-- https://vmf-docs.verminti.de
-- ##########################################################
-- ################## Variables #############################

local Breed = require("scripts/utilities/breed")
local Dodge = require("scripts/extension_systems/character_state_machine/character_states/utilities/dodge")
local Sprint = require("scripts/extension_systems/character_state_machine/character_states/utilities/sprint")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")
local UIWidget = require("scripts/managers/ui/ui_widget")

local always_on = true

local queue = {}

local last_dodge_distance = 0
local last_dodge_dur = 0
local last_dodge_start_pos = nil
local last_dodge_start_time = nil

local last_slide_distance = 0
local last_slide_dur = 0
local last_slide_start_pos = nil
local last_slide_start_time = nil

local offset_x = 1281
local offset_y = 100
local text_font_size = 20
local frames = 360

local render_settings = {}

local scenegraph_definition = {
	--root = {scale = "fit", size = {1920, 1080}, position = {10, text_font_size * 10, 50}}
	root = { scale = "fit", size = { 5120, 1440 }, position = { 10, text_font_size * 10, 50 } },
}

local color_white = {
	255,
	255,
	255,
	255,
}

local function get_resolution()
	local w, h = Application.back_buffer_size()
	local is_fullscreen = Application.is_fullscreen and Application.is_fullscreen()
	return w, h, is_fullscreen
end

local function get_x()
	-- local w, h, is_fullscreen = get_resolution()
	-- local x = offset_x
	-- on_setting_changed()
	-- local x_limit = w -- / 2
	-- local max_x = math.min(offset_x, x_limit)
	-- local min_x = math.max(offset_x, -x_limit)
	-- if x == 0 then return 0 end
	-- local clamped_x = x > 0 and max_x or min_x
	-- return clamped_x
	return offset_x
end

local function get_y()
	local w, h, is_fullscreen = get_resolution()
	local y = offset_y
	local y_limit = h -- / 2
	local max_y = math.min(offset_y, y_limit)
	local min_y = math.max(offset_y, -y_limit)
	if y == 0 then
		return 0
	end
	local clamped_y = -(y > 0 and max_y or min_y)
	return -1 * clamped_y
end

local movement_debug_ui_definition = {
	scenegraph_id = "root",
	passes = {
		{
			style_id = "current_speed_text",
			pass_type = "text",
			value_id = "current_speed_text",
			retained_mode = false,
			fade_out_duration = 5,
			visibility_function = function(content, style)
				if always_on then
					return true
				end
			end,
		},
		{
			style_id = "avg_speed_text",
			pass_type = "text",
			value_id = "avg_speed_text",
			retained_mode = false,
			fade_out_duration = 5,
			visibility_function = function(content, style)
				if always_on then
					return true
				end
			end,
		},
		{
			style_id = "last_dodge_distance_text",
			pass_type = "text",
			value_id = "last_dodge_distance_text",
			retained_mode = false,
			fade_out_duration = 5,
			visibility_function = function(content, style)
				if always_on then
					return true
				end
			end,
		},
		{
			style_id = "last_dodge_dur_text",
			pass_type = "text",
			value_id = "last_dodge_dur_text",
			retained_mode = false,
			fade_out_duration = 5,
			visibility_function = function(content, style)
				if always_on then
					return true
				end
			end,
		},
		{
			style_id = "dodging_text",
			pass_type = "text",
			value_id = "dodging_text",
			retained_mode = false,
			visibility_function = function(content, style)
				return true
			end,
		},
		{
			style_id = "position_text",
			pass_type = "text",
			value_id = "position_text",
			retained_mode = false,
			fade_out_duration = 5,
			visibility_function = function(content, style)
				if always_on then
					return true
				end
			end,
		},
		{
			style_id = "player_height_text",
			pass_type = "text",
			value_id = "player_height_text",
			retained_mode = false,
			fade_out_duration = 5,
			visibility_function = function(content, style)
				if always_on then
					return true
				end
			end,
		},
		{
			style_id = "last_slide_distance_text",
			pass_type = "text",
			value_id = "last_slide_distance_text",
			retained_mode = false,
			fade_out_duration = 5,
			visibility_function = function(content, style)
				if always_on then
					return true
				end
			end,
		},
		{
			style_id = "last_slide_dur_text",
			pass_type = "text",
			value_id = "last_slide_dur_text",
			retained_mode = false,
			fade_out_duration = 5,
			visibility_function = function(content, style)
				if always_on then
					return true
				end
			end,
		},
		{
			style_id = "sliding_text",
			pass_type = "text",
			value_id = "sliding_text",
			retained_mode = false,
			visibility_function = function(content, style)
				return true
			end,
		},
		{
			style_id = "sprinting_text",
			pass_type = "text",
			value_id = "sprinting_text",
			retained_mode = false,
			visibility_function = function(content, style)
				return true
			end,
		},
	},
	content = {
		current_speed_text = "",
		avg_speed_text = "",
		dodging_text = "",
		last_dodge_distance_text = "",
		last_dodge_dur_text = "",
		position_text = "",
		player_height_text = "",
		sliding_text = "",
		last_slide_distance_text = "",
		last_slide_dur_text = "",
		sprinting_text = "sprinting",
	},
	style = {
		current_speed_text = {
			font_type = "arial",
			font_size = text_font_size,
			vertical_alignment = "left",
			horizontal_alignment = "left",
			text_color = color_white,
			offset = { get_x(), get_y(), 0 },
		},
		avg_speed_text = {
			font_type = "arial",
			font_size = text_font_size,
			vertical_alignment = "left",
			horizontal_alignment = "left",
			text_color = color_white,
			offset = {
				get_x(),
				get_y() - text_font_size,
				0,
			},
		},
		last_dodge_distance_text = {
			font_type = "arial",
			font_size = text_font_size,
			vertical_alignment = "left",
			horizontal_alignment = "left",
			text_color = color_white,
			offset = {
				get_x(),
				get_y() - (text_font_size * 2),
				0,
			},
		},
		last_dodge_dur_text = {
			font_type = "arial",
			font_size = text_font_size,
			vertical_alignment = "left",
			horizontal_alignment = "left",
			text_color = color_white,
			offset = {
				get_x(),
				get_y() - (text_font_size * 3),
				0,
			},
		},
		dodging_text = {
			font_type = "machine_medium",
			font_size = text_font_size,
			vertical_alignment = "left",
			horizontal_alignment = "left",
			text_color = color_white,
			offset = {
				get_x(),
				get_y() - (text_font_size * 4),
				0,
			},
		},
		position_text = {
			font_type = "arial",
			font_size = text_font_size,
			vertical_alignment = "left",
			horizontal_alignment = "left",
			text_color = color_white,
			offset = {
				get_x(),
				get_y() - (text_font_size * 5),
				0,
			},
		},
		player_height_text = {
			font_type = "arial",
			font_size = text_font_size,
			vertical_alignment = "left",
			horizontal_alignment = "left",
			text_color = color_white,
			offset = {
				get_x(),
				get_y() - (text_font_size * 6),
				0,
			},
		},
		last_slide_distance_text = {
			font_type = "arial",
			font_size = text_font_size,
			vertical_alignment = "left",
			horizontal_alignment = "left",
			text_color = color_white,
			offset = {
				get_x(),
				get_y() - (text_font_size * 7),
				0,
			},
		},
		last_slide_dur_text = {
			font_type = "arial",
			font_size = text_font_size,
			vertical_alignment = "left",
			horizontal_alignment = "left",
			text_color = color_white,
			offset = {
				get_x(),
				get_y() - (text_font_size * 8),
				0,
			},
		},
		sliding_text = {
			font_type = "machine_medium",
			font_size = text_font_size,
			vertical_alignment = "left",
			horizontal_alignment = "left",
			text_color = color_white,
			offset = {
				get_x(),
				get_y() - (text_font_size * 9),
				0,
			},
		},
		sprinting_text = {
			font_type = "machine_medium",
			font_size = text_font_size,
			vertical_alignment = "left",
			horizontal_alignment = "left",
			text_color = color_white,
			offset = {
				get_x(),
				get_y() - (text_font_size * 10),
				0,
			},
		},
	},
	offset = { 0, 0, 0 },
}

local fake_input_service = {
	get = function()
		return
	end,
	has = function()
		return
	end,
}

-- ##########################################################
-- ################## Functions #############################

local function on_setting_changed()
	queue = {}
	always_on = true

	if not mod.ui_widget then
		return
	end
	mod.ui_widget.style.current_speed_text.offset[1] = get_x()
	mod.ui_widget.style.current_speed_text.offset[2] = get_y()
	mod.ui_widget.style.current_speed_text.font_size = text_font_size

	mod.ui_widget.style.avg_speed_text.offset[1] = get_x()
	mod.ui_widget.style.avg_speed_text.offset[2] = get_y() - text_font_size
	mod.ui_widget.style.avg_speed_text.font_size = text_font_size

	mod.ui_widget.style.last_dodge_distance_text.offset[1] = get_x()
	mod.ui_widget.style.last_dodge_distance_text.offset[2] = get_y() - (text_font_size * 2)
	mod.ui_widget.style.last_dodge_distance_text.font_size = text_font_size

	mod.ui_widget.style.last_dodge_dur_text.offset[1] = get_x()
	mod.ui_widget.style.last_dodge_dur_text.offset[2] = get_y() - (text_font_size * 3)
	mod.ui_widget.style.last_dodge_dur_text.font_size = text_font_size

	mod.ui_widget.style.dodging_text.offset[1] = get_x()
	mod.ui_widget.style.dodging_text.offset[2] = get_y() - (text_font_size * 4)
	mod.ui_widget.style.dodging_text.font_size = text_font_size

	mod.ui_widget.style.position_text.offset[1] = get_x()
	mod.ui_widget.style.position_text.offset[2] = get_y() - (text_font_size * 7)
	mod.ui_widget.style.position_text.font_size = text_font_size

	mod.ui_widget.style.player_height_text.offset[1] = get_x()
	mod.ui_widget.style.player_height_text.offset[2] = get_y() - (text_font_size * 8)
	mod.ui_widget.style.player_height_text.font_size = text_font_size

	mod.ui_widget.style.last_slide_distance_text.offset[1] = get_x()
	mod.ui_widget.style.last_slide_distance_text.offset[2] = get_y() - (text_font_size * 9)
	mod.ui_widget.style.last_slide_distance_text.font_size = text_font_size

	mod.ui_widget.style.last_slide_dur_text.offset[1] = get_x()
	mod.ui_widget.style.last_slide_dur_text.offset[2] = get_y() - (text_font_size * 10)
	mod.ui_widget.style.last_slide_dur_text.font_size = text_font_size

	mod.ui_widget.style.sliding_text.offset[1] = get_x()
	mod.ui_widget.style.sliding_text.offset[2] = get_y() - (text_font_size * 11)
	mod.ui_widget.style.sliding_text.font_size = text_font_size

	mod.ui_widget.style.sprinting_text.offset[1] = get_x()
	mod.ui_widget.style.sprinting_text.offset[2] = get_y() - (text_font_size * 13)
	mod.ui_widget.style.sprinting_text.font_size = text_font_size
end

local function get_player()
	local player_manager = Managers and Managers.player
	local player = player_manager and player_manager:local_player(1)

	return player
end

local function get_player_unit(player)
	local player = player or get_player()
	local player_unit = player and player:unit_is_alive() and player.player_unit

	return player_unit
end

local function is_sliding(unit)
	local unit_data_extension = unit
		and Unit.alive(unit)
		and ScriptUnit
		and ScriptUnit.has_extension(unit, "unit_data_system")

	if not unit_data_extension then
		return false
	end

	local breed = unit_data_extension:breed()

	if not Breed.is_player(breed) then
		return false
	end

	local movement_state_component = unit_data_extension:read_component("movement_state")
	local is_sliding = movement_state_component and movement_state_component.method == "sliding"

	return is_sliding
end

local function init()
	if mod.ui_widget then
		return
	end

	local world = Managers.world:world("level_world")
	if world then
		mod.ui_renderer = Managers.ui:create_renderer(mod_name .. "_ui_default_renderer", world)
		mod.ui_scenegraph = UIScenegraph.init_scenegraph(scenegraph_definition)
		mod.ui_widget = UIWidget.init(mod_name .. "_widget_definition", movement_debug_ui_definition)
	end
end

local function on_hud_update(hud, dt)
	local widget = mod.ui_widget
	local ui_renderer = mod.ui_renderer
	local ui_scenegraph = mod.ui_scenegraph

	local player = get_player()
	local player_unit = get_player_unit(player)
	if not player_unit then
		return
	end

	local locomotion_extension = player_unit and ScriptUnit.has_extension(player_unit, "locomotion_system")

	local current_speed
	local z

	if locomotion_extension then
		local current_velocity = locomotion_extension:current_velocity()
		z = current_velocity[3]
		current_speed = Vector3.length(Vector3.flat(current_velocity))
	end

	table.insert(queue, current_speed)
	if #queue > frames then
		table.remove(queue, 1)
	end
	local sum = 0
	for i = 1, #queue, 1 do
		sum = sum + queue[i]
	end
	local avg_speed = sum / frames
	-- mod:echo(avg_speed)

	--local average_velocity = GameSession.game_object_field(locomotion_extension._game_session, locomotion_extension._game_object_id, "average_velocity") or current_velocity
	--local average_speed = Vector3.length(average_velocity)
	--local move_direction = Vector3.normalize(locomotion_extension:current_velocity())

	local timer_text = string.format("%-15s: %.2f", "Current Speed", current_speed)
	widget.content.current_speed_text = timer_text
	widget.content.avg_speed_text = string.format("%-15s: %.2f", "Avg Speed", avg_speed)
	widget.content.last_dodge_distance_text = string.format("%s: %.2f", "Dodge Dist.", last_dodge_distance)
	widget.content.last_dodge_dur_text = string.format("%s: %.3fs", "Dodge Dur.", last_dodge_dur)
	if mod:get("show_dodge") then
		local dodgeState = (Dodge.is_dodging(player_unit) and "true") or "false"
		widget.content.dodging_text = "Dodging: " .. dodgeState
	else
		widget.content.dodging_text = ""
	end

	widget.content.last_slide_distance_text = string.format("%s: %.2f", "Slide Dist.", last_slide_distance)
	widget.content.last_slide_dur_text = string.format("%s: %.3fs", "Slide Dur.", last_slide_dur)
	if mod:get("show_slide") then
		local slideState = (is_sliding(player_unit) and "true") or "false"
		widget.content.sliding_text = "Sliding: " .. slideState
	else
		widget.content.sliding_text = ""
	end

	local unit_data_extension = ScriptUnit.has_extension(player_unit, "unit_data_system")
	local sprint_character_state_component = unit_data_extension:read_component("sprint_character_state")
	local sprint_state = Sprint.is_sprinting(sprint_character_state_component) and "true" or "false"
	widget.content.sprinting_text = "Sprinting: " .. sprint_state

	local cm = Managers.state.camera
	if cm then
		local vp_name = player and player.viewport_name

		if vp_name then
			local pos = cm:camera_position(vp_name)
			local rot = cm:camera_rotation(vp_name)
			local position_string = string.format(
				"Position(%.2f, %.2f, %.2f) Rotation(%.4f, %.4f, %.4f, %.4f)",
				pos.x,
				pos.y,
				pos.z,
				Quaternion.to_elements(rot)
			)

			widget.content.position_text = position_string
		end
	end

	local first_person_extension = player_unit and ScriptUnit.has_extension(player_unit, "first_person_system")

	if first_person_extension then
		local playerHeight = first_person_extension:default_height("default")
		widget.content.player_height_text = string.format("%s: %.2f Z-Speed: %.2f", "Height", playerHeight, z)
	end

	on_setting_changed()
	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, fake_input_service, dt, render_settings)
	UIWidget.draw(widget, ui_renderer)
	UIRenderer.end_pass(ui_renderer)

	if false then
		local debug_string = "MovementDebug: "
		debug_string = debug_string .. widget.content.current_speed_text .. ", "
		debug_string = debug_string .. widget.content.avg_speed_text .. ", "
		debug_string = debug_string .. widget.content.last_dodge_distance_text .. ", "
		debug_string = debug_string .. widget.content.last_dodge_dur_text .. ", "
		debug_string = debug_string .. widget.content.dodging_text .. ", "
		debug_string = debug_string .. widget.content.position_text .. ", "
		debug_string = debug_string .. widget.content.player_height_text .. ", "
		debug_string = debug_string .. widget.content.last_slide_distance_text .. ", "
		debug_string = debug_string .. widget.content.last_slide_dur_text .. ", "
		debug_string = debug_string .. widget.content.sliding_text
		mod:echo(debug_string)
	end
end

-- Get raycast position
-- From AussiemonCreatureSpawner
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
			local player_unit = get_player_unit()
			local ray_hit_self = player_unit and (hit_unit == player_unit)

			if not ray_hit_self then
				new_position = hit[1]
				break
			end
		end
	end

	return new_position
end

local function distToLookingAt()
	local player_unit = get_player_unit()
	local current_position = player_unit and Unit.local_position(player_unit, 1)

	if not current_position then
		mod:echo("Could not determine player position.")
		return
	end

	local player = get_player()
	local looking_at = player and position_at_cursor(player)
	if looking_at then
		mod:echo("Distance: " .. Vector3.distance(current_position, looking_at))
	else
		mod:echo("Distance: nil")
	end
end

mod.on_enabled = function()
	init()
	on_setting_changed()
end

mod.on_disabled = function(is_silent)
	if not mod.ui_renderer then
		return
	end
	Managers.ui:destroy_renderer(mod_name .. "_ui_default_renderer")

	mod.ui_renderer = nil
	mod.ui_scenegraph = nil
	mod.ui_widget = nil
end

-- ##########################################################
-- #################### Hooks ###############################

local ui_hud_file_name = "scripts/managers/ui/ui_hud"

mod:hook("UIHud", "update", function(func, self, dt, ...)
	local result = func(self, dt, ...)

	if mod:is_enabled() then
		if not mod.ui_widget then
			init()
		else
			on_hud_update(self, dt)
		end
	end

	return result
end)

mod:hook("UIHud", "destroy", function(func, self, ...)
	if mod:is_enabled() then
		mod.on_disabled()
	end

	return func(self, ...)
end)

-- Get Dodge Data
local dodge_file_name =
	"scripts/extension_systems/character_state_machine/character_states/player_character_state_dodging"

mod:hook("PlayerCharacterStateDodging", "on_enter", function(func, self, unit, ...)
	local result = func(self, unit, ...)

	local player_unit = get_player_unit()
	if player_unit and player_unit == unit then
		local start_pos = Unit.local_position(unit, 1)
		last_dodge_start_pos = { start_pos[1], start_pos[2], start_pos[3] }
		last_dodge_start_time = Managers.time:time("gameplay")
	end

	return result
end)

mod:hook("PlayerCharacterStateDodging", "on_exit", function(func, self, unit, ...)
	local result = func(self, unit, ...)

	local player_unit = get_player_unit()
	if player_unit and player_unit == unit then
		local end_pos = Unit.local_position(unit, 1)
		local start_pos = Vector3(last_dodge_start_pos[1], last_dodge_start_pos[2], last_dodge_start_pos[3])
		last_dodge_distance = Vector3.distance(start_pos, end_pos)
		local dodge_end_time = Managers.time:time("gameplay")
		last_dodge_dur = dodge_end_time - last_dodge_start_time
	end

	return result
end)

-- Get Slide Data
local slide_state_file_name =
	"scripts/extension_systems/character_state_machine/character_states/player_character_state_sliding"

mod:hook("PlayerCharacterStateSliding", "on_enter", function(func, self, unit, ...)
	local result = func(self, unit, ...)

	local player_unit = get_player_unit()
	if player_unit and player_unit == unit then
		local start_pos = Unit.local_position(unit, 1)
		last_slide_start_pos = { start_pos[1], start_pos[2], start_pos[3] }
		last_slide_start_time = Managers.time:time("gameplay")
	end

	return result
end)

mod:hook("PlayerCharacterStateSliding", "on_exit", function(func, self, unit, ...)
	local result = func(self, unit, ...)

	local player_unit = get_player_unit()
	if player_unit and player_unit == unit then
		local end_pos = Unit.local_position(unit, 1)
		local start_pos = Vector3(last_slide_start_pos[1], last_slide_start_pos[2], last_slide_start_pos[3])
		last_slide_distance = Vector3.distance(start_pos, end_pos)
		local slide_end_time = Managers.time:time("gameplay")
		last_slide_dur = slide_end_time - last_slide_start_time
	end

	return result
end)

-- Enable in meat grinder
local training_grounds_file_name = "scripts/managers/game_mode/game_modes/game_mode_training_grounds"

mod:hook_safe("GameModeTrainingGrounds", "_on_loading_finished", function()
	mod.on_enabled()
end)
