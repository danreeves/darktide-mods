local mod = get_mod("TestMod")

mod:command("connect", "Connect to the server", function()
	function on_peer_connect(peer)
		mod:echo("Connected to " .. peer)

		RTC.send("test", peer, "welcome to the server")
	end

	function on_message(message, peer)
		mod:echo(peer .. " said " .. message)

		RTC.send("test", peer, "echo")
	end

	function on_peer_disconnect(peer)
		mod:echo("Disconnected from " .. peer)
	end

	RTC.connect("test", on_peer_connect, on_message, on_peer_disconnect)
end)

mod:command("send", "Send a message to the server", function(message)
	RTC.send("test", "all", message)
end)

mod:command("disconnect", "Disconnect from the server", function()
	RTC.disconnect("test")
end)
