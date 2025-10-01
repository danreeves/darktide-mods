local mod = get_mod("NoChatColours")

mod:hook("ConstantElementChat", "_add_message", function(func, self, message, sender, channel)
	return func(self, self:_scrub(message), sender, channel)
end)
