local mod = get_mod("NumericUI")

local companion_glyph = ""

local nameplates = {
	"scripts/ui/hud/elements/world_markers/templates/world_marker_template_nameplate_companion",
	"scripts/ui/hud/elements/world_markers/templates/world_marker_template_nameplate_companion_hub",
}

for _, nameplate in ipairs(nameplates) do
	mod:hook_require(nameplate, function(instance)
		instance.screen_clamp = mod:get("companion_nameplates_screen_clamp")
		mod:hook(instance, "on_enter", function(func, widget, marker)
			func(widget, marker)

			if not mod:get("companion_nameplates_name") then
				local content = widget.content
				content.header_text = content.header_text:gsub(companion_glyph .. ".*", companion_glyph)
			end

			if not mod:get("companion_nameplates_icon") then
				local content = widget.content
				content.icon_text = ""
				content.header_text = content.header_text:gsub(companion_glyph, "")
			end
		end)
	end)
end
