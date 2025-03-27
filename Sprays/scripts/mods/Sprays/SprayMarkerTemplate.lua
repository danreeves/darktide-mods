local mod = get_mod("Sprays")
local UIWidget = require("scripts/managers/ui/ui_widget")

local template = {}
local size = {
	250,
	250,
}

template.size = size
template.name = "spray"
template.unit_node = "j_head"
template.life_time = 2
template.position_offset = {
	0,
	0,
	0.2,
}
template.check_line_of_sight = true
template.max_distance = 15
template.screen_clamp = false
template.scale_settings = {
	distance_max = 20,
	distance_min = 10,
	scale_from = 0.5,
	scale_to = 1,
}
template.fade_settings = {
	default_fade = 1,
	fade_from = 0,
	fade_to = 1,
	distance_max = template.max_distance,
	distance_min = template.max_distance * 0.5,
	easing_function = math.ease_exp,
}

template.create_widget_defintion = function(_template, scenegraph_id)
	return UIWidget.create_definition({

		{
			pass_type = "texture",
			style_id = "texture",
			value_id = "texture",
			style = {
				vertical_alignment = "bottom",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
					1,
				},
				size = { 10, 10 },
				material_values = {
					use_placeholder_texture = 0,
				},
				color = {
					255,
					255,
					255,
					255,
				},
			},
			visibility_function = function(_content, style)
				if style.material_values.texture_map then
					return true
				end

				return false
			end,
		},
	}, scenegraph_id)
end

template.on_exit = function(_widget, _marker) end

template.on_enter = function(widget, marker)
	marker.data.direction = math.clamp(math.random() - 0.5, -0.5, 0.5)
	local url = marker.data.url
	if mod.textures[url] == nil then
		Managers.url_loader:load_texture(url):next(function(data)
			mod:echo("loaded")
			mod.textures[url] = data.texture
			-- mod:echo("%dx%d", data.width, data.height)
		end)
	else
		local texture = mod.textures[url]
		local style = widget.style
		style.texture.material_values.texture_map = texture
	end
end

template.update_function = function(_parent, _ui_renderer, widget, marker, _template, dt, _t)
	local url = marker.data.url
	local texture = mod.textures[url]
	local style = widget.style

	style.texture.material_values.texture_map = texture

	local p = math.clamp(math.easeOutCubic(marker.duration), 0, 1)
	local scaled_size = math.lerp(10, 250, p)
	local scaled_offset_speed = math.lerp(150, 45, p)
	local scaled_drift_speed = math.lerp(0, 5, p)
	style.texture.size = { scaled_size, scaled_size }
	style.texture.offset[2] = style.texture.offset[2] - scaled_offset_speed * dt
	if p > 0.5 then
		style.texture.offset[1] = style.texture.offset[1]
			+ marker.data.direction * scaled_drift_speed * scaled_offset_speed * dt
	end
end

return template
