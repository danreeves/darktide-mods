local mod = get_mod("TestMod")

mod:command("connect", "Connect to a channel", function()
	function on_peer_connect(peer)
		mod:echo("Connected to " .. peer)
	end

	function on_message(message, peer)
		mod:echo(peer .. " said " .. message)
	end

	function on_peer_disconnect(peer)
		mod:echo("Disconnected from " .. peer)
	end

	RTC.connect("test", on_peer_connect, on_message, on_peer_disconnect)
end)

mod:command("send", "Send a message to a channel", function(message)
	RTC.send("test", "all", message)
end)

mod:command("disconnect", "Disconnect from a channel", function()
	RTC.disconnect("test")
end)
