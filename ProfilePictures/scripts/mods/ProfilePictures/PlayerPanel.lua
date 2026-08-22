local mod = get_mod("ProfilePictures")

local _apply_profile_image = mod.apply_profile_image

local hud_types = {
	"PersonalPlayerPanel",
	"PersonalPlayerPanelHub",
	"TeamPlayerPanel",
	"TeamPlayerPanelHub",
}

-- The player icon widget belongs to the panel, so resolve it before handing the picture over
local function _apply_panel_profile_image(self, texture)
	local widgets_by_name = self._widgets_by_name

	_apply_profile_image(widgets_by_name and widgets_by_name.player_icon, "texture", texture)
end

local function _load_portrait_icon(self)
	local player = self._player
	local player_info = mod.player_info_for_player(player)

	mod.load_profile_image(player_info, function(texture)
		if self.__deleted or self.destroyed or self._player ~= player then
			return
		end

		self._profile_picture_texture = texture

		_apply_panel_profile_image(self, texture)
	end)
end

-- Vanilla replaces the icon slot with the character render target once it finishes loading
local function _cb_set_player_icon(self)
	local texture = self._profile_picture_texture

	if texture then
		_apply_panel_profile_image(self, texture)
	end
end

-- Runs at the start of every portrait load, so the previous player's picture never carries over
local function _unload_portrait_icon(self)
	self._profile_picture_texture = nil
end

for _, hud_type in ipairs(hud_types) do
	local class_name = "HudElement" .. hud_type

	mod:hook_safe(class_name, "_load_portrait_icon", _load_portrait_icon)
	mod:hook_safe(class_name, "_cb_set_player_icon", _cb_set_player_icon)
	mod:hook_safe(class_name, "_unload_portrait_icon", _unload_portrait_icon)
end
