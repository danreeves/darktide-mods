-- PreviewCosmetics
-- Description: Preview cosmetics on your own character
-- Author: raindish
local mod = get_mod("PreviewCosmetics")

mod:hook(CLASS.StoreItemDetailView, "_spawn_profile", function(func, self, original_profile, item)
    local UISettings = mod:original_require("scripts/settings/ui/ui_settings")
    local MasterItems = mod:original_require("scripts/backend/master_items")

    local local_player = Managers.player:local_player(1)
    local player_profile = table.clone(local_player:profile())

    local dummy_profile = {
        loadout = player_profile.loadout,
        archetype = player_profile.archetype,
        breed = player_profile.breed or local_player:breed_name(),
        gender = player_profile.gender
    }

    dummy_profile.loadout.slot_portrait_frame = nil
    dummy_profile.loadout.slot_primary = nil
    dummy_profile.loadout.slot_secondary = nil

    for slot_name, current_slot_item in pairs(dummy_profile.loadout) do
        local item_definition = MasterItems.get_item(current_slot_item.__gear.masterDataInstance.id)

        if item_definition then
            local slot_item = table.clone(item_definition)
            dummy_profile.loadout[slot_name] = slot_item
        end
    end

    local items = #item > 0 and item or {item}
    local wrong_breed = false

    for i = 1, #items do
        local item = items[i]

        if item.breeds and #item.breeds > 0 and not table.array_contains(item.breeds, dummy_profile.breed) then
            wrong_breed = true
        end

        if item.slots then
            dummy_profile.loadout[item.slots[1]] = item
        end
    end

    if wrong_breed then
        return func(self, original_profile, item)
    else
        return func(self, dummy_profile, item)
    end
end)
