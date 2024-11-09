local mod = get_mod("Sprays")
local wsf = get_mod("wsf")
local SprayMarkerTemplate = mod:io_dofile("Sprays/scripts/mods/Sprays/SprayMarkerTemplate")
local function noop() end
mod.textures = mod:persistent_table("textures")

wsf:register(mod)

mod:hook_safe("HudElementWorldMarkers", "init", function(self)
	self._marker_templates[SprayMarkerTemplate.name] = SprayMarkerTemplate
end)

function mod:on_message(event, player)
	local url = event.url
	if player then
		Managers.event:trigger(
			"add_world_marker_unit",
			SprayMarkerTemplate.name,
			player.player_unit,
			noop,
			{ url = url }
		)
	end
end

local url = "https://i.imgur.com/0L4pcoX.jpg"

function mod.add_spray()
	local player_unit = Managers.player:local_player(1).player_unit
	Managers.event:trigger("add_world_marker_unit", SprayMarkerTemplate.name, player_unit, noop, { url = url })
	mod:send_message({ url = url })
end
