---@meta

---@class DarktideDiscord
---Global interface for Discord Rich Presence integration
DarktideDiscord = {}

---Start the activity timer
function DarktideDiscord.set_start_time() end

---Set the details line of the presence (typically mission name or activity)
---@param details string The details text to display
function DarktideDiscord.set_details(details) end

---Set the state line of the presence (typically difficulty or party status)
---@param state string The state text to display
function DarktideDiscord.set_state(state) end

---Set the party size information
---@param current_size number Current number of players in the party
---@param max_size number Maximum party size (typically 4)
function DarktideDiscord.set_party_size(current_size, max_size) end

---Set the character class/archetype information
---@param archetype_name string The archetype identifier
---@param details string Formatted details string with player name, class, and level
function DarktideDiscord.set_class(archetype_name, details) end

---Update and push the presence to Discord
function DarktideDiscord.update() end
