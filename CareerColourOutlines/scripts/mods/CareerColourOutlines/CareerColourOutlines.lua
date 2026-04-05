local mod = get_mod("CareerColourOutlines")
local UISettings = require("scripts/settings/ui/ui_settings")
local player_slot_colors = UISettings.player_slot_colors
local player_manager = Managers.player
local slot_color_vectors = {}
local set_outline_color = Unit.set_vector3_for_materials

local function _slot_color_vector(player_slot)
	if not player_slot then
		return nil
	end

	local cached = slot_color_vectors[player_slot]

	if cached ~= nil then
		return cached ~= false and cached or nil
	end

	local player_slot_color = player_slot_colors[player_slot]

	if not player_slot_color then
		slot_color_vectors[player_slot] = false
		return nil
	end

	cached = Vector3(player_slot_color[2] / 255, player_slot_color[3] / 255, player_slot_color[4] / 255)
	slot_color_vectors[player_slot] = cached

	return cached
end

mod:hook_safe("OutlineSystem", "update", function(self)
	if self._total_num_outlines == 0 then
		return
	end

	if not self._visible then
		return
	end

	for unit, extension in pairs(self._unit_extension_data) do
		local player = player_manager:player_by_unit(unit)

		if player then
			local top_outline = extension.outlines[1]

			if top_outline then
				local color = _slot_color_vector(player:slot())

				if color then
					set_outline_color(unit, "outline_color", color, true)
				end
			end
		end
	end
end)
