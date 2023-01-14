local mod = get_mod("TaskbarFlasher")

return {
    name = "Taskbar Flasher",
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {{
            setting_id = "flash_on_load",
            type = "checkbox",
            default_value = true
        }, {
            setting_id = "flash_on_afk",
            type = "checkbox",
            default_value = true
        }}
    }
}
