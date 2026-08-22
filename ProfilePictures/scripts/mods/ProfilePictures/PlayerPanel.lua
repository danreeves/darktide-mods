local mod = get_mod("ProfilePictures")

local hud_types = {
	"PersonalPlayerPanel",
	"PersonalPlayerPanelHub",
	"TeamPlayerPanel",
	"TeamPlayerPanelHub",
}

-- The portrait is a render target fed into the frame material's icon slot, so the picture goes into that same slot instead of being drawn over the panel. The equipped frame keeps rendering around it, and the panel's own tint, shadowing and fades still apply.
local function _apply_profile_image(self, texture)
	local widgets_by_name = self._widgets_by_name
	local widget = widgets_by_name and widgets_by_name.player_icon
	local style = widget and widget.style.texture

	if not style then
		return
	end

	local material_values = style.material_values

	material_values.use_placeholder_texture = 0
	material_values.rows = 1
	material_values.columns = 1
	material_values.grid_index = 0
	material_values.texture_icon = texture
	widget.dirty = true
end

local function _load_portrait_icon(self)
	local player = self._player
	local player_info = mod.player_info_for_player(player)

	mod.load_profile_image(player_info, function(texture)
		if self.__deleted or self.destroyed or self._player ~= player then
			return
		end

		self._profile_picture_texture = texture

		_apply_profile_image(self, texture)
	end)
end

-- Vanilla replaces the icon slot with the character render target once it finishes loading
local function _cb_set_player_icon(self)
	local texture = self._profile_picture_texture

	if texture then
		_apply_profile_image(self, texture)
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
