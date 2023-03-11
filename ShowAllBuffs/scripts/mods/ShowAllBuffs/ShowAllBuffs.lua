local mod = get_mod("ShowAllBuffs")
local UIWidget = require("scripts/managers/ui/ui_widget")

-- local default_buff_icon = "content/ui/materials/icons/abilities/default"

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
	for id, item in pairs(cached_items) do
		if item.item_type == "TRAIT" then
			local icon = item.icon
			local trait = item.trait
			if trait and icon then
				apply_changes(BuffTemplates[trait], icon)
				apply_changes(BuffTemplates[trait .. "_parent"], icon)
				apply_changes(BuffTemplates[trait .. "_child"], icon)
			end
		end
	end
end

mod:hook("MasterData", "_get_items_from_backend", function(func, ...)
	local promise = func(...)

	promise:next(function(items)
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
