local mod = get_mod("wsf")

if not WebSockets then
	mod:echo("darktide_ws_plugin missing.")
	return
end

local connections = mod:persistent_table("connections")
local peers = mod:persistent_table("peers")
local state = mod:persistent_table("state")
local tojson = cjson.encode
local fromjson = cjson.decode

local registered_mods = { wsf = mod }
local registered_mod_names = { "wsf" }

local player_by_account_id = {}
local mods_by_account_id = {}

local function get_player_by_account_id(account_id)
	if player_by_account_id[account_id] then
		return player_by_account_id[account_id]
	end

	for _, player in pairs(Managers.player:players()) do
		if player:account_id() == account_id then
			player_by_account_id[account_id] = player
			return player
		end
	end

	return nil
end

local sync_message = {
	type = "sync",
	player = "",
	mods = registered_mod_names,
}
local function _on_message(room, message)
	local msg = fromjson(message)

	if msg.type == "joined" then
		mods_by_account_id[msg.player] = msg.mods

		if peers[room] == nil then
			peers[room] = {}
		end

		table.insert(peers[room], msg.player)

		local connection = connections[room]
		if connection then
			sync_message.player = Managers.player:local_player(1):account_id()
			sync_message.mods = registered_mod_names
			WebSockets.send(connection, tojson(sync_message))
		end

		-- Notify mods that someone joined
		for _, mod_name in ipairs(msg.mods) do
			local otherMod = registered_mods[mod_name]
			if otherMod and otherMod.player_joined then
				otherMod:player_joined(get_player_by_account_id(msg.player))
			end
		end
	end

	if msg.type == "sync" then
		mods_by_account_id[msg.player] = msg.mods

		if peers[room] == nil then
			peers[room] = {}
		end

		table.insert(peers[room], msg.player)

		-- Notify mods that someone joined
		for _, mod_name in ipairs(msg.mods) do
			local otherMod = registered_mods[mod_name]
			if otherMod and otherMod.player_joined then
				otherMod:player_joined(get_player_by_account_id(msg.player))
			end
		end
	end

	if msg.type == "left" then
		if peers[room] == nil then
			peers[room] = {}
		else
			-- Remove player as peer
			peers[room] = table.filter(peers[room], function(p)
				return p == msg.player
			end)
		end

		-- Clean up player cache
		player_by_account_id[msg.id] = nil

		-- Clean up mods for peer
		mods_by_account_id[msg.id] = nil

		-- Notify mods that someone left
		for _, mod_name in ipairs(msg.mods) do
			local otherMod = registered_mods[mod_name]
			if otherMod and otherMod.player_left then
				otherMod:player_left(get_player_by_account_id(msg.player))
			end
		end
	end

	if msg.type == "data" then
		if msg.mod then
			local otherMod = registered_mods[msg.mod]
			if otherMod and otherMod.on_message then
				otherMod:on_message(msg.data, get_player_by_account_id(msg.player))
			end
		end
	end
end

local join_message = {
	type = "joined",
	player = "",
	mods = registered_mod_names,
}
mod:hook("MultiplayerSession", "joined_host", function(func, self, channel_id, host_peer_id, host_type)
	local room = host_peer_id
	state.current_room = room
	peers[room] = {}

	if #registered_mod_names == 0 then
		return
	end

	local connection = connections[room]

	if connection == nil then
		function on_message(message)
			_on_message(room, message)
		end
		mod:echo("Connecting to darktide_ws_plugin")
		print("Connecting to darktide_ws_plugin")
		connection = WebSockets.connect("wss://ws.darkti.de/" .. room, on_message)
		connections[room] = connection

		join_message.player = Managers.player:local_player(1):account_id()
		join_message.mods = registered_mod_names
		WebSockets.send(connection, tojson(join_message))
	else
		join_message.player = Managers.player:local_player(1):account_id()
		join_message.mods = registered_mod_names
		WebSockets.send(connection, tojson(join_message))
	end

	return func(self, channel_id, host_peer_id, host_type)
end)

local leave_message = {
	type = "left",
	player = "",
}
mod:hook("MultiplayerSession", "disconnected_from_host", function(func, self, ...)
	state.current_room = nil
	local room = self._joined_host_peer_id
	local connection = connections[room]

	if connection then
		leave_message.player = Managers.player:local_player(1):account_id()
		WebSockets.send(connection, tojson(leave_message))
		WebSockets.close(connection)
		connection = nil
		connections[room] = nil
	end

	return func(self, ...)
end)

local data_message = {
	type = "data",
	mod = "",
	player = "",
	data = nil,
}
local function send_message(self, data, optional_room)
	local room = optional_room or state.current_room
	local connection = connections[room]
	if connection then
		data_message.mod = self:get_name()
		data_message.player = Managers.player:local_player(1):account_id()
		data_message.data = data
		WebSockets.send(connection, tojson(data_message))
	end
end

local function get_peers(self, optional_room)
	local room = optional_room or state.current_room
	local mod_name = self:get_name()
	return table.map(
		table.filter(peers[room], function(account_id)
			return table.array_contains(mods_by_account_id[account_id], mod_name)
		end),
		function(account_id)
			return get_player_by_account_id(account_id)
		end
	)
end

function mod:register(other_mod)
	local mod_name = other_mod:get_name()
	registered_mod_names[#registered_mod_names + 1] = mod_name
	registered_mods[mod_name] = other_mod
	other_mod.send_message = send_message
	other_mod.get_peers = get_peers
end
