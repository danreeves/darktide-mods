local mod = get_mod("DisableScreenEffects")
local MoodSettings = require("scripts/settings/camera/mood/mood_settings")
local moods = MoodSettings.moods
local mood_types = MoodSettings.mood_types

local BuffTemplates = require("scripts/settings/buff/buff_templates")

local widgets = {}

local function add(name)
	widgets[#widgets + 1] = {
		setting_id = name,
		type = "checkbox",
		default_value = false,
	}
end

add("disable_plasmagun")
add("chaos_daemonhost_ambience")

for _, effect in ipairs(mod.screenspace_effects) do
	add(effect)
end

for buff_name, template in pairs(BuffTemplates) do
	if template.player_effects then
		add(buff_name)
	end
end

for mood_type, _ in pairs(mood_types) do
	local mood = moods[mood_type]
	if
		mood.shading_environment
		or mood.particle_effects_on_enter
		or mood.particle_effects_looping
		or mood.particle_effects_on_exit
	then
		add(mood_type)
	end
end

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = widgets,
	},
}
