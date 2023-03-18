local mod = get_mod("ShowAllBuffs")
local UIWidget = require("scripts/managers/ui/ui_widget")
local AttackIntensitySettings = require("scripts/settings/attack_intensity/attack_intensity_settings")
local toughness_broken_grace_settings = AttackIntensitySettings.toughness_broken_grace

local default_buff_icon = "content/ui/materials/icons/abilities/default"

local custom_buffs = {
	toughness_broken_grace_period = {
		predicted = false,
		hud_icon = default_buff_icon,
		hud_icon_url = "https://darkti.de/mod-assets/toughness-broken.png",
		hud_priority = 1,
		unique_buff_id = "toughness_broken_grace_period",
		unique_buff_priority = 1,
		duration = 0,
		class_name = "buff",
	},
}

mod.on_all_mods_loaded = function()
	for _, custom_buff in pairs(custom_buffs) do
		if custom_buff.hud_icon_url then
			Managers.url_loader:load_texture(custom_buff.hud_icon_url):next(function(data)
				custom_buff.hud_icon = data.texture
				mod:debug("loaded" .. custom_buff.hud_icon_url)
			end)
		end
	end
end

local function apply_changes(buff, icon)
	if buff then
		if not buff.hud_priority then
			buff.hud_priority = 1
		end
		buff.hud_icon = icon
	end
end

local function apply()
	local BuffTemplates = require("scripts/settings/buff/buff_templates")
	local cached_items = Managers.backend.interfaces.master_data:items_cache():get_cached()
	for _, item in pairs(cached_items) do
		if item.item_type == "TRAIT" then
			local icon = item.icon
			local trait = item.trait
			if trait and icon then
				apply_changes(BuffTemplates[trait], icon)
				-- apply_changes(BuffTemplates[trait .. "_parent"], icon)
				apply_changes(BuffTemplates[trait .. "_child"], icon)
			end
		end
	end
end

mod:hook("MasterData", "_get_items_from_backend", function(func, ...)
	local promise = func(...)

	promise:next(function()
		apply()
	end)

	return promise
end)

mod:hook(UIWidget, "create_definition", function(func, pass_definitions, scenegraph_id, ...)
	if scenegraph_id == "buff" then
		local updated_passes = table.clone(pass_definitions)
		table.insert(updated_passes, 1, {
			value = "content/ui/materials/backgrounds/default_square",
			style_id = "background",
			pass_type = "texture",
			style = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
					0,
				},
				size = {
					36,
					36,
				},
				color = {
					150,
					36,
					36,
					36,
				},
			},
		})
		return func(updated_passes, scenegraph_id, ...)
	end
	return func(pass_definitions, scenegraph_id, ...)
end)

mod:hook_require("scripts/ui/hud/elements/player_buffs/hud_element_player_buffs_settings", function(instance)
	instance.positive_colors.background = { 255, 36, 36, 36 }
	instance.negative_colors.background = { 255, 36, 36, 36 }
	instance.inactive_colors.background = { 150, 36, 36, 36 }
end)

mod.on_game_state_changed = function(status)
	if status == "enter" and Managers.backend.interfaces.master_data:items_cache():has_data() then
		apply()
	end
end

local function can_add_unique_buff(buff_extension, template)
	local can_add_buff = true
	local unique_buff_id = template.unique_buff_id

	if unique_buff_id then
		local buffs_by_index = buff_extension._buffs_by_index
		for _, buff_instance in pairs(buffs_by_index) do
			local buff_template = buff_instance:template()
			local unique_id = buff_template.unique_buff_id
			if unique_buff_id == unique_id then
				can_add_buff = false
			end
		end
	end

	return can_add_buff
end

mod:hook_safe("PlayerUnitMoodExtension", "_add_mood", function(self, t, mood_type)
	if mood_type == "toughness_broken" then
		if mod:get("custom_toughness_broken_buff") then
			local buff_extension = ScriptUnit.extension(self._unit, "buff_system")
			local diff_toughness_broken_grace_settings = Managers.state.difficulty:get_table_entry_by_challenge(
				toughness_broken_grace_settings
			)
			local template = custom_buffs.toughness_broken_grace_period
			if can_add_unique_buff(buff_extension, template) then
				template.duration = diff_toughness_broken_grace_settings.duration
				buff_extension:_add_buff(template, t)
			end
		end
	end
end)
