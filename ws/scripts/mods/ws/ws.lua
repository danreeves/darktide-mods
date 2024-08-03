local mod = get_mod("ws")

if not WebSockets then
	mod:echo("darktide_ws_plugin missing.")
	return
end

local connection = WebSockets.connect("wss://ws.darkti.de", function(message)
	mod:echo(message)
end)

mod:hook_safe("MultiplayerSession", "joined_host", function()
	local session_id = tostring(Managers.connection:session_id())
	connection:send(cjson.encode({ type = "join", room = session_id }))
end)

-- mod:command("ws", "Websocket commands", function(...)
-- 	DarktideWs.send_message(table.concat({ ... }, " "))
-- end)
