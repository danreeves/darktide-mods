local mod = get_mod("DisableScreenEffects")
local MoodSettings = require("scripts/settings/camera/mood/mood_settings")
local mood_types = MoodSettings.mood_types

local BuffTemplates = require("scripts/settings/buff/buff_templates")

mod.screenspace_effects = {
	"corruptor_ambience",
	"content/fx/particles/screenspace/screen_stunned_light",
	"content/fx/particles/screenspace/screen_stunned_heavy",
	"content/fx/particles/screenspace/screen_blood_splatter",
}

local function localize(name)
	return {
		en = string.format("Disable %s", string.gsub(name, "_", " ")),
	}
end

local localization = {
	mod_description = {
		en = "Makes all screen effects toggleable",
	},
	disable_plasmagun = {
		en = "Disable plasmagun overheat",
	},
	chaos_daemonhost_ambience = {
		en = "Disable Daemonhost effects",
	},
	[mod.screenspace_effects[4]] = {
		en = "Disable corruptor effects",
	},
	[mod.screenspace_effects[1]] = {
		en = "Disable player stun distortion light",
	},
	[mod.screenspace_effects[2]] = {
		en = "Disable player stun distortion heavy",
	},
	[mod.screenspace_effects[3]] = {
		en = "Disable blood splatter",
	},
}

for buff_name, template in pairs(BuffTemplates) do
	if template.player_effects then
		localization[buff_name] = localize(buff_name)
	end
end

for mood_type, _ in pairs(mood_types) do
	localization[mood_type] = localize(mood_type)
end

return localization
