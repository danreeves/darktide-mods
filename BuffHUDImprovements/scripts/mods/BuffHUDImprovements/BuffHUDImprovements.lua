local mod = get_mod("BuffHUDImprovements")

local BuffSettings = require("scripts/settings/buff/buff_settings")
local AttackIntensitySettings = require("scripts/settings/attack_intensity/attack_intensity_settings")
local DEFAULT_BUFF_ICON = "content/ui/materials/icons/abilities/default"

mod:io_dofile("BuffHUDImprovements/scripts/mods/BuffHUDImprovements/VisualBuffExtension")
mod:io_dofile("BuffHUDImprovements/scripts/mods/BuffHUDImprovements/BuffHudHooks")
local BuffSettingsWindow = mod:io_dofile("BuffHUDImprovements/scripts/mods/BuffHUDImprovements/BuffSettingsWindow")

mod.custom_buffs = {
	toughness_broken_grace_period = {
		hud_icon = DEFAULT_BUFF_ICON,
		hud_icon_url = "https://darkti.de/mod-assets/toughness-broken.png",
		hud_priority = 1,
		max_stacks = 1,
		class_name = "proc_buff",
		proc_events = {
			[BuffSettings.proc_events.on_player_toughness_broken] = 1,
		},
		-- filled in at application time with difficulty specific numbers
		cooldown_duration = 0,
		active_duration = 0,
	},
}

mod.on_all_mods_loaded = function()
	for name, custom_buff in pairs(mod.custom_buffs) do
		custom_buff.name = name

		if custom_buff.hud_icon_url then
			Managers.url_loader:load_texture(custom_buff.hud_icon_url):next(function(data)
				custom_buff.hud_icon = data.texture
			end)
		end
	end
end

mod.on_setting_changed = function()
	mod._add_custom_buffs()
end

local param_table = {}
mod:hook_safe("PlayerUnitMoodExtension", "_add_mood", function(_self, _t, mood_type)
	if mood_type == "toughness_broken" then
		if mod:get("custom_toughness_broken_buff") then
			mod:add_proc_event("on_player_toughness_broken", param_table)
		end
	end
end)

mod._add_custom_buffs = function()
	if mod:get("custom_toughness_broken_buff") then
		if not mod:has_buff(mod.custom_buffs.toughness_broken_grace_period.name) then
			local grace_settings = Managers.state.difficulty:get_table_entry_by_challenge(
				AttackIntensitySettings.toughness_broken_grace
			)
			local grace_cooldown = Managers.state.difficulty:get_table_entry_by_challenge(
				AttackIntensitySettings.toughness_broken_grace_cooldown
			)
			local buff = table.clone(mod.custom_buffs.toughness_broken_grace_period)
			buff.active_duration = grace_settings.duration
			buff.cooldown_duration = grace_cooldown
			mod:add_buff(buff)
		end
	else
		mod:remove_buff(mod.custom_buffs.toughness_broken_grace_period.name)
	end
end

local buff_settings_window = BuffSettingsWindow:new()

mod:hook("UIManager", "using_input", function(func, ...)
	return buff_settings_window._is_open or func(...)
end)

mod.open_buff_settings = function()
	if buff_settings_window._is_open then
		buff_settings_window:close()
	else
		buff_settings_window:open()
	end
end

mod.update = function()
	if buff_settings_window and buff_settings_window._is_open then
		buff_settings_window:update()
	end
end

local hud_element = {
	package = "packages/ui/hud/player_buffs/player_buffs",
	use_retained_mode = true,
	use_hud_scale = true,
	class_name = "HudElementPriorityBuffs",
	filename = "BuffHUDImprovements/scripts/mods/BuffHUDImprovements/HudElementPriorityBuffs",
	visibility_groups = {
		"dead",
		"alive",
		"communication_wheel",
	},
}

mod:add_require_path(hud_element.filename)

mod:hook_require("scripts/ui/hud/hud_elements_player_onboarding", function(elements)
	if not table.find_by_key(elements, "class_name", hud_element.class_name) then
		table.insert(elements, hud_element)
	end
end)

mod:hook_require("scripts/ui/hud/hud_elements_player", function(elements)
	if not table.find_by_key(elements, "class_name", hud_element.class_name) then
		table.insert(elements, hud_element)
	end
end)
