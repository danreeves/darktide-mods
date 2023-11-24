local mod = get_mod("Clock")

local hud_element = {
	class_name = "HudElementClock",
	filename = "Clock/scripts/mods/Clock/HudElementClock",
	visibility_groups = {
		"in_hub_view",
		"dead",
		"alive",
		"communication_wheel",
		"tactical_overlay",
	},
}

mod:add_require_path(hud_element.filename)

function add_hud_element(elements)
	local i, t = table.find_by_key(elements, "class_name", hud_element.class_name)
	if not i or not t then
		table.insert(elements, hud_element)
	else
		elements[i] = hud_element
	end
end

mod:hook_require("scripts/ui/hud/hud_elements_player", add_hud_element)
mod:hook_require("scripts/ui/hud/hud_elements_player_hub", add_hud_element)
mod:hook_require("scripts/ui/hud/hud_elements_player_onboarding", add_hud_element)
