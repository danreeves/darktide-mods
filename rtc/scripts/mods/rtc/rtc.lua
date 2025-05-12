local mod = get_mod("rtc")

local mod_event_handlers = mod:persistent_table("mod_event_handlers")
local internal_data = mod:persistent_table("internal_data")
local data_for_peer = mod:persistent_table("data_for_peer")
local account_id_to_peer_id = mod:persistent_table("account_id_to_peer_id")

function mod.register(registering_mod, event_name, callback)
	local mod_name = registering_mod:get_name()
	mod_event_handlers[mod_name] = mod_event_handlers[mod_name] or {}
	mod_event_handlers[mod_name][event_name] = callback
end

function mod.send(sending_mod, event_name, player_or_all, data)
	local mod_name = sending_mod:get_name()
	local host_peer_id = internal_data.host_peer_id
	if not host_peer_id then
		mod:echo(string.format("[{%s}] Not connected to a channel, cannot send message.", mod_name))
		return
	end

	local channel = "rtc_" .. host_peer_id
	local payload = {
		mod_name = mod_name,
		event_name = event_name,
		data = data,
	}
	local recipient = player_or_all == "all" and "all" or account_id_to_peer_id[player_or_all:account_id()]
	RTC.send(channel, recipient, cjson.encode(payload))
end

function mod.get_player_by_account_id(account_id)
	for _, player in pairs(Managers.player:players()) do
		if player:account_id() == account_id then
			return player
		end
	end

	return nil
end

function mod.player_has_mod(player, wanted_mod_name)
	local peer_id = account_id_to_peer_id[player:account_id()]
	if not peer_id then
		return false
	end

	local peer_data = data_for_peer[peer_id]
	if not peer_data then
		return false
	end

	for _, mod_name in ipairs(peer_data.mods) do
		if mod_name == wanted_mod_name then
			return true
		end
	end

	return false
end

local function on_share_meta(peer_id, data)
	data_for_peer[peer_id] = data
	account_id_to_peer_id[data.account_id] = peer_id

	local player = mod.get_player_by_account_id(data.account_id)
	if not player or not #data.mods then
		return
	end

	for _, mod_name in ipairs(data.mods) do
		local callback = mod_event_handlers[mod_name]
		if callback and callback.player_joined then
			callback.player_joined(player)
		end
	end
end

local function on_peer_connect(peer_id)
	local player = Managers.player:local_player(1)
	local account_id = player:account_id()
	local player_mods = {}
	for mod_name, _ in pairs(mod_event_handlers) do
		table.insert(player_mods, mod_name)
	end

	if #player_mods == 0 then
		return
	end

	local host_peer_id = internal_data.host_peer_id
	if not host_peer_id then
		mod:echo("[rtc] Not connected to a channel, cannot send message.")
		return
	end

	local channel = "rtc_" .. host_peer_id
	local data = {
		account_id = account_id,
		mods = player_mods,
	}
	local payload = {
		mod_name = "rtc",
		event_name = "rtc_share_meta",
		data = data,
	}
	RTC.send(channel, peer_id, cjson.encode(payload))
end

local function on_message(message, peer_id)
	local decoded_message = cjson.decode(message)
	if not decoded_message then
		return
	end

	local mod_name = decoded_message.mod_name
	local event_name = decoded_message.event_name
	local data = decoded_message.data

	if mod_name == "rtc" and event_name == "rtc_share_meta" then
		on_share_meta(peer_id, data)
		return
	end

	if not mod_event_handlers[mod_name] or not mod_event_handlers[mod_name][event_name] then
		return
	end

	local callback = mod_event_handlers[mod_name][event_name]
	if callback then
		local peer_data = data_for_peer[peer_id]
		if peer_data and peer_data.account_id then
			local player = mod.get_player_by_account_id(peer_data.account_id)
			if player then
				callback(player, data)
			end
		end
	end
end

local function on_peer_disconnect(peer_id)
	local peer_data = data_for_peer[peer_id]
	if peer_data then
		local player = mod.get_player_by_account_id(peer_data.account_id)
		if player then
			for _, mod_name in ipairs(peer_data.mods) do
				local callbacks = mod_event_handlers[mod_name]
				if callbacks and callbacks.player_left then
					callbacks.player_left(player)
				end
			end
		end
		account_id_to_peer_id[peer_data.account_id] = nil
		data_for_peer[peer_id] = nil
	end
end

mod:hook_safe("MultiplayerSession", "joined_host", function(_self, _channel_id, host_peer_id)
	internal_data.host_peer_id = host_peer_id
	local channel = "rtc_" .. host_peer_id
	RTC.connect(channel, on_peer_connect, on_message, on_peer_disconnect)
end)

mod:hook_safe("MultiplayerSession", "disconnected_from_host", function(self)
	local host_peer_id = self._joined_host_peer_id
	internal_data.host_peer_id = nil
	local channel = "rtc_" .. host_peer_id
	RTC.disconnect(channel)
end)

mod:hook("MultiplayerSession", "other_client_left", function(func, self, game_peer_id)
	for _, player in pairs(Managers.player:players_at_peer(game_peer_id)) do
		local account_id = player:account_id()
		local peer_id = account_id_to_peer_id[account_id]
		local peer_data = data_for_peer[peer_id]
		if peer_data then
			for _, mod_name in ipairs(peer_data.mods) do
				local callbacks = mod_event_handlers[mod_name]
				if callbacks and callbacks.player_left then
					callbacks.player_left(player)
				end
			end

			data_for_peer[peer_id] = nil
			account_id_to_peer_id[account_id] = nil
		end
	end

	return func(self, game_peer_id)
end)
