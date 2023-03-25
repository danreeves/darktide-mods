local mod = get_mod("NumericUI")

mod._is_in_hub = function()
	local game_mode_name = Managers.state.game_mode:game_mode_name()
	local is_in_hub = game_mode_name == "hub"

	return is_in_hub
end
