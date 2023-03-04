local mod = get_mod("ShowAllBuff")

local default_buff_icon = "content/ui/materials/icons/abilities/default"

mod:hook("MasterData", "_get_items_from_backend", function(func, ...)
	local promise = func(...)

	promise:next(function(items)
		local BuffTemplates = require("scripts/settings/buff/buff_templates")
		local cached_items = Managers.backend.interfaces.master_data:items_cache():get_cached()
		for id, item in pairs(cached_items) do
			if item.item_type == "TRAIT" then
				local icon = item.icon
				local trait = item.trait
				if trait and icon then
					if BuffTemplates[trait] then
						BuffTemplates[trait].hud_icon = icon
					end
				end
			end
		end
	end)

	return promise
end)
