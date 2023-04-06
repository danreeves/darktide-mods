local mod = get_mod("NumericUI")
local UISettings = require("scripts/settings/ui/ui_settings")

mod:hook_require(
	"scripts/ui/hud/elements/world_markers/templates/world_marker_template_nameplate_combat",
	function(instance)
		mod:hook(instance, "on_enter", function(func, widget, marker)
			func(widget, marker)
			if mod:get("archetype_icons_in_nameplates") then
				local data = marker.data
				local content = widget.content
				local profile = data:profile()
				local player_slot = data:slot()
				local player_slot_color = UISettings.player_slot_colors[player_slot]
					or Color.ui_hud_green_light(255, true)
				local color_string = "{#color("
					.. player_slot_color[2]
					.. ","
					.. player_slot_color[3]
					.. ","
					.. player_slot_color[4]
					.. ")}"
				local archetype = profile and profile.archetype
				local string_symbol = archetype and archetype.string_symbol or ""

				content.header_text = color_string .. string_symbol .. "{#reset()} " .. data:name()
				content.icon_text = color_string .. string_symbol .. "{#reset()}"
			end
		end)
	end
)
