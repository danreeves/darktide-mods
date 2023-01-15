local mod = get_mod("Healthbars")

mod.tags = {
	"horde",
	"roamer",
	"elite",
	"special",
	"monster",
}

local localization = {
	mod_description = {
		en = "Show healthbars from the Psykanium in regular game modes",
	},
}

for i = 1, #mod.tags do
	local key = "show_" .. mod.tags[i]
	local label = "Show " .. mod.tags[i] .. " health"
	localization[key] = {
		en = label,
	}
end

return localization
