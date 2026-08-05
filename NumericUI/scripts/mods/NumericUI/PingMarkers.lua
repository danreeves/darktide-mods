local mod = get_mod("NumericUI")

local ARBITES_COMPANION_TAG_TEMPLATE_NAME = "enemy_companion_target"
local SKITARIUS_COMPANION_TAG_TEMPLATE_NAME = "servo_skull_enemy_companion_target"

mod:hook_require("scripts/ui/hud/elements/world_markers/templates/world_marker_template_unit_threat", function(instance)
	mod:hook(instance, "create_widget_defintion", function(func, ...)
		local widget_definition = func(...)
		if not mod:get("show_ping_skull") then
			widget_definition.style.icon.size = { 0, 0 }
			widget_definition.style.icon.default_size = { 0, 0 }
			widget_definition.style.entry_icon_1.size = { 0, 0 }
			widget_definition.style.entry_icon_1.default_size = { 0, 0 }
			widget_definition.style.entry_icon_2.size = { 0, 0 }
			widget_definition.style.entry_icon_2.default_size = { 0, 0 }
			widget_definition.style.text.offset[2] = 0
			widget_definition.style.text.default_offset[2] = 0
		end
		return widget_definition
	end)
end)

mod:hook_require(
	"scripts/ui/hud/elements/world_markers/templates/world_marker_template_unit_threat_veteran",
	function(instance)
		mod:hook(instance, "create_widget_defintion", function(func, ...)
			local widget_definition = func(...)
			if not mod:get("show_vet_ping_skull") then
				widget_definition.style.icon.size = { 0, 0 }
				widget_definition.style.icon.default_size = { 0, 0 }
				widget_definition.style.entry_icon_1.size = { 0, 0 }
				widget_definition.style.entry_icon_1.default_size = { 0, 0 }
				widget_definition.style.entry_icon_2.size = { 0, 0 }
				widget_definition.style.entry_icon_2.default_size = { 0, 0 }
				widget_definition.style.text.offset[2] = 0
				widget_definition.style.text.default_offset[2] = 0
			end
			return widget_definition
		end)
	end
)

mod:hook_require(
	"scripts/ui/hud/elements/world_markers/templates/world_marker_template_unit_threat_companion",
	function(instance)
		mod:hook(instance, "on_enter", function(func, widget, marker, template)
			func(widget, marker, template)

			local data = marker.data
			local tag_template = data and data.tag_template
			local tag_template_name = tag_template and tag_template.name
			local hide_skull = false

			if tag_template_name == ARBITES_COMPANION_TAG_TEMPLATE_NAME then
				hide_skull = not mod:get("show_arb_ping_skull")
			elseif tag_template_name == SKITARIUS_COMPANION_TAG_TEMPLATE_NAME then
				hide_skull = not mod:get("show_skit_ping_skull")
			end

			if hide_skull then
				widget.style.icon.size = { 0, 0 }
				widget.style.icon.default_size = { 0, 0 }
				widget.style.entry_icon_1.size = { 0, 0 }
				widget.style.entry_icon_1.default_size = { 0, 0 }
				widget.style.entry_icon_2.size = { 0, 0 }
				widget.style.entry_icon_2.default_size = { 0, 0 }
				widget.style.text.offset[2] = 0
				widget.style.text.default_offset[2] = 0
			end
		end)
	end
)
