local mod = get_mod("CareerColourOutlines")
local UISettings = require("scripts/settings/ui/ui_settings")

mod:hook_safe("OutlineSystem", "update", function(self)
	if self._total_num_outlines == 0 then
		return
	end

	if not self._visible then
		return
	end

	for unit, extension in pairs(self._unit_extension_data) do
		local player = Managers.player:player_by_unit(unit)

		if player then
			local top_outline = extension.outlines[1]

			if top_outline then
				local player_slot = player:slot()
				local player_slot_color = UISettings.player_slot_colors[player_slot]
				if player_slot_color then
					local color =
						Vector3(player_slot_color[2] / 255, player_slot_color[3] / 255, player_slot_color[4] / 255)
					Unit.set_vector3_for_materials(unit, "outline_color", color, true)
				end
			end
		end
	end
end)
