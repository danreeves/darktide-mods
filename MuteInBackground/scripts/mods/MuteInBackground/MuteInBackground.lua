local mod = get_mod("MuteInBackground")

local default_sound_volume = 100
local master_volume_value_name = "option_master_slider"
local current_master_volume = Application.user_setting("sound_settings", master_volume_value_name)
	or default_sound_volume

local calling_it_ourselves = false
mod:hook(Wwise, "set_parameter", function(func, param_name, value)
	if param_name == master_volume_value_name and not calling_it_ourselves then
		current_master_volume = value
	end
	return func(param_name, value)
end)

local muted = false
mod.update = function()
	if mod:is_enabled() then
		if IS_WINDOWS and not Window.has_focus() and not muted then
			muted = true
			calling_it_ourselves = true
			Wwise.set_parameter(master_volume_value_name, 0)
			calling_it_ourselves = false
		end

		if IS_WINDOWS and Window.has_focus() and muted then
			muted = false
			calling_it_ourselves = true
			Wwise.set_parameter(master_volume_value_name, current_master_volume)
			calling_it_ourselves = false
		end
	end
end

mod.on_disabled = function()
	Wwise.set_parameter(master_volume_value_name, current_master_volume)
end
