local mod = get_mod("Healthbars")

local HudHealthBarLogic = require("scripts/ui/hud/elements/hud_health_bar_logic")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIWidget = require("scripts/managers/ui/ui_widget")

local template = {}

local size = { 120, 6 }
template.size = size
template.name = "custom_healthbar"
template.unit_node = "root_point"
template.position_offset = { 0, 0, 0 }
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

-- ---------------------------------------------------------------------------
-- UI helpers
-- ---------------------------------------------------------------------------

local function _slot_right_edge(template, slot_index)
	local base_right = -(template.size[1] / 2) + 20
	return base_right + (slot_index - 1) * 40
end

local function _set_rgb(dst, src)
	dst[2], dst[3], dst[4] = src[2], src[3], src[4]
end

-- ---------------------------------------------------------------------------
-- Debuff layout
-- ---------------------------------------------------------------------------

local MAX_DEBUFF_SLOTS_ALLOC = 12 -- maximum number of slots

local ICON_SIZE = 25
local GRID_COLS = 4
local GRID_GAP_X = 4
local GRID_GAP_Y = 4
local BAR_TO_DEBUFF_MARGIN_Y = 5

local function _slot_pos(template, slot_index)
  local cols = GRID_COLS
  local col  = (slot_index - 1) % cols
  local row  = math.floor((slot_index - 1) / cols)

  -- left edge of the bar is -width/2 in the widget's local space
  local bar_left_x = -(template.size[1] * 0.5)

  -- place first icon starting at bar-left, then to the right
  local x = bar_left_x + (ICON_SIZE * 0.5) + col * (ICON_SIZE + GRID_GAP_X)

  -- base y directly under the bar (negative is "down")
  local base_y = -((template.size[2] * 0.5) + BAR_TO_DEBUFF_MARGIN_Y + (ICON_SIZE * 0.5))

  -- in case armour type display is active move row up
  if mod:get("show_damage_numbers") and mod:get("show_armour_type") then
      base_y = base_y - 20
  end

  -- IMPORTANT: row 2 must be BELOW row 1 => y becomes MORE negative
  local y = base_y - row * (ICON_SIZE + GRID_GAP_Y)

  return x, y
end

local function _debuff_signature(debuffs)
	local parts = {}
	for i = 1, #debuffs do
		local d = debuffs[i]
		if d then
			local v = d.stacks or d.percent or ""
			parts[#parts + 1] = string.format("%s:%s", d.type or "?", tostring(v))
		end
	end
	return table.concat(parts, "|")
end

-- ---------------------------------------------------------------------------
-- Damage number rendering (logic pass)
-- ---------------------------------------------------------------------------

local function _draw_damage_numbers(template, mod, ui_renderer, ui_style, ui_content, position)
	if not mod:get("show_damage_numbers") then
		return
	end

	local settings = template.damage_number_settings
	local damage_numbers = ui_content.damage_numbers
	local num = #damage_numbers
	if num == 0 then
		return
	end

	local dt = ui_renderer.dt
	local scale = RESOLUTION_LOOKUP.scale

	local default_font_size = settings.default_font_size * scale
	local dps_font_size = settings.dps_font_size * scale
	local hundreds_font_size = settings.hundreds_font_size * scale
	local font_type = ui_style.font_type

	local default_color = Color[settings.default_color](255, true)
	local crit_color = Color[settings.crit_color](255, true)
	local weakspot_color = Color[settings.weakspot_color](255, true)

	local text_color = table.clone(default_color)

	local z0 = position[3]
	local x0 = position[1] + settings.x_offset
	local y0 = position[2] + settings.y_offset

	for i = num, 1, -1 do
		local dn = damage_numbers[i]
		local progress = math.clamp(dn.time / dn.duration, 0, 1)

		if progress >= 1 then
			table.remove(damage_numbers, i)
		else
			dn.time = dn.time + dt
		end

		if dn.was_critical then
			_set_rgb(text_color, crit_color)
			dn.expand_duration = settings.expand_duration
		elseif dn.hit_weakspot then
			_set_rgb(text_color, weakspot_color)
		else
			_set_rgb(text_color, default_color)
		end

		local value = dn.value
		local font_size = (value <= 99) and default_font_size or hundreds_font_size

		-- Expand then shrink behavior (same timing logic as original)
		if dn.expand_duration then
			local expand_progress = math.clamp(dn.expand_time / dn.expand_duration, 0, 1)
			local anim_progress = 1 - expand_progress
			font_size = font_size + settings.expand_bonus_scale * anim_progress

			if expand_progress >= 1 then
				dn.expand_duration = nil
				dn.shrink_start_t = dn.duration - settings.shrink_duration
			else
				dn.expand_time = dn.expand_time + dt
			end
		elseif dn.shrink_start_t and dn.shrink_start_t < dn.time then
			local diff = dn.time - dn.shrink_start_t
			local percentage = diff / settings.shrink_duration
			local s = 1 - percentage
			font_size = font_size * s
			text_color[1] = text_color[1] * s
		end

		local current_order = num - i
		if current_order == 0 then
			local scale_size = dn.was_critical and settings.crit_hit_size_scale or settings.first_hit_size_scale
			font_size = font_size * scale_size
		end

		position[3] = z0 + current_order
		position[2] = y0
		position[1] = x0 + current_order * settings.x_offset_between_numbers

		UIRenderer.draw_text(ui_renderer, value, font_size, font_type, position, ui_style.size, text_color, {})
	end

	-- DPS (only drawn when dead in the original logic)
	if ui_content.damage_has_started and mod:get("show_dps") then
		if not ui_content.damage_has_started_timer then
			ui_content.damage_has_started_timer = dt
		elseif not ui_content.dead then
			ui_content.damage_has_started_timer = ui_content.damage_has_started_timer + dt
		end

		if ui_content.dead then
			local dps_pos = Vector3(x0, y0 - settings.dps_y_offset, z0)
			local elapsed = ui_content.damage_has_started_timer
			local dps = (elapsed and elapsed > 1) and (ui_content.damage_taken / elapsed) or ui_content.damage_taken
			local text = string.format("%d DPS", dps)

			UIRenderer.draw_text(ui_renderer, text, dps_font_size, font_type, dps_pos, ui_style.size, ui_style.text_color, {})
		end
	end

	-- Armour type label
	if ui_content.damage_has_started and ui_content.last_hit_zone_name and mod:get("show_armour_type") then
		local hit_zone_name = ui_content.last_hit_zone_name
		local breed = ui_content.breed
		local armor_type = breed.armor_type

		if breed.hitzone_armor_override and breed.hitzone_armor_override[hit_zone_name] then
			armor_type = breed.hitzone_armor_override[hit_zone_name]
		end

		local armor_type_loc_string = armor_type and armor_type_string_lookup[armor_type] or ""
		local armor_type_text = Localize(armor_type_loc_string)
		local armor_pos = Vector3(x0, y0 - settings.has_taken_damage_timer_y_offset, z0)

		UIRenderer.draw_text(ui_renderer, armor_type_text, dps_font_size, font_type, armor_pos, ui_style.size, ui_style.text_color, {})
	end

	-- restore values for any later pass that might use them
	ui_style.font_size = default_font_size
	position[3], position[2], position[1] = z0, y0, x0
end

-- ---------------------------------------------------------------------------
-- Widget definition
-- ---------------------------------------------------------------------------

local ICON_DEFAULT_COLORS = {
	{ 255, 255, 0, 0 },
	{ 255, 255, 102, 0 },
	{ 255, 0, 255, 0 },
	{ 255, 120, 210, 255 },
	{ 255, 255, 255, 255 },
}

template.create_widget_defintion = function(template, scenegraph_id)
	local header_font_setting_name = "nameplates"
	local header_font_settings = UIFontSettings[header_font_setting_name]
	local header_font_color = header_font_settings.text_color

	local bar_size = { template.size[1], template.size[2] }
	local bar_offset = { -template.size[1] * 0.5, 0, 0 }

	local passes = {
		{
			pass_type = "logic",
			value = function(pass, ui_renderer, ui_style, ui_content, position, size)
				_draw_damage_numbers(template, mod, ui_renderer, ui_style, ui_content, position)
			end,
			style = {
				horizontal_alignment = "left",
				font_size = 30,
				text_vertical_alignment = "bottom",
				text_horizontal_alignment = "left",
				vertical_alignment = "center",
				offset = { -template.size[1] * 0.5, -template.size[2], 2 },
				font_type = header_font_settings.font_type,
				text_color = header_font_color,
				size = { 600, template.size[2] },
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
				offset = { bar_offset[1], bar_offset[2], 2 },
				size = bar_size,
				color = { 255, 220, 100, 100 },
			},
		},
		{
			value = "content/ui/materials/backgrounds/default_square",
			style_id = "health_max",
			pass_type = "rect",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = { bar_offset[1], bar_offset[2], 1 },
				size = bar_size,
				color = { 200, 255, 255, 255 },
			},
		},
		{
			value = "content/ui/materials/backgrounds/default_square",
			style_id = "bar",
			pass_type = "rect",
			style = {
				vertical_alignment = "center",
				offset = { bar_offset[1], bar_offset[2], 3 },
				size = bar_size,
				color = { 255, 220, 20, 20 },
			},
		},
		{
			value = "content/ui/materials/bars/simple/end",
			style_id = "bar_end",
			pass_type = "texture",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				offset = { bar_offset[1], bar_offset[2], 4 },
				size = { 12, bar_size[2] + 12 },
				color = { 255, 255, 255, 255 },
			},
		},
	}

	-- Debuff slots (1..MAX_DEBUFF_SLOTS_ALLOC) in a centered grid (max 4 per row)
	for i = 1, MAX_DEBUFF_SLOTS_ALLOC do
		local icon_id = "status_icon_" .. i
		local stacks_id = "status_stacks_" .. i
		local x, y = _slot_pos(template, i)

		passes[#passes + 1] = {
			pass_type = "texture",
			style_id = icon_id,
			value_id = icon_id,
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = { x, y, 10 },
				size = { ICON_SIZE, ICON_SIZE },
				color = ICON_DEFAULT_COLORS[i] or { 255, 255, 255, 255 },
			},
			visibility_function = function(content, style)
				return content[icon_id] ~= nil
			end,
		}

		passes[#passes + 1] = {
			pass_type = "text",
			style_id = stacks_id,
			value_id = stacks_id,
			value = "",
			style = {
              vertical_alignment = "center",
              horizontal_alignment = "center",
              text_vertical_alignment = "bottom",
              text_horizontal_alignment = "right",
              offset = { x, y, 11 },
              size = { ICON_SIZE, ICON_SIZE },

              font_type = header_font_settings.font_type,
              font_size = 14,
              text_color = { 255, 255, 255, 0 },
            }
		}
	end

	return UIWidget.create_definition(passes, scenegraph_id)
end

-- ---------------------------------------------------------------------------
-- Marker lifecycle
-- ---------------------------------------------------------------------------

template.on_enter = function(widget, marker, template)
	local content = widget.content
	content.spawn_progress_timer = 0
	content.damage_taken = 0
	content.damage_numbers = {}

	local bar_settings = template.bar_settings
	marker.bar_logic = HudHealthBarLogic:new(bar_settings)

	local unit = marker.unit
	local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
	local breed = unit_data_extension:breed()

	content.header_text = breed.name
	content.breed = breed

	marker.head_offset = 0
	marker.debuff_check_timer = 0
	marker.debuffs = {}
	marker.brittleness_percent = 0

	content.brittleness_show_icon = false
	content.brittleness_show_text = false
	content.brittleness_icon = nil
	content.brittleness_text = ""

	marker._debuff_sig = ""
	marker._had_active_debuff = false
end

-- Buff templates that apply the electrocution keyword (see weapon_buff_templates.lua)
local ELECTROCUTED_BUFFS = {
	"shock_grenade_interval",
	"shock_mine_interval",
	"shockmaul_stun_interval",
	"power_maul_p2_special_hit_primer",
	"power_maul_p2_activated_stun_extra",
	"power_maul_p2_activated_stun_basic",
	"power_maul_stun",
	"shotgun_special_stun",
	"chain_lightning_interval",
	"psyker_protectorate_spread_chain_lightning_interval",
	"shock_effect",
	"toxin_special_stun",
}

-- Brittleness (enemy-side) is implemented via rending_multiplier statbuffs on the enemy.
local BRITTLENESS_BUFFS = {
	{ name = "rending_debuff", per_stack = 2.5, cap = 16 },
	{ name = "rending_burn_debuff", per_stack = 1.0, cap = 20 },
	{ name = "shotgun_special_rending_debuff", per_stack = 25.0, cap = 1 },
	{ name = "saw_rending_debuff", per_stack = 2.5, cap = 15 },
}

-- Skullcrusher / Damage vs staggered debuff
-- Template: increase_damage_received_while_staggered (duration 5s, max_stacks 8, 10% per stack)
local SKULLCRUSHER_BUFFS = {
	{ name = "increase_damage_received_while_staggered", per_stack = 10.0, cap = 8 },
	-- Fallback in case the buff is exposed under the stat-buff name (rare, but harmless)
	{ name = "damage_vs_staggered", per_stack = 10.0, cap = 8 },
}

-- Thunderstrike / Impact modifier debuff
-- Template: increase_impact_received_while_staggered (duration 5s, max_stacks 8, 10% per stack)
local THUNDERSTRIKE_BUFFS = {
	{ name = "increase_impact_received_while_staggered", per_stack = 10.0, cap = 8 },
	-- Fallback in case the buff is exposed under the stat-buff name
	{ name = "impact_modifier", per_stack = 10.0, cap = 8 },
}


-- Melee damage taken debuff (Hard Knocks + Target the Weak)
-- Each source applies once (max_stacks=1) and they add additively (+15% each)
local MELEE_DAMAGE_TAKEN_BUFFS = {
	"ogryn_staggering_damage_taken_increase",
	"adamant_staggering_enemies_take_more_damage",
}
local MELEE_DAMAGE_TAKEN_PER_SOURCE = 15.0

local function _staggered_color_by_stacks(stacks)
	-- 1-2 white, 3-4 yellow, 5-6 orange, 7-8 red
	stacks = stacks or 0
	if stacks <= 2 then
		return { 255, 255, 255, 255 } -- white
	elseif stacks <= 4 then
		return { 255, 255, 255, 0 } -- yellow
	elseif stacks <= 6 then
		return { 255, 255, 165, 0 } -- orange
	else
		return { 255, 255, 0, 0 } -- red
	end
end

local function _compute_staggered_debuff(buff_extension, BUFFS)
	if not buff_extension then
		return 0, 0
	end

	local stacks_best = 0
	local per_stack = 10.0

	for i = 1, #BUFFS do
		local cfg = BUFFS[i]
		local stacks = buff_extension:current_stacks(cfg.name) or 0

		if stacks > 0 then
			if cfg.cap and stacks > cfg.cap then
				stacks = cfg.cap
			end
			if stacks > stacks_best then
				stacks_best = stacks
				per_stack = cfg.per_stack or per_stack
			end
		end
	end

	return stacks_best, stacks_best * per_stack
end

local function _count_named_buffs(buff_extension, buff_names)
	if not buff_extension or not buff_names then
		return 0
	end

	local buffs = buff_extension._buffs
	if not buffs then
		return 0
	end

	local count = 0
	for i = 1, #buff_names do
		local name = buff_names[i]
		for j = 1, #buffs do
			local buff = buffs[j]
			if buff then
				local template_name = nil
				-- Prefer method if available
				if buff.template_name then
					template_name = buff:template_name()
				else
					template_name = buff._template_name
				end
				if template_name == name then
					count = count + 1
					break
				end
			end
		end
	end

	return count
end

local function _melee_damage_taken_color(sources)
	if sources >= 2 then
		return { 255, 255, 0, 0 } -- red
	elseif sources == 1 then
		return { 255, 255, 255, 255 } -- white
	end
	return { 255, 255, 255, 255 }
end

local function _compute_thunderstrike(buff_extension)
	return _compute_staggered_debuff(buff_extension, THUNDERSTRIKE_BUFFS)
end

local function _compute_skullcrusher(buff_extension)
	return _compute_staggered_debuff(buff_extension, SKULLCRUSHER_BUFFS)
end

local BRITTLENESS_RELEVANT_ARMOR_TYPES = {
	armored = true,      -- Flak
	super_armor = true,  -- Carapace
	berserker = true,    -- Maniac
	resistant = true,    -- Unyielding
}

local function _is_brittleness_relevant(content)
	local breed = content and content.breed
	if not breed then
		return false
	end

	local armor_type = breed.armor_type
	return armor_type and BRITTLENESS_RELEVANT_ARMOR_TYPES[armor_type] == true or false
end

local function _format_percent(value)
	local rounded = math.floor(value * 10 + 0.5) / 10
	if math.abs(rounded - math.floor(rounded)) < 0.0001 then
		return string.format("%d%%", rounded)
	end
	return string.format("%.1f%%", rounded)
end

local function _brittleness_color(percent)
	-- 2.5..19.9 white, 20..29.9 yellow, 30..39.9 orange, >=40 red
	if percent >= 40 then
		return 255, 255, 0, 0
	elseif percent >= 30 then
		return 255, 255, 165, 0
	elseif percent >= 20 then
		return 255, 255, 255, 0
	elseif percent >= 2.5 then
		return 255, 255, 255, 255
	end
	return 0, 255, 255, 255
end

local function _compute_brittleness_percent(buff_extension)
	if not buff_extension then
		return 0
	end

	local total = 0
	for i = 1, #BRITTLENESS_BUFFS do
		local cfg = BRITTLENESS_BUFFS[i]
		local stacks = buff_extension:current_stacks(cfg.name) or 0
		if stacks > 0 then
			if stacks > cfg.cap then
				stacks = cfg.cap
			end
			total = total + stacks * cfg.per_stack
		end
	end
	return total
end

local function _trim_debuffs_keep(debuffs, max, keep_type)
	if not debuffs then
		return
	end

	while #debuffs > max do
		local removed = false
		for i = 1, #debuffs do
			if debuffs[i] and debuffs[i].type ~= keep_type then
				table.remove(debuffs, i)
				removed = true
				break
			end
		end

		if not removed then
			table.remove(debuffs, #debuffs)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Debuff definitions
-- ---------------------------------------------------------------------------

local DEBUFF_DEFS = {
	{
		id = "bleed",
		setting = "bleed",
		icon = function() return mod.textures and mod.textures.bleed end,
		color = function() return mod.colors and mod.colors.bleed end,
		poll = function(buff_extension)
			local stacks = buff_extension:current_stacks("bleed") or 0
			return stacks > 0 and { stacks = stacks } or nil
		end,
		text = function(data) return tostring(data.stacks or "") end,
	},
	{
		id = "burn",
		setting = "burn",
		icon = function() return mod.textures and mod.textures.burn end,
		color = function() return mod.colors and mod.colors.burn end,
		poll = function(buff_extension)
			local stacks = buff_extension:current_stacks("flamer_assault") or 0
			return stacks > 0 and { stacks = stacks } or nil
		end,
		text = function(data) return tostring(data.stacks or "") end,
	},
	{
		id = "warpfire",
		setting = "warpfire",
		icon = function() return mod.textures and mod.textures.warpfire end,
		color = function() return mod.colors and mod.colors.warpfire end,
		poll = function(buff_extension)
			local stacks = buff_extension:current_stacks("warp_fire") or 0
			return stacks > 0 and { stacks = stacks } or nil
		end,
		text = function(data) return tostring(data.stacks or "") end,
	},
	{
		id = "toxin",
		setting = "toxin",
		icon = function() return mod.textures and mod.textures.toxin end,
		color = function() return mod.colors and mod.colors.toxin end,
		poll = function(buff_extension)
			local toxin_stacks =
				(buff_extension:current_stacks("neurotoxin_interval_buff") or 0) +
				(buff_extension:current_stacks("neurotoxin_interval_buff2") or 0) +
				(buff_extension:current_stacks("neurotoxin_interval_buff3") or 0) +
				(buff_extension:current_stacks("exploding_toxin_interval_buff") or 0)

			return toxin_stacks > 0 and { stacks = toxin_stacks } or nil
		end,
		text = function(data) return tostring(data.stacks or "") end,
	},
	{
		id = "electrocuted",
		setting = "electrocuted",
		icon = function() return mod.textures and mod.textures.electrocuted end,
		color = function() return mod.colors and mod.colors.electrocuted end,
		poll = function(buff_extension)
			for i = 1, #ELECTROCUTED_BUFFS do
				local stacks = buff_extension:current_stacks(ELECTROCUTED_BUFFS[i]) or 0
				if stacks > 0 then
					return {} -- presence-only
				end
			end
			return nil
		end,
		text = function(_) return "" end,
	},
	{
		id = "brittleness",
		setting = "brittleness_indicator",
		icon = function() return mod.textures and mod.textures.brittleness end,
		color = function(data)
			-- color by percent
			local a, r, g, b = _brittleness_color(data.percent or 0)
			return { a, r, g, b }
		end,
		poll = function(buff_extension, content)
			if not mod:get("brittleness_indicator") then
				return nil
			end
			if not _is_brittleness_relevant(content) then
				return nil
			end
			local p = _compute_brittleness_percent(buff_extension)
			return p >= 2.5 and { percent = p } or nil
		end,
		text = function(data)
			local mode = mod:get("brittleness_indicator_display") or "icon_text"
			if mode == "icon_text" then
				return _format_percent(data.percent or 0)
			end
			return ""
		end,
		is_brittleness = true,
	},
	{
		id = "skullcrusher",
		setting = "skullcrusher",
		icon = function() return mod.textures and mod.textures.skullcrusher end,
		-- Color by stacks:
		-- 1-2 white, 3-4 yellow, 5-6 orange, 7-8 red
		color = function(data)
			return _staggered_color_by_stacks((data and data.stacks) or 0)
		end,
		poll = function(buff_extension)
			local stacks, percent = _compute_skullcrusher(buff_extension)
			return stacks > 0 and { stacks = stacks, percent = percent } or nil
		end,
		text = function(data)
		  local mode = mod:get("skullcrusher_display") or "stacks"

		  if mode == "icon_only" then
			return ""
		  elseif mode == "percent" then
			return _format_percent(data.percent or 0)
		  end

		  return tostring(data.stacks or "")
		end,
	},
	{
		id = "thunderstrike",
		setting = "thunderstrike",
		icon = function() return mod.textures and mod.textures.thunderstrike end,
		color = function(data)
			return _staggered_color_by_stacks((data and data.stacks) or 0)
		end,
		poll = function(buff_extension)
			local stacks, percent = _compute_thunderstrike(buff_extension)
			return stacks > 0 and { stacks = stacks, percent = percent } or nil
		end,
		text = function(data)
			local mode = mod:get("thunderstrike_display") or "stacks"
			if mode == "icon_only" then
				return ""
			elseif mode == "percent" then
				return _format_percent(data.percent or 0)
			end
			return tostring(data.stacks or "")
		end,
	},
	{
    	id = "melee_damage_taken",
    	setting = "melee_damage_taken",
    	icon = function() return mod.textures and mod.textures.melee_damage_taken end,

    	-- color by "active sources" (1=white, 2=red)
    	-- IMPORTANT: use data.stacks here because update() only forwards stacks/percent.
    	color = function(data)
    		return _melee_damage_taken_color((data and data.stacks) or 0)
    	end,

    	poll = function(buff_extension)
    		if not mod:get("melee_damage_taken") then
    			return nil
    		end

    		local sources = _count_named_buffs(buff_extension, MELEE_DAMAGE_TAKEN_BUFFS)
    		if sources <= 0 then
    			return nil
    		end

    		-- store sources into stacks so it survives update() packing
    		return {
    			stacks = sources,
    			percent = sources * MELEE_DAMAGE_TAKEN_PER_SOURCE
    		}
    	end,

    	-- only "icon_text" (percent) or "icon_only", like brittleness
    	text = function(data)
    		local mode = mod:get("melee_damage_taken_display") or "icon_text"
    		if mode == "icon_text" then
    			return _format_percent(data.percent or 0)
    		end
    		return ""
    	end,
    },
}

local function max_visible_slots()
  return math.min(#DEBUFF_DEFS, MAX_DEBUFF_SLOTS_ALLOC)
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------

local HEAD_NODE = "j_head"

template.update_function = function(parent, ui_renderer, widget, marker, template, dt, t)
	local content = widget.content
	local style = widget.style
	local unit = marker.unit

	local health_extension = ScriptUnit.has_extension(unit, "health_system")
	local is_dead = not health_extension or not health_extension:is_alive()
	local health_percent = is_dead and 0 or health_extension:current_health_percent()

	local max_health = Managers.state.difficulty:get_minion_max_health(content.breed.name)
	local damage_taken

	-- ----------------------------
	-- Debuffs (polled via registry)
	-- ----------------------------
	marker.debuff_check_timer = marker.debuff_check_timer + dt

	if marker.debuff_check_timer >= 0.1 then
		marker.debuff_check_timer = 0

		local buff_extension = ScriptUnit.extension(unit, "buff_system")
		if buff_extension then
			table.clear(marker.debuffs)

			for i = 1, #DEBUFF_DEFS do
				local def = DEBUFF_DEFS[i]
				local enabled = (def.setting == nil) or mod:get(def.setting)
				if enabled then
					local data = def.poll(buff_extension, content)
					if data then
						marker.debuffs[#marker.debuffs + 1] = {
							type = def.id,
							def = def,
							stacks = data.stacks,
							percent = data.percent,
						}
					end
				end
			end

			-- Keep max slots, but try to keep brittleness if present (same behavior as before)
			_trim_debuffs_keep(marker.debuffs, max_visible_slots(), "brittleness")

			-- Detect debuff changes (for “show when applied” even without damage)
			local sig = _debuff_signature(marker.debuffs)
			if sig ~= marker._debuff_sig then
				marker._debuff_sig = sig
				-- “Applied/changed”: force visibility window (like damage does)
				content.visibility_delay = template.damage_number_settings.visibility_delay
			end
		end
	end

-- ----------------------------
-- Render DoTs and Debuffs (grid, fixed ordering)
-- DoTs: bleed, burn, warpfire, toxin
-- Debuffs: electrocuted, brittleness
-- If any debuff is active: debuffs occupy bottom row (slots 1..GRID_COLS),
-- and all DoTs are moved to the next row (slot + GRID_COLS).
-- ----------------------------

-- Clear all allocated slots first
for i = 1, MAX_DEBUFF_SLOTS_ALLOC do
	local icon_id = "status_icon_" .. i
	local stacks_id = "status_stacks_" .. i
	content[icon_id] = nil
	content[stacks_id] = ""
end

local function _find_active(t, id)
	for i = 1, #t do
		if t[i] and t[i].type == id then
			return t[i]
		end
	end
	return nil
end

local dot_order = { "bleed", "burn", "warpfire", "toxin" }
local debuff_order = { "brittleness", "melee_damage_taken", "skullcrusher", "thunderstrike", "electrocuted" }

local active_debuffs = {}
for i = 1, #debuff_order do
	local d = _find_active(marker.debuffs, debuff_order[i])
	if d then
		active_debuffs[#active_debuffs + 1] = d
	end
end

local active_dots = {}
for i = 1, #dot_order do
	local d = _find_active(marker.debuffs, dot_order[i])
	if d then
		active_dots[#active_dots + 1] = d
	end
end

local has_any_debuff = #active_debuffs > 0

-- slot mapping we want to show; ensure at least 2 rows are available
local max_slots_used = math.min(GRID_COLS * 2, MAX_DEBUFF_SLOTS_ALLOC)

-- Build a list of {slot = n, debuff = d}
local placements = {}

if has_any_debuff then
	-- Debuffs in top row from slot 1
	for i = 1, #active_debuffs do
		if i > GRID_COLS then
			break
		end
		placements[#placements + 1] = { slot = i, debuff = active_debuffs[i] }
	end

	-- DoTs compacted into second row (slot + GRID_COLS)
	for i = 1, #active_dots do
		if i > GRID_COLS then
			break
		end
		placements[#placements + 1] = { slot = GRID_COLS + i, debuff = active_dots[i] }
	end
else
	-- Only DoTs: occupy top row in fixed order, compacted
	for i = 1, #active_dots do
		if i > GRID_COLS then
			break
		end
		placements[#placements + 1] = { slot = i, debuff = active_dots[i] }
	end
end

-- helper: apply the shared "center + small" style
local function center_small_text(stacks_style)
  if not stacks_style then return end
  stacks_style.font_size = 11
  stacks_style.text_horizontal_alignment = "center"
  stacks_style.text_vertical_alignment   = "center"
end

-- "switch table" / rules per debuff type
local debuff_rules = {
  brittleness = { setting = "brittleness_indicator_display", default = "icon_text", center_on = "icon_text" },
  skullcrusher = { setting = "skullcrusher_display",         default = "stacks",    center_on = "percent"   },
  thunderstrike = { setting = "thunderstrike_display",       default = "stacks",    center_on = "percent"   },
  melee_damage_taken = { setting = "melee_damage_taken_display",    default = "icon_text", center_on = "icon_text" },
}

-- Apply placements to widget content/styles
for p = 1, #placements do
	local slot = placements[p].slot
	local debuff = placements[p].debuff

	if slot <= max_slots_used and debuff then
		local icon_id = "status_icon_" .. slot
		local stacks_id = "status_stacks_" .. slot

		local icon_style = style[icon_id]
		local stacks_style = style[stacks_id]

		local x, y = _slot_pos(template, slot)
		if icon_style then
			icon_style.offset[1], icon_style.offset[2] = x, y
		end
		if stacks_style then
			stacks_style.offset[1], stacks_style.offset[2] = x, y
			-- defaults: small number in bottom-right inside icon bounds
			stacks_style.size[1], stacks_style.size[2] = ICON_SIZE, ICON_SIZE
			stacks_style.text_horizontal_alignment = "right"
			stacks_style.text_vertical_alignment = "bottom"
			stacks_style.font_size = 14
		end

		local def = debuff.def
		content[icon_id] = def and def.icon and def.icon() or (mod.textures and mod.textures[debuff.type])

		-- icon color
		if icon_style then
			local c = def and def.color and def.color(debuff) or (mod.colors and mod.colors[debuff.type]) or { 255, 255, 255, 255 }
			icon_style.color = c
		end

		-- text
		if def and def.text then
			content[stacks_id] = def.text(debuff) or ""
		else
			content[stacks_id] = tostring(debuff.stacks or "")
		end

		-- text for brittleness, skullcrusher and thunderstrike debuffs
        local rule = debuff_rules[debuff.type]
        if rule then
          local mode = mod:get(rule.setting) or rule.default
          if mode == rule.center_on then
            center_small_text(stacks_style)
          end
        end

		-- Electrocution: no text
		if debuff.type == "electrocuted" then
			content[stacks_id] = ""
		end
	end
end

	-- ----------------------------
	-- Head position offset init
	-- ----------------------------
	if ALIVE[unit] and marker.head_offset == 0 then
		local root_position = Unit.world_position(unit, 1)
		local node = Unit.node(unit, HEAD_NODE)
		local head_position = Unit.world_position(unit, node)
		marker.head_offset = head_position.z - root_position.z + 0.4
	end

	-- ----------------------------
	-- Damage & hit info
	-- ----------------------------
	if not is_dead then
		damage_taken = health_extension:total_damage_taken()
	else
		damage_taken = max_health
	end

	if health_extension then
		local last_damaging_unit = health_extension:last_damaging_unit()
		if last_damaging_unit then
			content.last_hit_zone_name = health_extension:last_hit_zone_name() or "center_mass"

			local breed = content.breed
			local weakspots = breed.hit_zone_weakspot_types
			content.hit_weakspot = weakspots and weakspots[content.last_hit_zone_name] and true or false
			content.was_critical = health_extension:was_hit_by_critical_hit_this_render_frame()
		end
	end

	-- ----------------------------
	-- Marker world position
	-- ----------------------------
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

	-- ----------------------------
	-- Damage number bookkeeping
	-- ----------------------------
	local old_damage_taken = content.damage_taken
	local dns = template.damage_number_settings

	if damage_taken and damage_taken ~= old_damage_taken then
		content.visibility_delay = dns.visibility_delay
		content.damage_taken = damage_taken

		if old_damage_taken < damage_taken and mod:get("show_damage_numbers") then
			local damage_numbers = content.damage_numbers
			local damage_diff = math.ceil(damage_taken - old_damage_taken)
			local latest = damage_numbers[#damage_numbers]
			local was_critical = health_extension and health_extension:was_hit_by_critical_hit_this_render_frame()

			local should_add = true
			if latest and (t - latest.start_time) < dns.add_numbers_together_timer then
				should_add = false
			end

			if content.add_on_next_number or was_critical or should_add then
				local dn = {
					expand_time = 0,
					time = 0,
					start_time = t,
					duration = dns.duration,
					value = damage_diff,
					expand_duration = dns.expand_duration,
				}

				local breed = content.breed
				local weakspots = breed.hit_zone_weakspot_types
				dn.hit_weakspot = weakspots and weakspots[content.last_hit_zone_name] and true or false
				dn.was_critical = was_critical

				damage_numbers[#damage_numbers + 1] = dn

				if content.add_on_next_number then
					content.add_on_next_number = nil
				end
				if was_critical then
					content.add_on_next_number = true
				end
			else
				latest.value = math.clamp(latest.value + damage_diff, 0, max_health)
				latest.time = 0
				latest.y_position = nil
				latest.start_time = t

				local breed = content.breed
				local weakspots = breed.hit_zone_weakspot_types
				latest.hit_weakspot = weakspots and weakspots[content.last_hit_zone_name] and true or false
				latest.was_critical = was_critical
			end
		end

		content.damage_has_started = content.damage_has_started or true
		content.last_damage_taken_time = t
	end

	-- ----------------------------
	-- Health bar animation/layout
	-- ----------------------------
	content.t = t

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
		style.ghost_bar.offset[1] = default_width_offset + health_width
		style.ghost_bar.size[1] = ghost_bar_width

		local background_width = math.max(bar_width - ghost_bar_width - health_width, 0)
		background_width = math.max(background_width - spacing, 0)
		style.background.offset[1] = default_width_offset + bar_width - background_width
		style.background.size[1] = background_width

		local health_max_width = bar_width - math.max(bar_width * health_max_fraction, 0)
		health_max_width = math.max(health_max_width - spacing, 0)
		style.health_max.offset[1] = default_width_offset + bar_width - health_max_width * 0.5
		style.health_max.size[1] = health_max_width

		style.bar_end.offset[1] = -(bar_width - bar_width * health_fraction) + 6 + math.abs(default_width_offset)

		marker.health_fraction = health_fraction
	end

	if not mod:get("show_bar") then
		style.bar.visible = false
		style.ghost_bar.visible = false
		style.health_max.visible = false
		style.bar_end.visible = false
		style.background.visible = false
	end

	-- ----------------------------
	-- LOS fade + removal timing
	-- ----------------------------
	local line_of_sight_progress = content.line_of_sight_progress or 0

	if marker.raycast_initialized then
		local raycast_result = marker.raycast_result
		local speed = 10

		if raycast_result then
			line_of_sight_progress = math.max(line_of_sight_progress - dt * speed, 0)
		else
			line_of_sight_progress = math.min(line_of_sight_progress + dt * speed, 1)
		end
	end

	if not HEALTH_ALIVE[unit] then
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

	-- ----------------------------
	-- Visibility / Fade rules
	-- Show while: (damage visibility window) OR (active debuff)
	-- Also show when debuff is applied/changed (handled via content.visibility_delay above)
	-- ----------------------------
	local alpha_multiplier = line_of_sight_progress
	content.line_of_sight_progress = line_of_sight_progress

	local has_active_debuff = marker.debuffs and #marker.debuffs > 0

	if has_active_debuff then
		-- Hard-visible as long as any debuff is active
		content.fade_delay = nil
		-- keep visibility_delay untouched (damage numbers may use it), but it doesn't matter for alpha now
		marker._had_active_debuff = true
	else
		-- If we *just* lost the last debuff, start fade-out
		if marker._had_active_debuff then
			content.fade_delay = template.damage_number_settings.fade_delay
			marker._had_active_debuff = false
		end

		local dns = template.damage_number_settings

		local visibility_delay = content.visibility_delay
		if visibility_delay then
			visibility_delay = visibility_delay - dt
			content.visibility_delay = (visibility_delay >= 0) and visibility_delay or nil
			if not content.visibility_delay then
				content.fade_delay = dns.fade_delay
			end
		end

		local fade_delay = content.fade_delay
		if fade_delay then
			fade_delay = fade_delay - dt
			content.fade_delay = (fade_delay >= 0) and fade_delay or nil
			local progress = math.clamp(fade_delay / dns.fade_delay, 0, 1)
			alpha_multiplier = alpha_multiplier * progress
		elseif not visibility_delay then
			alpha_multiplier = 0
		end
	end

	widget.alpha_multiplier = alpha_multiplier
end

return template