local mod = get_mod("ChatBlock")
local WeaponTemplate = require("scripts/utilities/weapon/weapon_template")

mod.input_blocked = false

function input_get_hook(func, self, action_name)
	-- Don't impact the non gameplay input services
	if self.type == "Ingame" and action_name ~= "voip_push_to_talk" then
		-- When checking if action_two_hold is held
		if action_name == "action_two_hold" then
			local unit = Managers.player:local_player(1).player_unit
			if unit then
				local unit_data = ScriptUnit.extension(unit, "unit_data_system")
				local weapon_action_component = unit_data:read_component("weapon_action")
				local weapon_template = WeaponTemplate.current_weapon_template(weapon_action_component)
				if weapon_template then
					-- If the current held weapon has a block action
					if weapon_template.actions.action_block then
						-- You alt tabbed
						if IS_WINDOWS and not Window.has_focus() then
							return true
						end

						-- Steam overlay is open
						if HAS_STEAM and Managers.steam:is_overlay_active() then
							return true
						end

						-- Chat or some other menu is open
						if mod.input_blocked then
							return true
						end
					end
				end
			end
		end

		-- Act as if any other input is not working while the UI is using input
		-- so you don't move or tag or dodge while typing
		local ui_manager = Managers.ui
		if ui_manager and ui_manager:using_input() then
			local result = func(self, action_name)
			local result_type = type(result)

			if result_type == "boolean" then
				return false
			elseif result_type == "number" then
				return 0
			elseif result_type == "userdata" then
				return Vector3(0, 0, 0)
			else
				return result
			end
		end
	end

	-- Default behaviour for other input services or
	-- while UI not using input
	return func(self, action_name)
end

mod:hook("InputService", "_get", input_get_hook)
mod:hook("InputService", "_get_simulate", input_get_hook)

mod:hook("HumanGameplay", "_input_active", function(func, ...)
	mod.input_blocked = not func(...)

	if Managers.state.cinematic:cinematic_active() then
		return false
	end

	-- Keep the input active so you can block
	return true
end)
