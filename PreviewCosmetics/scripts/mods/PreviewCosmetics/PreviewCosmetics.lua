-- PreviewCosmetics
-- Description: Preview cosmetics on your own character
-- Author: raindish
local mod = get_mod("PreviewCosmetics")

local function get_player_profile_with_item(item)
	local MasterItems = require("scripts/backend/master_items")

	local local_player = Managers.player:local_player(1)
	local player_profile = table.clone_instance(local_player:profile())

	local ignored_slots = {
		"slot_pocketable",
		"slot_luggable",
		"slot_support_ability",
		"slot_combat_ability",
		"slot_grenade_ability",
		-- "slot_primary",
		-- "slot_secondary",
		"slot_portrait_frame",
	}

	-- for _, slot in ipairs(ignored_slots) do
	-- 	player_profile.loadout[slot] = nil
	-- end

	-- for slot_name, current_slot_item in pairs(dummy_profile.loadout) do
	-- 	local item_definition = MasterItems.get_item(current_slot_item.__gear.masterDataInstance.id)
	--
	-- 	if item_definition then
	-- 		local slot_item = table.clone(item_definition)
	-- 		dummy_profile.loadout[slot_name] = slot_item
	-- 	end
	-- end

	local items = #item > 0 and item or { item }
	local wrong_breed = false

	for i = 1, #items do
		local item = items[i]
		local master_item = MasterItems.get_item(item.name)

		if item.breeds and #item.breeds > 0 and not table.array_contains(item.breeds, player_profile.breed) then
			-- wrong_breed = true
		end

		if item.slots then
			player_profile.loadout[item.slots[1]] = item
		end
	end

	return wrong_breed, player_profile
end

mod:hook("StoreItemDetailView", "_spawn_profile", function(func, self, original_profile, item)
	local wrong_breed, profile = get_player_profile_with_item(item)

	if wrong_breed then
		return func(self, original_profile, item)
	else
		return func(self, profile, item)
	end
end)

mod:hook("StoreItemDetailView", "_get_generic_profile_from_item", function(func, self, item)
	local wrong_breed, profile = get_player_profile_with_item(item)

	if wrong_breed then
		return func(self, item)
	end

	return profile
end)

mod:hook("CosmeticsInspectView", "init", function(func, self, settings, context)
	context.preview_with_gear = true
	func(self, settings, context)
	self._camera_zoomed_in = false
end)
