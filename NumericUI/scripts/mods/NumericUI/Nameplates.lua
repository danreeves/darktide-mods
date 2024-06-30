local mod = get_mod("NumericUI")

mod:hook_require(
	"scripts/ui/hud/elements/world_markers/templates/world_marker_template_nameplate_combat",
	function(instance)
		mod:hook(instance, "on_enter", function(func, widget, marker)
			func(widget, marker)
			if mod:get("archetype_icons_in_nameplates") then
				local data = marker.data
				local content = widget.content
				local profile = data:profile()
				local archetype = profile and profile.archetype
				local symbol_string = archetype and archetype.string_symbol or ""
				local replace_string = mod:get("color_nameplate") and "{#reset%(%)}" or ""

				content.header_text = content.header_text:gsub(replace_string, symbol_string)
				content.icon_text = content.icon_text:gsub(replace_string, symbol_string)
			end
		end)
	end
)
