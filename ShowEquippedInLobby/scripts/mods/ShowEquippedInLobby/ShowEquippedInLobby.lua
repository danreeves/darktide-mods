local mod = get_mod("ShowEquippedInLobby")

local legend_input_definition = {
	input_action = "hotkey_menu_special_1",
	display_name = "loc_inventory_menu_swap_weapon",
	alignment = "right_alignment",
	on_pressed_callback = "__modded_cb_on_weapon_swap_pressed",
}

mod:hook_require("scripts/ui/views/lobby_view/lobby_view_definitions", function(instance)
	if not table.find_by_key(instance.legend_inputs, "display_name", legend_input_definition.display_name) then
		table.insert(instance.legend_inputs, legend_input_definition)
	end
end)

mod:hook_safe("LobbyView", "init", function(self)
	self.__modded_cb_on_weapon_swap_pressed = function()
		local slots = self._spawn_slots
		for _, slot in ipairs(slots) do
			local slot_name = slot.default_slot == "slot_primary" and "slot_secondary" or "slot_primary"
			local profile_spawner = slot.profile_spawner
			local slot_item = slot.profile and slot.profile.loadout[slot_name]

			local item_inventory_animation_event = slot_item and slot_item.inventory_animation_event
				or "inventory_idle_default"

			profile_spawner:wield_slot(slot_name)

			if item_inventory_animation_event then
				profile_spawner:assign_animation_event(item_inventory_animation_event)
			end

			-- There's no ready to ready transition so assign the ready animation after
			-- resetting to idle first
			if slot.ready then
				profile_spawner:assign_animation_event("ready")
			end

			slot.default_slot = slot_name
		end
	end
end)

mod:hook("LobbyView", "_setup_loadout_widgets", function(func, self, spawn_slot)
	spawn_slot.default_slot = mod:get("default_slot")
	return func(self, spawn_slot)
end)
