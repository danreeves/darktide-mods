local mod = get_mod("NumericUI")

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
	"scripts/ui/hud/elements/world_markers/templates/world_marker_template_unit_threat_adamant",
	function(instance)
		mod:hook(instance, "create_widget_defintion", function(func, ...)
			local widget_definition = func(...)
			if not mod:get("show_arb_ping_skull") then
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
