local mod = get_mod("CustomCrosshairColor")
local _AttackSettings = require("scripts/settings/damage/attack_settings")
local CrosshairSettings = require("scripts/ui/hud/elements/crosshair/hud_element_crosshair_settings")
local _hit_indicator_colors = table.clone(CrosshairSettings.hit_indicator_colors)
local HudElementCrosshair = require("scripts/ui/hud/elements/crosshair/hud_element_crosshair")

local crosshair_parts = {
	"center",
	"up",
	"down",
	"top",
	"bottom",
	"left",
	"right",
	"up_left",
	"up_right",
	"bottom_left",
	"bottom_right",
	"charge_mask_left",
	"charge_mask_right",
}

mod:hook_safe(HudElementCrosshair, "_sync_active_crosshair", function(self)
	local widget = self._widget
	if not widget or not widget.style then
		return
	end
	for _, part in ipairs(crosshair_parts) do
		local style = widget.style[part]
		if style and style.color then
			style.color[1] = mod:get("crosshair_opacity")
			style.color[2] = mod:get("crosshair_r")
			style.color[3] = mod:get("crosshair_g")
			style.color[4] = mod:get("crosshair_b")
		end
	end
end)

local function override_colors()
	for _, kind in ipairs(mod.kinds) do
		local color = { 255 }
		for _, field in ipairs(mod.fields) do
			color[#color + 1] = mod:get(kind .. "_" .. field)
		end
		CrosshairSettings.hit_indicator_colors[kind] = color
	end
end

mod.on_setting_changed = function()
	override_colors()
end

mod.on_enabled = function()
	override_colors()
end

mod.on_disabled = function()
	for field, _ in pairs(CrosshairSettings.hit_indicator_colors) do
		CrosshairSettings.hit_indicator_colors[field] = _hit_indicator_colors[field]
	end
end

if mod:is_enabled() then
	override_colors()
end
