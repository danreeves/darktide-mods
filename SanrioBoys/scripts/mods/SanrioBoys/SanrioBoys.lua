local mod = get_mod("SanrioBoys")

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
