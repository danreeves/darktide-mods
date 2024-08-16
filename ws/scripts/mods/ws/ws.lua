local mod = get_mod("ws")
local pt = mod:persistent_table("pt")

local tojson = cjson.encode
local fromjson = cjson.decode

if not WebSockets then
	mod:echo("darktide_ws_plugin missing.")
	return
end

local mods = {}

local function on_connect() end

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

if pt.connection == nil then
	pt.connection = WebSockets.connect("wss://ws.darkti.de", on_connect, on_message, on_close)
end

Managers.event:register(mod, "event_multiplayer_session_joined_host", "_event_multiplayer_session_joined_host")
function mod:_event_multiplayer_session_joined_host()
	if pt.connection then
		pt.connection:send(tojson({
			type = "join",
			id = Managers.player:local_player(1):account_id(),
			room = Managers.connection:session_id(),
		}))
	end
end

Managers.event:register(
	mod,
	"event_multiplayer_session_disconnected_from_host",
	"_event_multiplayer_session_disconnected_from_host"
)
function mod:_event_multiplayer_session_disconnected_from_host()
	if pt.connection then
		pt.connection:send(tojson({ type = "leave" }))
	end
end

local function send_message(self, data, optional_to)
	if pt.connection then
		local to = optional_to == nil and "all" or optional_to
		pt.connection:send(tojson({
			type = "data",
			mod = self:get_name(),
			from = Managers.player:local_player(1):account_id(),
			to = to,
			data = data,
		}))
	end
end

function mod:register(other_mod)
	mods[other_mod:get_name()] = other_mod
	other_mod.send_message = send_message
end
