local Archetypes = require("scripts/settings/archetype/archetypes")

local localization = {
	mod_name = {
		en = "Tertium 5... or 4",
		["zh-cn"] = "特提恩五人组…或四人组",
	},
	mod_description = {
		en = "We're the bloody Tertium 5... or 4, it doesn't matter!",
		["zh-cn"] = "我们是特提恩贼配军五人组…或者四人组，没区别！",
	},
	num_bots = {
		en = "Number of bots",
		["zh-cn"] = "机器人数量",
	},
	bots = {
		en = "Bots",
		["zh-cn"] = "机器人",
	},
	gender_male_abbreviation = {
		en = "(m)",
	},
	gender_female_abbreviation = {
		en = "(f)",
	},
}

for i = 1, table.size(Archetypes) do
	localization["character_" .. i] = {
		en = "Bot " .. i,
		["zh-cn"] = "机器人 " .. i,
	}
end

return localization
