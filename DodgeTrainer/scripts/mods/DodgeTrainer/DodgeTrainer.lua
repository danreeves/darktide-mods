local mod = get_mod("DodgeTrainer")

local hud_elements = {
	{
		filename = "DodgeTrainer/scripts/mods/DodgeTrainer/HudElementDodgeTrainer",
		class_name = "HudElementDodgeTrainer",
	},
}

for _, hud_element in ipairs(hud_elements) do
	mod:add_require_path(hud_element.filename)
end

mod:hook("UIHud", "init", function(func, self, elements, visibility_groups, params)
	for _, hud_element in ipairs(hud_elements) do
		if not table.find_by_key(elements, "class_name", hud_element.class_name) then
			table.insert(elements, {
				class_name = hud_element.class_name,
				filename = hud_element.filename,
				use_hud_scale = true,
				visibility_groups = hud_element.visibility_groups or {
					"alive",
				},
			})
		end
	end

	return func(self, elements, visibility_groups, params)
end)

mod.time_between = 0
mod.exit_time = 0

local function on_enter(_self, _unit, _dt, t, _previous_state, _params)
	mod.time_between = t - mod.exit_time
	mod.exit_time = 0
end

local function on_exit(_self, _unit, t, _next_state)
	mod.exit_time = t
end

mod:hook_safe("PlayerCharacterStateDodging", "on_enter", on_enter)
mod:hook_safe("PlayerCharacterStateDodging", "on_exit", on_exit)

mod:hook_safe("PlayerCharacterStateSliding", "on_enter", on_enter)
mod:hook_safe("PlayerCharacterStateSliding", "on_exit", on_exit)

mod:hook_safe("PlayerCharacterStateSprinting", "on_enter", function(...)
	if mod:get("include_sprinting") then
		on_enter(...)
	end
end)
mod:hook_safe("PlayerCharacterStateSprinting", "on_exit", function(...)
	if mod:get("include_sprinting") then
		on_exit(...)
	end
end)
