local mod = get_mod("ws")

if not DarktideWs then
	mod:echo("Websocket plugin missing.")
	return
end

function _darktide_ws_callback(message)
	mod:echo(message)
end

mod:hook_safe("MultiplayerSession", "joined_host", function ()
	local session_id = tostring(Managers.connection:session_id())
	DarktideWs.join_room(session_id)
end)

mod:command("ws", "Websocket commands", function(...) 
	DarktideWs.send_message(table.concat({...}, " "))
end)
