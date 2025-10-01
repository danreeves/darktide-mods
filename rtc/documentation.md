# RTC Mod API Documentation

### `rtc.register(mod: Mod, event_name: string, callback: function)`
Registers an event handler for a specific event name under the given mod. The callback will be invoked when the event is triggered.
- `mod`: The mod registering the event.
- `event_name`: The name of the event to listen for.
- `callback`: The function to call when the event occurs.
	- `player`: The player object that triggered the event.
	- `data`: The data payload sent with the event.

### `rtc.send(mod: Mod, event_name: string, player_or_all: string | Player, data: table)`
Sends a message/event to a specific player or all players via RTC.
- `mod`: The mod sending the event.
- `event_name`: The name of the event to send.
- `player_or_all`: A player object or the string "all" to broadcast.
- `data`: The data payload to send. **Must** be JSON serializable.

### `rtc.get_player_by_account_id(account_id: string)`
Returns the player object matching the given account ID, or nil if not found.
- `account_id`: The account ID to search for.

### `rtc.player_has_mod(player, mod_name)`
Checks if the specified player has a particular mod loaded.
- `player`: The player object to check.
- `mod_name`: The name of the mod to look for.
