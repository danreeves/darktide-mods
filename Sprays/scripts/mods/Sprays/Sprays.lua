local mod = get_mod("Sprays")
local rtc = get_mod("rtc")
local function noop() end
mod.textures = mod:persistent_table("textures")

local SprayMarkerTemplate = mod:io_dofile("Sprays/scripts/mods/Sprays/SprayMarkerTemplate")
mod:hook_safe("HudElementWorldMarkers", "init", function(self)
	self._marker_templates[SprayMarkerTemplate.name] = SprayMarkerTemplate
end)

rtc.register(mod, "add_spray", function(player, data)
	local url = data.url
	if player then
		Managers.event:trigger(
			"add_world_marker_unit",
			SprayMarkerTemplate.name,
			player.player_unit,
			noop,
			{ url = url }
		)
	end
end)

local url = "https://cdn.7tv.app/emote/01FS5ZCFG0000500DPPCXJWCP8/2x.png"

function mod.add_spray()
	local player_unit = Managers.player:local_player(1).player_unit
	Managers.event:trigger("add_world_marker_unit", SprayMarkerTemplate.name, player_unit, noop, { url = url })
	rtc.send(mod, "add_spray", "all", {
		url = url,
	})
end
