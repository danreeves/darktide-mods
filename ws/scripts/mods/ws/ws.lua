local mod = get_mod("ws")

local tojson = cjson.encode
local fromjson = cjson.decode

if not WebSockets then
	mod:echo("darktide_ws_plugin missing.")
	return
end

local mods = {}
local connection

local function on_connect()
	connection:send(tojson({
		type = "connect",
		id = Managers.player:players():account_id(),
	}))
end

local function on_message(message)
	local msg = fromjson(message)
	if msg.mod then
		local otherMod = mods[msg.mod]
		if otherMod then
			otherMod:on_message(msg.data, msg.from)
		end
	end
end

local function on_close()
	mod:echo("Disconnected from WebSocket server")
end

connection = WebSockets.connect("wss://ws.darkti.de", on_connect, on_message, on_close)

function mod.on_unload()
	connection.close()
end

mod:hook_safe("MultiplayerSession", "joined_host", function()
	if connection then
		local session_id = Managers.connection:session_id()
		connection:send(tojson({ type = "join", room = session_id }))
	end
end)

mod:hook_safe("MultiplayerSession", "disconnected_from_host ", function()
	if connection then
		connection:send(tojson({ type = "leave" }))
	end
end)

local function send_message(self, data, optional_to)
	if connection then
		local to = optional_to == nil and "all" or optional_to
		connection:send(tojson({
			type = "data",
			mod = self:get_name(),
			from = Managers.player:players():account_id(),
			to = to,
			data = data,
		}))
	end
end

function mod:register(other_mod)
	mods[other_mod:get_name()] = other_mod
	other_mod.send_message = send_message
end
