-- Ammo pickup notifications
-- Description: Shows the Ammo Tins and Ammo Stashes you and your teammates pick up in the combat feed, with the ammo
-- gained, and how much ammo each Ammo Crate charge refilled.
local mod = get_mod("NumericUI")

local Pickups = require("scripts/settings/pickup/pickups")
local Text = require("scripts/utilities/ui/text")
local UISettings = require("scripts/settings/ui/ui_settings")

local math_floor = math.floor
local math_min = math.min
local string_match = string.match
local pickup_ammo_amount = mod.pickup_ammo_amount
local split_pickup_ammo = mod.split_pickup_ammo
local weapon_ammo_totals = mod.weapon_ammo_totals

local SETTING_ID = "show_ammo_pickup_notifications"

-- A client starts its own pickup itself, and the server's start of the same pickup follows within a round trip. Until
-- then, a start of the same interaction keeps the ammo from before the pickup.
local SNAPSHOT_LIFETIME = 2

local MESSAGE_KEYS = {
	small_clip = "ammo_pickup_notification_small_clip",
	large_clip = "ammo_pickup_notification_large_clip",
}

-- What each weapon family fires, by the family its ammo template name starts with (bots' weapons share these ammo
-- templates). Every other weapon that uses ammo fires rounds.
local AMMO_UNIT_BY_AMMO_FAMILY = {
	flamer = "fuel",
	lasgun = "energy",
	laspistol = "energy",
	plasmagun = "energy",
	arc_rifle = "energy",
	needle_pistol = "needles",
	shotgun = "shells",
	shotpistol_shield = "shells",
	ogryn_rippergun = "shells",
	-- the Kickback and the Thugshot
	ogryn_thumper = "shells",
	ogryn_gauntlet = "grenades",
}
-- Marks that fire something else than the rest of their family
local AMMO_UNIT_BY_AMMO_TEMPLATE = {
	-- the Rumbler
	ogryn_thumper_p1_m2 = "grenades",
}
local DEFAULT_AMMO_UNIT = "rounds"

-- The ammo gained, in its unit. Ammo counted one by one has its own text for exactly 1.
local GAINED_KEYS = {
	rounds = "ammo_pickup_gained_rounds",
	shells = "ammo_pickup_gained_shells",
	grenades = "ammo_pickup_gained_grenades",
	needles = "ammo_pickup_gained_needles",
	fuel = "ammo_pickup_gained_fuel",
	energy = "ammo_pickup_gained_energy",
}
local GAINED_ONE_KEYS = {
	rounds = "ammo_pickup_gained_rounds_one",
	shells = "ammo_pickup_gained_shells_one",
	grenades = "ammo_pickup_gained_grenades_one",
	needles = "ammo_pickup_gained_needles_one",
}
local WASTED_KEY = "ammo_pickup_wasted"
local WASTED_ONE_KEY = "ammo_pickup_wasted_one"
local GAINED_AND_WASTED_KEY = "ammo_pickup_gained_and_wasted"
-- The deployable crate, and the expedition crate the game also calls an Ammo Crate
local CRATE_PICKUPS = {
	ammo_cache_deployable = true,
	large_ammunition_crate = true,
}
local CRATE_MESSAGE_KEY = "ammo_pickup_notification_crate"
-- for a crate that refilled something, but less than 1%
local CRATE_UNDER_ONE_PERCENT_MESSAGE_KEY = "ammo_pickup_notification_crate_under_one_percent"

-- the combat feed's colour for a player without a slot colour
local PLAYER_DEFAULT_COLOR = Color.ui_hud_green_light(255, true)

-- The ammo pickup each interactor started last, with its result worked out from the ammo before the pickup. Every
-- interactor unit keeps one entry, reused for its next pickup.
local pending_by_interactor = {}

-- The ammo unit of each weapon template, worked out on the first pickup with it
local ammo_unit_by_weapon_template = {}

local function _is_local_player_unit(unit)
	local local_player = Managers.player:local_player(1)

	return local_player ~= nil and local_player.player_unit == unit
end

local function _ammo_unit(unit, slot_name)
	local visual_loadout_extension = ScriptUnit.has_extension(unit, "visual_loadout_system")
	local weapon_template = visual_loadout_extension and visual_loadout_extension:weapon_template_from_slot(slot_name)

	if not weapon_template then
		return DEFAULT_AMMO_UNIT
	end

	local ammo_unit = ammo_unit_by_weapon_template[weapon_template]

	if not ammo_unit then
		-- The game's source names ammo templates <family>_p1_m1; the running game prefixes them with base_
		local ammo_template_name = weapon_template.ammo_template

		if ammo_template_name then
			ammo_template_name = string_match(ammo_template_name, "^base_(.+)$") or ammo_template_name
			ammo_unit = AMMO_UNIT_BY_AMMO_TEMPLATE[ammo_template_name]
				or AMMO_UNIT_BY_AMMO_FAMILY[string_match(ammo_template_name, "^(.-)_p%d")]
		end

		ammo_unit = ammo_unit or DEFAULT_AMMO_UNIT
		ammo_unit_by_weapon_template[weapon_template] = ammo_unit
	end

	return ammo_unit
end

-- Every ammo pickup is instant: the server starts it, adds the ammo and stops it in the same frame, and clients receive
-- the start and stop together, before they read a teammate's new ammo. So the ammo read here is from before the pickup.
mod:hook_safe("InteracteeExtension", "started", function(self, interactor_unit)
	local scope = mod.setting(SETTING_ID)

	if scope ~= "all" and scope ~= "teammates" then
		return
	end

	if not interactor_unit or self:interaction_type() ~= "ammunition" then
		return
	end

	local t = Managers.time:time("gameplay")
	local entry = pending_by_interactor[interactor_unit]

	if entry and entry.interactee == self and t - entry.t < SNAPSHOT_LIFETIME then
		return
	end

	if scope == "teammates" and _is_local_player_unit(interactor_unit) then
		return
	end

	local interactee_unit = self._unit
	local pickup_name = ALIVE[interactee_unit] and Unit.get_data(interactee_unit, "pickup_type")
	local is_crate = CRATE_PICKUPS[pickup_name]
	local pickup_data = (is_crate or MESSAGE_KEYS[pickup_name]) and Pickups.by_name[pickup_name]

	if not pickup_data then
		return
	end

	local ammo_reserve, max_ammo_reserve, ammo_clip, max_ammo_clip, ammo_slot_name = weapon_ammo_totals(interactor_unit)

	-- without a weapon that uses ammo, the pickup gives no ammo to report
	if not ammo_reserve then
		return
	end

	local pickup_amount = pickup_ammo_amount(pickup_data, max_ammo_reserve, max_ammo_clip)
	local gained, wasted =
		split_pickup_ammo(pickup_amount, ammo_reserve + ammo_clip, max_ammo_reserve + max_ammo_clip)

	if not entry then
		entry = {
			interactee = false,
			t = 0,
			message_key = false,
			gained_key = false,
			wasted_key = false,
			amount = 0,
			wasted = 0,
		}
		pending_by_interactor[interactor_unit] = entry
	end

	entry.interactee = self
	entry.t = t

	if is_crate then
		-- The share of the reserve refilled, rounded down. The ammo a crate adds for a part-empty magazine can take the
		-- reserve past its max, so the share stops at 100%.
		local refilled_percent = math_floor(math_min(gained, max_ammo_reserve) * 100 / max_ammo_reserve)

		entry.message_key = refilled_percent == 0 and gained > 0 and CRATE_UNDER_ONE_PERCENT_MESSAGE_KEY
			or CRATE_MESSAGE_KEY
		entry.gained_key = false
		entry.wasted_key = false
		entry.amount = refilled_percent
		entry.wasted = 0
	else
		local ammo_unit = _ammo_unit(interactor_unit, ammo_slot_name)

		entry.message_key = MESSAGE_KEYS[pickup_name]
		entry.gained_key = gained == 1 and GAINED_ONE_KEYS[ammo_unit] or GAINED_KEYS[ammo_unit]
		entry.wasted_key = wasted > 0 and (wasted == 1 and WASTED_ONE_KEY or WASTED_KEY)
		entry.amount = gained
		entry.wasted = wasted
	end
end)

-- Runs once per interaction on every machine: on the host straight away, on clients when the server's stop arrives
mod:hook_safe("InteracteeExtension", "stopped", function(self, result, interactor_unit)
	local entry = interactor_unit and pending_by_interactor[interactor_unit]

	if not entry or entry.interactee ~= self then
		return
	end

	-- whatever the result, this pickup is done
	entry.interactee = false

	if result ~= "success" then
		return
	end

	local scope = mod.setting(SETTING_ID)

	if scope ~= "all" and scope ~= "teammates" then
		return
	end

	local player = Managers.state.player_unit_spawn:owner(interactor_unit)

	if not player or scope == "teammates" and player == Managers.player:local_player(1) then
		return
	end

	local player_name =
		Text.apply_color_to_text(player:name(), UISettings.player_slot_colors[player:slot()] or PLAYER_DEFAULT_COLOR)
	local gained_key = entry.gained_key

	-- A tin or stash message takes the ammo gained, and any wasted, as text in the weapon's ammo unit; a crate message
	-- takes its percentage
	if gained_key then
		local amount_text = mod:localize(gained_key, entry.amount)
		local wasted_key = entry.wasted_key

		if wasted_key then
			amount_text = mod:localize(GAINED_AND_WASTED_KEY, amount_text, mod:localize(wasted_key, entry.wasted))
		end

		return Managers.event:trigger(
			"event_add_combat_feed_message",
			mod:localize(entry.message_key, player_name, amount_text)
		)
	end

	Managers.event:trigger("event_add_combat_feed_message", mod:localize(entry.message_key, player_name, entry.amount))
end)

-- Pickups that never stopped, and the units of players who died or left, must not outlive the mission
mod.clear_ammo_pickup_notifications = function()
	table.clear(pending_by_interactor)
end
