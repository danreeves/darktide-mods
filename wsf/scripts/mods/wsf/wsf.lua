local mod = get_mod("wsf")

if not WebSockets then
	mod:echo("darktide_ws_plugin missing.")
	return
end

local pt = mod:persistent_table("pt")
local tojson = cjson.encode
local fromjson = cjson.decode
local registered_mod_names = { nil }
local mods = {}
local peers = {}
local player_by_account_id = {}
local mods_by_account_id = {}

local function on_connect() end

local function get_player_by_account_id(account_id)
	if player_by_account_id[account_id] then
		return player_by_account_id[account_id]
	end

	for _, player in ipairs(Managers.player:players()) do
		if player:account_id() == account_id then
			player_by_account_id[account_id] = player
			return player
		end
	end

	return nil
end

local function on_message(message)
	local msg = fromjson(message)

	if msg.type == "joined" then
		for _, peer in ipairs(msg.peers) do
			local player = get_player_by_account_id(peer.id)

			-- Save player as peer
			if not table.array_contains(peers, player) then
				table.insert(peers, player)
			end

			-- Store mods for peer so we can filter later in get_peers
			mods_by_account_id[peer.id] = peer.mods

			-- Notify mods that someone joined
			for _, mod_name in ipairs(msg.mods) do
				local otherMod = mods[mod_name]
				if otherMod and otherMod.player_joined then
					otherMod:player_joined(player)
				end
			end
		end
	end

	if msg.type == "left" then
		local player = get_player_by_account_id(msg.id)

		-- Remove player as peer
		peers = table.filter(peers, function(p)
			return p == player
		end)

		-- Clean up player cache
		player_by_account_id[msg.id] = nil

		-- Clean up mods for peer
		mods_by_account_id[msg.id] = nil

		-- Notify mods that someone joined
		for _, mod_name in ipairs(msg.mods) do
			local otherMod = mods[mod_name]
			if otherMod and otherMod.player_left then
				otherMod:player_left(msg.id)
			end
		end
	end

	if msg.type == "data" then
		if msg.mod then
			local otherMod = mods[msg.mod]
			if otherMod and otherMod.on_message then
				otherMod:on_message(msg.data, get_player_by_account_id(msg.from))
			end
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
local join_message = {
	type = "join",
	id = "",
	room = "",
	mods = registered_mod_names,
}
function mod:_event_multiplayer_session_joined_host()
	if pt.connection and #registered_mod_names > 0 then
		join_message.id = Managers.player:local_player(1):account_id()
		join_message.room = Managers.connection:session_id()
		join_message.mods = registered_mod_names
		pt.connection:send(tojson(join_message))
	end

	-- There are no registered mods, close the connection
	if #registered_mod_names == 0 then
		pt.connection:close()
		pt.connection = nil
	end
end

Managers.event:register(
	mod,
	"event_multiplayer_session_disconnected_from_host",
	"_event_multiplayer_session_disconnected_from_host"
)
local leave_message = tojson({ type = "leave" })
function mod:_event_multiplayer_session_disconnected_from_host()
	if pt.connection then
		pt.connection:send(leave_message)
	end
end

local to_list = {}
local data_message = {
	type = "data",
	mod = "",
	from = "",
	to = to_list,
	data = nil,
}
local function send_message(self, data, optional_to)
	if pt.connection then
		table.clear_array(to_list, #to_list)
		local to = optional_to == nil and "all"
			or table.map(optional_to, function(player)
				return player:account_id()
			end, to_list)
		data_message.mod = self:get_name()
		data_message.to = to
		data_message.from = Managers.player:local_player(1):account_id()
		data_message.data = data
		pt.connection:send(tojson(data_message))
	end
end

local function get_peers(self)
	local mod_name = self:get_name()
	return table.filter(peers, function(player)
		local account_id = player:account_id()
		return table.array_contains(mods_by_account_id[account_id], mod_name)
	end)
end

function mod:register(other_mod)
	local mod_name = other_mod:get_name()
	registered_mod_names[#registered_mod_names + 1] = mod_name
	mods[mod_name] = other_mod
	other_mod.send_message = send_message
	other_mod.get_peers = get_peers
end
