-- DisableScreenEffects
-- Description: Makes all screen effects toggleable
-- Author: raindish

local mod = get_mod("DisableScreenEffects")
local MoodSettings = require("scripts/settings/camera/mood/mood_settings")
local BuffTemplates = require("scripts/settings/buff/buff_templates")

mod:hook("PlayerUnitMoodExtension", "_add_mood", function(func, self, t, mood_type, reset_time)
	if mod:get(mood_type) then
		return
	end
	return func(self, t, mood_type, reset_time)
end)

mod:hook("PlasmagunOverheatEffects", "_update_screenspace", function(func, ...)
	if mod:get("disable_plasmagun") then
		return
	end
	return func(...)
end)

mod:hook("PlayerUnitFxExtension", "spawn_exclusive_particle", function(func, self, particle_name, ...)
	if mod:get(particle_name) then
		return
	end
	return func(self, particle_name, ...)
end)

mod:hook("FxSystem", "start_template_effect", function(func, self, template, ...)
	if
		(template.name == "chaos_daemonhost_ambience" and mod:get("chaos_daemonhost_ambience"))
		or (
			mod:get("corruptor_ambience")
			and (template.name == "corruptor_ambience_burrowed" or template.name == "corruptor_ambience")
		)
	then
		return
	end
	return func(self, template, ...)
end)

mod:hook("FxSystem", "stop_template_effect", function(func, self, global_effect_id)
	if global_effect_id == nil then
		return
	end
	return func(self, global_effect_id)
end)

mod:hook("PlayerUnitBuffExtension", "_start_fx", function(func, self, index, template)
	if template.player_effects then
		if mod:get(template.name) then
			return
		end
	end
	return func(self, index, template)
end)

mod:hook("PlayerUnitBuffExtension", "_stop_fx", function(func, self, index, template)
	if template.player_effects then
		if mod:get(template.name) then
			return
		end
	end
	return func(self, index, template)
end)
