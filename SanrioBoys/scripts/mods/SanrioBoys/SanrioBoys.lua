local mod = get_mod("SanrioBoys")
local MissionUtilities = require("scripts/utilities/ui/mission")
local MissionBoardViewSettings = require("scripts/ui/views/mission_board_view/mission_board_view_settings")
local MissionTemplates = require("scripts/settings/mission/mission_templates")

local characters = {
	explicator_a = {
		image = "https://danreeves.github.io/darktide-mods/SanrioBoys/img/mymelody.png",
		texture = nil,
		name = "My Melody",
		original = "explicator_a",
	},
	sergeant_a = {
		image = "https://danreeves.github.io/darktide-mods/SanrioBoys/img/kuromi.png",
		texture = nil,
		name = "Kuromi",
		original = "sergeant_a",
	},
	pilot_a = {
		image = "https://danreeves.github.io/darktide-mods/SanrioBoys/img/pompompurin.png",
		texture = nil,
		name = "Pompompurin",
		original = "pilot_a",
	},
	tech_priest_a = {
		image = "https://danreeves.github.io/darktide-mods/SanrioBoys/img/cinnamoroll.png",
		texture = nil,
		name = "Cinnamoroll",
		original = "tech_priest_a",
	},
}

for _name, character in pairs(characters) do
	character.texture = Managers.url_loader:load_texture(character.image):next(function(data)
		character.texture = data.texture
	end)
end

mod:hook("HudElementMissionSpeakerPopup", "_mission_speaker_start", function(func, self, _name_text, _icon)
	local character = characters[self._speaker_name]
	if character then
		return func(self, character.name, character.texture)
	end
	return func(self, _name_text, _icon)
end)

mod:hook_safe("MissionBoardView", "_fetch_success", function(self, data)
	local missions = data.missions
	local narrative_mission = MissionUtilities.get_latest_narrative_mission(missions)
	local mission_giver = narrative_mission and narrative_mission.missionGiver
	local character = characters[mission_giver]
	if character then
		self._widgets_by_name.story_mission_view_button_frame.style.char.material_values.main_texture =
			character.texture
		self._widgets_by_name.story_mission_view_button_frame.style.char.size = {
			120,
			120,
		}
	end
end)

mod:hook_safe("MissionBoardView", "_set_selected_quickplay", function(self)
	local vo_profile = MissionBoardViewSettings.quickplay_vo_profile
	local character = characters[vo_profile]

	local widget = self._widgets_by_name.objective_1
	widget.dirty = true
	widget.visible = true
	local content = widget.content
	local style = widget.style

	-- content.speaker_icon = character.textures
	content.speaker_text = "/ " .. character.name

	if not style.speaker_icon.material_values then
		style.speaker_icon.material_values = {}
	end
	style.speaker_icon.material_values.texture_map = character.texture
end)

mod:hook_safe("MissionBoardView", "_set_selected_mission", function(self, mission, move_gamepad_cursor, is_flash)
	local mission_template = MissionTemplates[mission.map]
	local vo_profile = mission.missionGiver or mission_template.mission_brief_vo.vo_profile
	local character = characters[vo_profile]

	local widget = self._widgets_by_name.objective_1
	widget.dirty = true
	widget.visible = true

	local content = widget.content
	local style = widget.style

	-- content.speaker_icon = character.material_small
	content.speaker_text = "/ " .. character.name

	if not style.speaker_icon.material_values then
		style.speaker_icon.material_values = {}
	end
	style.speaker_icon.material_values.texture_map = character.texture
end)
