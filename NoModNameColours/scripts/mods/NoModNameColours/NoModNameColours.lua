local mod = get_mod("NoModNameColours")

local dmf = get_mod("DMF")

-- Matches rich text tags used to colour/format text, e.g. "{#color(255,0,127)}" and "{#reset()}".
local RICH_TEXT_TAG_PATTERN = "{#.-}"

local function strip_colours(text)
	if type(text) ~= "string" then
		return text
	end

	return (text:gsub(RICH_TEXT_TAG_PATTERN, ""))
end

local function strip_mod_name_colours(mod_object)
	local readable_name = mod_object:get_internal_data("readable_name")
	local stripped_name = strip_colours(readable_name)

	if stripped_name ~= readable_name then
		dmf.set_internal_data(mod_object, "readable_name", stripped_name)
	end
end

-- Mods that load after this one have their name stripped before DMF stores it. The data tables are mutated in place,
-- so hooking the initializer is enough to clean both the internal readable name and the options menu entry.
mod:hook(dmf, "initialize_mod_data", function(func, mod_object, mod_data)
	if type(mod_data) == "table" then
		mod_data.name = strip_colours(mod_data.name)
	end

	return func(mod_object, mod_data)
end)

-- Mods that loaded before this one already had their readable name stored by the time this script ran, so the hook
-- above never saw them. Fix those up once every mod has finished loading.
mod.on_all_mods_loaded = function()
	for _, mod_object in pairs(dmf.mods) do
		strip_mod_name_colours(mod_object)
	end

	for _, widgets_data in ipairs(dmf.options_widgets_data) do
		local header_data = widgets_data[1]

		if header_data and header_data.readable_mod_name then
			header_data.readable_mod_name = strip_colours(header_data.readable_mod_name)
		end
	end
end
