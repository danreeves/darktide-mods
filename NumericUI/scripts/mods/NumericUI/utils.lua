local mod = get_mod("NumericUI")

local table_clear = table.clear

mod._is_in_hub = function()
	local game_mode_name = Managers.state.game_mode:game_mode_name()
	local is_in_hub = game_mode_name == "hub"

	return is_in_hub
end

local setting_values = {}
local setting_cached = {}

mod.setting = function(setting_id)
	if not setting_cached[setting_id] then
		setting_values[setting_id] = mod:get(setting_id)
		setting_cached[setting_id] = true
	end

	return setting_values[setting_id]
end

mod.flush_settings = function()
	table_clear(setting_values)
	table_clear(setting_cached)
end
