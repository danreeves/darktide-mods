local FEATURE_SETTING_SUFFIXES = {
	enabled = "_enabled",
	show_healthbar = "_show_healthbar",
	show_damage_numbers = "_show_damage_numbers",
	show_dps = "_show_dps",
	show_info_label = "_show_info_label",
	info_label_content = "_info_label_content",
	show_dots = "_show_dots",
	show_debuffs = "_show_debuffs",
}

local function setting_id(breed_name, feature_name)
	return breed_name .. FEATURE_SETTING_SUFFIXES[feature_name]
end

return {
	setting_id = setting_id,
	schema_setting_id = "enemy_features_schema_version",
	schema_version = 2,
}
