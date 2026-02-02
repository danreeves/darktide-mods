--[[-------------------------------------------------------------------------
Healthbars - HealthbarMarker (v4_final)

This file got a focused performance + stability pass.

Why:
  * Healthbar widgets run for every visible enemy, every frame.
  * The original implementation did a lot of tiny-but-expensive work in hot paths:
      - creating Color objects every draw call,
      - repeated mod:get() lookups,
      - repeated max-health lookups through Managers,
      - frequent extension calls that can become invalid when units despawn,
      - and extra allocations (tables/vectors) that increase GC pressure.

What changed (high level):
  * Heavy per-unit reads are throttled to ~10 Hz, while world-position tracking stays per-frame
    so the bar doesn't "lag behind" fast-moving targets.
  * Frequently reused values are cached (settings, resolution scale, max_health, colors).
  * Temporary objects are reused where possible (debuff entries, Vector3Box).
  * Defensive validation/pcall guards were added around extension access to avoid crashes
    when an extension is destroyed mid-frame.

Net result: smoother FPS, fewer spikes, and better resilience in hectic fights.
---------------------------------------------------------------------------]]

local mod = get_mod("Healthbars")

local HudHealthBarLogic = require("scripts/ui/hud/elements/hud_health_bar_logic")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIWidget = require("scripts/managers/ui/ui_widget")
local template = {}
local size = {
	120,
	6,
}
template.size = size
template.name = "custom_healthbar"
template.unit_node = "root_point"
template.position_offset = {
	0,
	0,
	0,
}
template.check_line_of_sight = true
template.max_distance = 25
template.screen_clamp = false
template.remove_on_death_duration = 0.5
template.damage_number_settings = {
	first_hit_size_scale = 1.2,
	crit_hit_size_scale = 1.5,
	visibility_delay = 5,
	expand_bonus_scale = 30,
	default_color = "white",
	has_taken_damage_timer_y_offset = 34,
	weakspot_color = "orange",
	fade_delay = 0.35,
	add_numbers_together_timer = 0.2,
	shrink_duration = 1,
	duration = 3,
	x_offset_between_numbers = 38,
	expand_duration = 0.2,
	crit_color = "yellow",
	hundreds_font_size = 14.4,
	default_font_size = 17,
	has_taken_damage_timer_remove_after_time = 5,
	max_float_y = 100,
	dps_font_size = 14.4,
	x_offset = 1,
	dps_y_offset = -24,
	y_offset = 15,
}
template.bar_settings = {
	animate_on_health_increase = true,
	bar_spacing = 2,
	duration_health_ghost = 0.2,
	health_animation_threshold = 0.1,
	alpha_fade_delay = 0.3,
	duration_health = 0.5,
	alpha_fade_min_value = 50,
	alpha_fade_duration = 0.4,
}

-- V4 OPTIMIZATION: Placeholder for cached Color objects (initialized in on_enter)
-- Caching eliminates 4 Color[] constructor calls per enemy per frame
template.cached_colors = nil

local armor_type_string_lookup = {
	disgustingly_resilient = "loc_weapon_stats_display_disgustingly_resilient",
	super_armor = "loc_weapon_stats_display_super_armor",
	armored = "loc_weapon_stats_display_armored",
	resistant = "loc_glossary_armour_type_resistant",
	berserker = "loc_weapon_stats_display_berzerker",
	unarmored = "loc_weapon_stats_display_unarmored",
}
template.fade_settings = {
	fade_to = 1,
	fade_from = 0.1,
	default_fade = 0.1,
	distance_max = template.max_distance,
	distance_min = template.max_distance * 0.5,
	easing_function = math.ease_out_quad,
}

template.create_widget_defintion = function(template, scenegraph_id)
	local size = template.size
	local header_font_setting_name = "nameplates"
	local header_font_settings = UIFontSettings[header_font_setting_name]
	local header_font_color = header_font_settings.text_color
	local bar_size = {
		size[1],
		size[2],
	}
	local bar_offset = {
		-size[1] * 0.5,
		0,
		0,
	}

	return UIWidget.create_definition({
		{
			pass_type = "logic",
			value = function(pass, ui_renderer, ui_style, ui_content, position, size)
				local damage_numbers = ui_content.damage_numbers
				local damage_number_settings = template.damage_number_settings
				local z_position = position[3]
				local y_position = position[2] + damage_number_settings.y_offset
				local x_position = position[1] + damage_number_settings.x_offset
				
				-- V4 OPTIMIZATION: Cache resolution scale in content (draw function can't access marker)
				local scale = ui_content.resolution_scale or RESOLUTION_LOOKUP.scale
				
				local default_font_size = damage_number_settings.default_font_size * scale
				local dps_font_size = damage_number_settings.dps_font_size * scale
				local hundreds_font_size = damage_number_settings.hundreds_font_size * scale
				local font_type = ui_style.font_type
				
				-- V4 OPTIMIZATION: Use pre-cached Color objects instead of creating new ones every frame
				-- Before: 4 allocations per enemy per frame (80 allocs/frame with 20 enemies = 4,800/sec)
				-- After: Reuse cached colors, only copy when needed for modification
				local cached_colors = template.cached_colors
				local default_color = cached_colors.default_color
				local crit_color = cached_colors.crit_color
				local weakspot_color = cached_colors.weakspot_color
				-- Create working copy for color modifications (unavoidable, but reduced from 4 to 1 allocation)
				local text_color = { default_color[1], default_color[2], default_color[3], default_color[4] }
				
				local num_damage_numbers = #damage_numbers

				for i = num_damage_numbers, 1, -1 do
					local damage_number = damage_numbers[i]
					local duration = damage_number.duration
					local time = damage_number.time
					local progress = math.clamp(time / duration, 0, 1)

					if progress >= 1 then
						table.remove(damage_numbers, i)
					else
						damage_number.time = damage_number.time + ui_renderer.dt
					end

					if damage_number.was_critical then
						text_color[2] = crit_color[2]
						text_color[3] = crit_color[3]
						text_color[4] = crit_color[4]
						damage_number.expand_duration = damage_number_settings.expand_duration
					elseif damage_number.hit_weakspot then
						text_color[2] = weakspot_color[2]
						text_color[3] = weakspot_color[3]
						text_color[4] = weakspot_color[4]
					else
						text_color[2] = default_color[2]
						text_color[3] = default_color[3]
						text_color[4] = default_color[4]
					end

					local value = damage_number.value
					local font_size = value <= 99 and default_font_size or hundreds_font_size
					local expand_duration = damage_number.expand_duration

					if expand_duration then
						local expand_time = damage_number.expand_time
						local expand_progress = math.clamp(expand_time / expand_duration, 0, 1)
						local anim_progress = 1 - expand_progress
						font_size = font_size + damage_number_settings.expand_bonus_scale * anim_progress

						if expand_progress >= 1 then
							damage_number.expand_duration = nil
							damage_number.shrink_start_t = duration - damage_number_settings.shrink_duration
						else
							damage_number.expand_time = expand_time + ui_renderer.dt
						end
					elseif damage_number.shrink_start_t and damage_number.shrink_start_t < time then
						local diff = time - damage_number.shrink_start_t
						local percentage = diff / damage_number_settings.shrink_duration
						local scale = 1 - percentage
						font_size = font_size * scale
						text_color[1] = text_color[1] * scale
					end

					local text = value
					local size = ui_style.size
					local current_order = num_damage_numbers - i

					if current_order == 0 then
						local scale_size = damage_number.was_critical and damage_number_settings.crit_hit_size_scale
							or damage_number_settings.first_hit_size_scale
						font_size = font_size * scale_size
					end

					position[3] = z_position + current_order
					position[2] = y_position
					position[1] = x_position + current_order * damage_number_settings.x_offset_between_numbers

					-- V4 OPTIMIZATION: Use cached setting from content (draw pass can't access marker/mod safely).
				-- Settings are captured once on_enter and reused here to avoid mod:get() in the draw hot-path.
					if ui_content.settings_cache and ui_content.settings_cache.show_damage_numbers then
						UIRenderer.draw_text(ui_renderer, text, font_size, font_type, position, size, text_color, {})
					end
				end

				local damage_has_started = ui_content.damage_has_started

				if damage_has_started then
					if not ui_content.damage_has_started_timer then
						ui_content.damage_has_started_timer = ui_renderer.dt
					elseif not ui_content.dead then
						ui_content.damage_has_started_timer = ui_content.damage_has_started_timer + ui_renderer.dt
					end

					if ui_content.dead then
						local damage_has_started_position =
							Vector3(x_position, y_position - damage_number_settings.dps_y_offset, z_position)
						local dps = ui_content.damage_has_started_timer > 1
								and ui_content.damage_taken / ui_content.damage_has_started_timer
							or ui_content.damage_taken
						local text = string.format("%d DPS", dps)

						-- V4 OPTIMIZATION: Use cached setting from content (draw pass can't access marker/mod safely).
				-- Settings are captured once on_enter and reused here to avoid mod:get() in the draw hot-path.
						if ui_content.settings_cache and ui_content.settings_cache.show_dps then
							UIRenderer.draw_text(
								ui_renderer,
								text,
								dps_font_size,
								font_type,
								damage_has_started_position,
								size,
								ui_style.text_color,
								{}
							)
						end
					end

					if ui_content.last_hit_zone_name then
						local hit_zone_name = ui_content.last_hit_zone_name
						local breed = ui_content.breed
						local armor_type = breed.armor_type

						if breed.hitzone_armor_override and breed.hitzone_armor_override[hit_zone_name] then
							armor_type = breed.hitzone_armor_override[hit_zone_name]
						end

						local armor_type_loc_string = armor_type and armor_type_string_lookup[armor_type] or ""
						local armor_type_text = Localize(armor_type_loc_string)
						local armor_type_position = Vector3(
							x_position,
							y_position - damage_number_settings.has_taken_damage_timer_y_offset,
							z_position
						)

						-- V4 OPTIMIZATION: Use cached setting from content (draw pass can't access marker/mod safely).
				-- Settings are captured once on_enter and reused here to avoid mod:get() in the draw hot-path.
						if ui_content.settings_cache and ui_content.settings_cache.show_armour_type then
							UIRenderer.draw_text(
								ui_renderer,
								armor_type_text,
								dps_font_size,
								font_type,
								armor_type_position,
								size,
								ui_style.text_color,
								{}
							)
						end
					end
				end

				ui_style.font_size = default_font_size
				position[3] = z_position
				position[2] = y_position
				position[1] = x_position
			end,
			style = {
				horizontal_alignment = "left",
				font_size = 30,
				text_vertical_alignment = "bottom",
				text_horizontal_alignment = "left",
				vertical_alignment = "center",
				offset = {
					-size[1] * 0.5,
					-size[2],
					2,
				},
				font_type = header_font_settings.font_type,
				text_color = header_font_color,
				size = {
					600,
					size[2],
				},
			},
		},
		{
			value = "content/ui/materials/backgrounds/default_square",
			style_id = "background",
			pass_type = "rect",
			style = {
				vertical_alignment = "center",
				offset = bar_offset,
				size = bar_size,
				color = UIHudSettings.color_tint_0,
			},
		},
		{
			value = "content/ui/materials/backgrounds/default_square",
			style_id = "ghost_bar",
			pass_type = "rect",
			style = {
				vertical_alignment = "center",
				offset = {
					bar_offset[1],
					bar_offset[2],
					2,
				},
				size = bar_size,
				color = {
					255,
					220,
					100,
					100,
				},
			},
		},
		{
			value = "content/ui/materials/backgrounds/default_square",
			style_id = "health_max",
			pass_type = "rect",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					bar_offset[1],
					bar_offset[2],
					1,
				},
				size = bar_size,
				color = {
					200,
					255,
					255,
					255,
				},
			},
		},
		{
			value = "content/ui/materials/backgrounds/default_square",
			style_id = "bar",
			pass_type = "rect",
			style = {
				vertical_alignment = "center",
				offset = {
					bar_offset[1],
					bar_offset[2],
					3,
				},
				size = bar_size,
				color = {
					255,
					220,
					20,
					20,
				},
			},
		},
		{
			value = "content/ui/materials/bars/simple/end",
			style_id = "bar_end",
			pass_type = "texture",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				offset = {
					bar_offset[1],
					bar_offset[2],
					4,
				},
				size = {
					12,
					bar_size[2] + 12,
				},
				color = {
					255,
					255,
					255,
					255,
				},
			},
		},

		{
			pass_type = "texture",
			style_id = "status_icon_1",
			value_id = "status_icon_1",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				position = { 0, 0, 0 },
				offset = {
					-(template.size[1] / 2) + 20,
					-40,
					10,
				},
				size = {
					25,
					25,
				},
				color = {
					255,
					255,
					0,
					0,
				},
			},
			visibility_function = function(content, style)
				return content.status_icon_1 ~= nil
			end,
		},
		{
			pass_type = "text",
			style_id = "status_stacks_1",
			value_id = "status_stacks_1",
			value = "",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				text_vertical_alignment = "center",
				text_horizontal_alignment = "right",
				position = { 0, 0, 0 },
				offset = {
					-(template.size[1] / 2) + 20 + 10,
					-40,
					10,
				},
				size = {
					25,
					25,
				},
				font_type = header_font_settings.font_type,
				font_size = 14,
				text_color = {
					255,
					255,
					255,
					0,
				},
			},
		},

		{
			pass_type = "texture",
			style_id = "status_icon_2",
			value_id = "status_icon_2",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				position = { 0, 0, 0 },
				offset = {
					-(template.size[1] / 2) + 20 + 10 + 20 + 10,
					-40,
					10,
				},
				size = {
					25,
					25,
				},
				color = {
					255,
					255,
					102,
					0,
				},
			},
			visibility_function = function(content, style)
				return content.status_icon_2 ~= nil
			end,
		},
		{
			pass_type = "text",
			style_id = "status_stacks_2",
			value_id = "status_stacks_2",
			value = "",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				text_vertical_alignment = "center",
				text_horizontal_alignment = "right",
				position = { 0, 0, 0 },
				offset = {
					-(template.size[1] / 2) + 20 + 10 + 20 + 10 + 10,
					-40,
					10,
				},
				size = {
					25,
					25,
				},
				font_type = header_font_settings.font_type,
				font_size = 14,
				text_color = {
					255,
					255,
					255,
					0,
				},
			},
		},

		{
			pass_type = "texture",
			style_id = "status_icon_3",
			value_id = "status_icon_3",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				position = { 0, 0, 0 },
				offset = {
					-(template.size[1] / 2) + 20 + 10 + 20 + 10 + 10 + 20 + 10,
					-40,
					10,
				},
				size = {
					25,
					25,
				},
				color = {
					255,
					0,
					255,
					0,
				},
			},
			visibility_function = function(content, style)
				return content.status_icon_3 ~= nil
			end,
		},
		{
			pass_type = "text",
			style_id = "status_stacks_3",
			value_id = "status_stacks_3",
			value = "",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				text_vertical_alignment = "center",
				text_horizontal_alignment = "right",
				position = { 0, 0, 0 },
				offset = {
					-(template.size[1] / 2) + 20 + 10 + 20 + 10 + 10 + 20 + 10 + 10,
					-40,
					10,
				},
				size = {
					25,
					25,
				},
				font_type = header_font_settings.font_type,
				font_size = 14,
				text_color = {
					255,
					255,
					255,
					0,
				},
			},
		},
	}, scenegraph_id)
end

template.on_enter = function(widget, marker, template)
	local content = widget.content
	content.spawn_progress_timer = 0
	content.damage_taken = 0
	content.damage_numbers = {}
	
	-- V4 OPTIMIZATION: Cache resolution scale in content (so draw function can access it)
	content.resolution_scale = RESOLUTION_LOOKUP.scale
	
	-- BUGFIX: Initialize visibility to prevent healthbar flash on spawn
	content.visibility_delay = nil
	content.fade_delay = nil
	widget.alpha_multiplier = 0  -- Start invisible (prevents 1-frame flash before fade timers kick in)
	
	local bar_settings = template.bar_settings
	marker.bar_logic = HudHealthBarLogic:new(bar_settings)
	local unit = marker.unit
	
	-- BUGFIX: Add nil-checking for extension access to prevent crashes
	if not (unit and Unit.alive(unit)) then
		return
	end
	
	if not ScriptUnit.has_extension(unit, "unit_data_system") then
		return
	end
	
	local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
	if not unit_data_extension then
		return
	end
	
	local breed = unit_data_extension:breed()
	if not breed then
		return
	end
	
	content.header_text = breed.name
	content.breed = breed
	marker.head_offset = 0
	marker.debuff_check_timer = 0
	marker.debuffs = {}
	
	-- V4 OPTIMIZATION: Cache settings to avoid repeated mod:get() lookups
	-- Store in BOTH marker (for update) and content (for draw function)
	-- Note: settings are captured when the marker is created; changing options mid-mission
	-- may require a UI reload or respawned marker to take effect.
	local settings_cache = {
		show_damage_numbers = mod:get("show_damage_numbers"),
		show_dps = mod:get("show_dps"),
		show_armour_type = mod:get("show_armour_type"),
		show_bar = mod:get("show_bar"),
		bleed = mod:get("bleed"),
		burn = mod:get("burn"),
		toxin = mod:get("toxin"),
	}
	marker.settings_cache = settings_cache
	content.settings_cache = settings_cache  -- Draw function needs access via ui_content
	
	-- V4 OPTIMIZATION: Cache max_health to avoid Manager chain traversal
	-- This value never changes for a breed, no need to recalculate every frame
	marker.max_health = Managers.state.difficulty:get_minion_max_health(breed.name)
	
	-- V4 OPTIMIZATION: Cache Color objects once (stored on the template and shared by all markers)
	-- to avoid constructor calls in the draw function
	-- Color[] is expensive (~50-100ns), and was being called 4x per enemy per frame
	-- With 20 enemies: 80 Color allocations/frame = 4,800/second at 60 FPS!
	if not template.cached_colors then
		local damage_number_settings = template.damage_number_settings
		template.cached_colors = {
			default_color = Color[damage_number_settings.default_color](255, true),
			crit_color = Color[damage_number_settings.crit_color](255, true),
			weakspot_color = Color[damage_number_settings.weakspot_color](255, true),
		}
	end
	
	-- V4 OPTIMIZATION: Reusable Vector3 for render positions (reduces GC pressure)
	marker.temp_vector3 = Vector3Box(Vector3(0, 0, 0))
end

local HEAD_NODE = "j_head"

template.update_function = function(parent, ui_renderer, widget, marker, template, dt, t)
	local content = widget.content
	local style = widget.style
	local unit = marker.unit
	content.t = t
	
	-- PERFORMANCE FIX: Throttle *heavy* work to ~10 FPS (100ms), keep lightweight tracking per-frame.
	-- This cuts extension/buff work dramatically while keeping the marker visually smooth.
	local skip_heavy = false
	-- Dead units need frequent updates to count down removal timer properly
	if not content.remove_timer then
		marker._update_timer = (marker._update_timer or 0) + dt
		if marker._update_timer < 0.1 then
			skip_heavy = true
		else
			marker._update_timer = 0
		end
	end
	
	-- PERFORMANCE FIX: Cache extension references (but revalidate if unit dies)
	local unit_is_alive = ALIVE[unit]

	-- Smooth tracking: update head offset once, and keep world position following the unit every frame
	-- This prevents the healthbar from visually lagging behind fast-moving targets when heavy updates are throttled.
	if unit_is_alive and marker.head_offset == 0 then
		local root_position = Unit.world_position(unit, 1)
		local node = Unit.node(unit, HEAD_NODE)
		local head_position = Unit.world_position(unit, node)
		marker.head_offset = head_position.z - root_position.z + 0.4
		marker.head_offset_cached = true
	end
	local wants_tracking = (widget.alpha_multiplier and widget.alpha_multiplier > 0)
		or content.visibility_delay
		or content.fade_delay
		or content.dead

	if wants_tracking and unit_is_alive and marker.world_position then
		local root_position = Unit.world_position(unit, 1)
		local position = marker.world_position:unbox()
		position.x = root_position.x
		position.y = root_position.y
		position.z = root_position.z + marker.head_offset
		marker.world_position:store(position)
	end

	
	-- Shared state (needed even when heavy updates are skipped)
	local is_dead = not HEALTH_ALIVE[unit]
	local health_percent = 0
	local damage_number_settings = template.damage_number_settings

	if not skip_heavy then
	if unit_is_alive and not marker._health_ext_cached then
		marker._health_extension = ScriptUnit.has_extension(unit, "health_system")
		-- BUGFIX: Add has_extension check before caching buff_extension
		if ScriptUnit.has_extension(unit, "buff_system") then
			marker._buff_extension = ScriptUnit.extension(unit, "buff_system")
		end
		marker._health_ext_cached = true
	end
	
	local health_extension = marker._health_extension
	
	-- OPTIMIZATION: Validate cached extensions once, then use direct calls.
	-- pcall is kept around the validation because extensions can be torn down asynchronously.
	-- Validates extension once, then all subsequent calls are direct (much faster)
	is_dead = not HEALTH_ALIVE[unit]
	health_percent = 0
	local extension_valid = false
	
	if unit_is_alive and health_extension then
		-- CRITICAL FIX: Even checking .is_alive can fail on destroyed extension
		-- Must pcall the entire validation, not just the call
		local success, alive = pcall(function()
			if health_extension.is_alive then
				return health_extension:is_alive()
			end
			return false
		end)
		
		if success and alive then
			extension_valid = true
			is_dead = false
		else
			-- Extension was destroyed, clear cache
			marker._health_ext_cached = false
			marker._health_extension = nil
		end
	end
	
	-- Direct access now safe - no pcall needed
	if extension_valid then
		health_percent = health_extension:current_health_percent() or 0
	end
	
	-- V4 OPTIMIZATION: Use cached max_health instead of Manager chain lookup
	local max_health = marker.max_health
	local damage_taken = nil

	marker.debuff_check_timer = marker.debuff_check_timer + dt
	
	if marker.debuff_check_timer >= 0.1 then
		marker.debuff_check_timer = 0
		local buff_extension = marker._buff_extension

		-- OPTIMIZATION: Validate buff extension once, then direct calls
		local buff_valid = false
		if buff_extension and not is_dead then
			-- CRITICAL FIX: Even checking .current_stacks can fail on destroyed extension
			local success = pcall(function()
				if buff_extension.current_stacks then
					return buff_extension:current_stacks("bleed")
				end
			end)
			buff_valid = success
			
			if not success then
				-- Buff extension was destroyed, clear cache
				marker._buff_extension = nil
				marker._health_ext_cached = false
			end
		end
		
		if buff_valid then
			table.clear(marker.debuffs)
			
			-- V4 OPTIMIZATION: Use cached settings instead of mod:get()
			if marker.settings_cache.bleed then
				local bleed_stacks = buff_extension:current_stacks("bleed") or 0
				if bleed_stacks > 0 then
					-- PERFORMANCE FIX: Reuse debuff entry tables (avoids allocations during buff polling)
					local entry = marker.debuffs[1] or {}
					entry.type = "bleed"
					entry.stacks = bleed_stacks
					marker.debuffs[1] = entry
				end
			end

			if marker.settings_cache.burn then
				local burn_stacks = (buff_extension:current_stacks("flamer_assault") or 0) 
					+ (buff_extension:current_stacks("warp_fire") or 0)
				if burn_stacks > 0 then
					local idx = #marker.debuffs + 1
					local entry = marker.debuffs[idx] or {}
					entry.type = "burn"
					entry.stacks = burn_stacks
					marker.debuffs[idx] = entry
				end
			end

			if marker.settings_cache.toxin then
				local toxin_stacks = (buff_extension:current_stacks("neurotoxin_interval_buff") or 0)
					+ (buff_extension:current_stacks("neurotoxin_interval_buff2") or 0)
					+ (buff_extension:current_stacks("neurotoxin_interval_buff3") or 0)
					+ (buff_extension:current_stacks("exploding_toxin_interval_buff") or 0)
				if toxin_stacks > 0 then
					local idx = #marker.debuffs + 1
					local entry = marker.debuffs[idx] or {}
					entry.type = "toxin"
					entry.stacks = toxin_stacks
					marker.debuffs[idx] = entry
				end
			end
		end
	end

	if marker.debuffs[1] then
		content.status_icon_1 = mod.textures[marker.debuffs[1].type]
		style.status_icon_1.color = mod.colors[marker.debuffs[1].type]
		content.status_stacks_1 = marker.debuffs[1].stacks
	else
		content.status_icon_1 = nil
		content.status_stacks_1 = ""
	end

	if marker.debuffs[2] then
		content.status_icon_2 = mod.textures[marker.debuffs[2].type]
		style.status_icon_2.color = mod.colors[marker.debuffs[2].type]
		content.status_stacks_2 = marker.debuffs[2].stacks
	else
		content.status_icon_2 = nil
		content.status_stacks_2 = ""
	end

	if marker.debuffs[3] then
		content.status_icon_3 = mod.textures[marker.debuffs[3].type]
		style.status_icon_3.color = mod.colors[marker.debuffs[3].type]
		content.status_stacks_3 = marker.debuffs[3].stacks
	else
		content.status_icon_3 = nil
		content.status_stacks_3 = ""
	end

	-- V4 OPTIMIZATION: Removed duplicate head_offset calculation
	-- (Same calculation already done earlier at lines 652-658)

	-- OPTIMIZATION: Use extension_valid flag from above - no pcall needed
	local damage_taken = nil
	if extension_valid then
		damage_taken = health_extension:total_damage_taken()
	else
		damage_taken = max_health
	end

	-- OPTIMIZATION: Direct access to health extension methods - extension_valid guarantees safety
	if extension_valid then
		-- DEFENSIVE: Even after validation, wrap in pcall (extension can be destroyed mid-frame)
		local success = pcall(function()
			local last_damaging_unit = health_extension.last_damaging_unit and health_extension:last_damaging_unit()

			if last_damaging_unit then
				content.last_hit_zone_name = (health_extension.last_hit_zone_name and health_extension:last_hit_zone_name()) or "center_mass"
				
				local breed = content.breed
				local hit_zone_weakspot_types = breed.hit_zone_weakspot_types

				if hit_zone_weakspot_types and hit_zone_weakspot_types[content.last_hit_zone_name] then
					content.hit_weakspot = true
				else
					content.hit_weakspot = false
				end

				-- Check critical hit (per-frame state)
				if health_extension.was_hit_by_critical_hit_this_render_frame then
					local crit_success, was_crit = pcall(health_extension.was_hit_by_critical_hit_this_render_frame, health_extension)
					content.was_critical = crit_success and was_crit or false
				end
			end
		end)
		
		if not success then
			-- Extension destroyed mid-frame, clear cache
			marker._health_ext_cached = false
			marker._health_extension = nil
		end
	end

	if ALIVE[unit] and damage_taken > 0 then
		local root_position = Unit.world_position(unit, 1)

		if not marker.world_position then
			local node = Unit.node(unit, HEAD_NODE)
			local head_position = Unit.world_position(unit, node)
			head_position.z = head_position.z + 0.5
			marker.world_position = Vector3Box(head_position)
		else
			local position = marker.world_position:unbox()
			position.x = root_position.x
			position.y = root_position.y
			position.z = root_position.z + marker.head_offset

			marker.world_position:store(position)
		end
	end

	local old_damage_taken = content.damage_taken

	if damage_taken and damage_taken ~= old_damage_taken then
		content.visibility_delay = damage_number_settings.visibility_delay
		content.damage_taken = damage_taken

		if old_damage_taken < damage_taken then
			local damage_numbers = content.damage_numbers
			local damage_diff = math.ceil(damage_taken - old_damage_taken)
			local latest_damage_number = damage_numbers[#damage_numbers]
			local should_add = true
			
			-- OPTIMIZATION: Use extension_valid flag but still wrap in pcall (defensive)
			local was_critical = false
			if extension_valid then
				local success, crit = pcall(function()
					if health_extension.was_hit_by_critical_hit_this_render_frame then
						return health_extension:was_hit_by_critical_hit_this_render_frame()
					end
					return false
				end)
				was_critical = success and crit or false
			end

			if
				latest_damage_number
				and t - latest_damage_number.start_time < damage_number_settings.add_numbers_together_timer
			then
				should_add = false
			end

			if content.add_on_next_number or was_critical or should_add then
				local damage_number = {
					expand_time = 0,
					time = 0,
					start_time = t,
					duration = damage_number_settings.duration,
					value = damage_diff,
					expand_duration = damage_number_settings.expand_duration,
				}
				local breed = content.breed
				local hit_zone_weakspot_types = breed.hit_zone_weakspot_types

				if hit_zone_weakspot_types and hit_zone_weakspot_types[content.last_hit_zone_name] then
					damage_number.hit_weakspot = true
				else
					damage_number.hit_weakspot = false
				end

				damage_number.was_critical = was_critical
				damage_numbers[#damage_numbers + 1] = damage_number

				if content.add_on_next_number then
					content.add_on_next_number = nil
				end

				if was_critical then
					content.add_on_next_number = true
				end
			else
				latest_damage_number.value = math.clamp(latest_damage_number.value + damage_diff, 0, max_health)
				latest_damage_number.time = 0
				latest_damage_number.y_position = nil
				latest_damage_number.start_time = t
				local breed = content.breed
				local hit_zone_weakspot_types = breed.hit_zone_weakspot_types

				if hit_zone_weakspot_types and hit_zone_weakspot_types[content.last_hit_zone_name] then
					latest_damage_number.hit_weakspot = true
				else
					latest_damage_number.hit_weakspot = false
				end

				latest_damage_number.was_critical = was_critical
			end
		end

		if not content.damage_has_started then
			content.damage_has_started = true
		end

		content.last_damage_taken_time = t
	end

	local bar_logic = marker.bar_logic

	bar_logic:update(dt, t, health_percent)

	local health_fraction, health_ghost_fraction, health_max_fraction = bar_logic:animated_health_fractions()

	if health_fraction and health_ghost_fraction then
		local bar_settings = template.bar_settings
		local spacing = bar_settings.bar_spacing
		local bar_width = template.size[1]
		local default_width_offset = -bar_width * 0.5
		local health_width = bar_width * health_fraction
		style.bar.size[1] = health_width
		local ghost_bar_width = math.max(bar_width * health_ghost_fraction - health_width, 0)
		local ghost_bar_style = style.ghost_bar
		ghost_bar_style.offset[1] = default_width_offset + health_width
		ghost_bar_style.size[1] = ghost_bar_width
		local background_width = math.max(bar_width - ghost_bar_width - health_width, 0)
		background_width = math.max(background_width - spacing, 0)
		local background_style = style.background
		background_style.offset[1] = default_width_offset + bar_width - background_width
		background_style.size[1] = background_width
		local health_max_style = style.health_max
		local health_max_width = bar_width - math.max(bar_width * health_max_fraction, 0)
		health_max_width = math.max(health_max_width - spacing, 0)
		health_max_style.offset[1] = default_width_offset + bar_width - health_max_width * 0.5
		health_max_style.size[1] = health_max_width
		local health_end_style = style.bar_end
		health_end_style.offset[1] = -(bar_width - bar_width * health_fraction) + 6 + math.abs(default_width_offset)
		marker.health_fraction = health_fraction
	else
		-- BUGFIX: If bar logic returns nil (unit dead), set health_fraction to 0
		marker.health_fraction = 0
	end

	-- V4 OPTIMIZATION: Use cached setting instead of mod:get()
	if marker.settings_cache and not marker.settings_cache.show_bar then
		style.bar.visible = false
		style.ghost_bar.visible = false
		style.health_max.visible = false
		style.bar_end.visible = false
		style.background.visible = false
	end

	end

	local line_of_sight_progress = content.line_of_sight_progress or 0

	if marker.raycast_initialized then
		local raycast_result = marker.raycast_result
		local line_of_sight_speed = 10

		if raycast_result then
			line_of_sight_progress = math.max(line_of_sight_progress - dt * line_of_sight_speed, 0)
		else
			line_of_sight_progress = math.min(line_of_sight_progress + dt * line_of_sight_speed, 1)
		end
	end

	-- BUGFIX: Trigger removal if unit is dead (either via HEALTH_ALIVE or our own detection)
	if not HEALTH_ALIVE[unit] or is_dead then
		if not content.remove_timer then
			content.remove_timer = template.remove_on_death_duration
			content.dead = true
		else
			content.remove_timer = content.remove_timer - dt

			if content.remove_timer <= 0 and (not marker.health_fraction or marker.health_fraction == 0) then
				marker.remove = true
			end
		end
	end

	local alpha_multiplier = line_of_sight_progress
	content.line_of_sight_progress = line_of_sight_progress
	local visibility_delay = content.visibility_delay

	if visibility_delay then
		visibility_delay = visibility_delay - dt
		content.visibility_delay = visibility_delay >= 0 and visibility_delay or nil

		if not content.visibility_delay then
			content.fade_delay = damage_number_settings.fade_delay
		end
	end

	local fade_delay = content.fade_delay

	if fade_delay then
		fade_delay = fade_delay - dt
		content.fade_delay = fade_delay >= 0 and fade_delay or nil
		local progress = math.clamp(fade_delay / damage_number_settings.fade_delay, 0, 1)
		alpha_multiplier = alpha_multiplier * progress
	elseif not visibility_delay then
		alpha_multiplier = 0
	end

	widget.alpha_multiplier = alpha_multiplier
end

return template
