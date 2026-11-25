-- Ammo pickup notifications
-- Description: Shows the Ammo Tins, Ammo Stashes and Grenades you and your teammates pick up in the combat feed, with
-- the ammo and Blitz charges gained and wasted, and how much ammo each Ammo Crate charge refilled.
local mod = get_mod("NumericUI")

local BuffSettings = require("scripts/settings/buff/buff_settings")
local Pickups = require("scripts/settings/pickup/pickups")
local SpecialRulesSettings = require("scripts/settings/ability/special_rules_settings")
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
-- joins an amount gained and the amount wasted
local JOIN_KEY = "ammo_pickup_join"
-- The deployable crate, and the expedition crate the game also calls an Ammo Crate
local CRATE_PICKUPS = {
	ammo_cache_deployable = true,
	large_ammunition_crate = true,
}
local CRATE_MESSAGE_KEY = "ammo_pickup_notification_crate"
-- for a crate that refilled something, but less than 1%
local CRATE_UNDER_ONE_PERCENT_MESSAGE_KEY = "ammo_pickup_notification_crate_under_one_percent"

-- The Grenade pickup, which refills a Blitz instead of ammo
local GRENADE_MESSAGE_KEY = "ammo_pickup_notification_grenade"
local BLITZ_GAINED_KEY = "ammo_pickup_blitz_gained"
-- an ammo pickup's message with the Blitz charges the pickup also restored
local WITH_BLITZ_MESSAGE_KEY = "ammo_pickup_notification_with_blitz"
-- the game's own word for a Blitz, for an ability no talent names
local BLITZ_FALLBACK_NAME_KEY = "loc_talents_category_tactical"
local GRENADE_ABILITY_TYPE = "grenade_ability"
local special_rules = SpecialRulesSettings.special_rules
local IMPROVED_AMMO_PICKUPS_KEYWORD = BuffSettings.keywords.improved_ammo_pickups

-- the combat feed's colour for a player without a slot colour
local PLAYER_DEFAULT_COLOR = Color.ui_hud_green_light(255, true)

-- The ammo pickup each interactor started last, with its result worked out from the ammo before the pickup. Every
-- interactor unit keeps one entry, reused for its next pickup.
local pending_by_interactor = {}

-- The ammo unit of each weapon template, worked out on the first pickup with it
local ammo_unit_by_weapon_template = {}

-- The loc key of each ability's name, from the talent that grants it. Built on the first Blitz refill.
local ability_name_keys = nil

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

local function _blitz_name_key(ability_extension)
	if not ability_name_keys then
		ability_name_keys = {}

		local ArchetypeTalents = require("scripts/settings/ability/archetype_talents/archetype_talents")

		for _, talents in pairs(ArchetypeTalents) do
			for _, talent in pairs(talents) do
				local player_ability = talent.player_ability
				local ability = player_ability and player_ability.ability

				if ability and ability.name and talent.display_name then
					ability_name_keys[ability.name] = talent.display_name
				end
			end
		end
	end

	local ability = ability_extension:equipped_abilities()[GRENADE_ABILITY_TYPE]

	return ability and ability_name_keys[ability.name] or BLITZ_FALLBACK_NAME_KEY
end

-- Splits the Blitz charges a pickup restores into the charges gained and the charges left over, the way ammo is split.
-- The game restores charges up to the Blitz's max, so a pickup offers a full Blitz at most. A Grenade, which restores
-- 100 charges, always offers a full Blitz.
local function _split_blitz_charges(ability_extension, max_charges, pickup_charges)
	return split_pickup_ammo(
		math_min(pickup_charges, max_charges),
		ability_extension:remaining_ability_charges(GRENADE_ABILITY_TYPE),
		max_charges
	)
end

-- Whether anyone on the interactor's side makes Ammo Crates share grenades, through a Veteran talent. The keyword
-- reaches clients, as the game syncs it over the network.
local function _side_shares_grenades(interactor_unit)
	local side = Managers.state.extension:system("side_system").side_by_unit[interactor_unit]
	local player_units = side and side.player_units

	if player_units then
		for _, player_unit in pairs(player_units) do
			local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")

			if buff_extension and buff_extension:has_keyword(IMPROVED_AMMO_PICKUPS_KEYWORD) then
				return true
			end
		end
	end

	return false
end

-- The Blitz charges an ammo pickup also restores and wastes, decided and worked out the way AmmunitionInteraction does
local function _ammo_pickup_blitz_charges(interactor_unit, ability_extension, pickup_data)
	local talent_extension = ScriptUnit.has_extension(interactor_unit, "talent_system")
	local refills

	if talent_extension and talent_extension:has_special_rule(special_rules.disable_grenade_pickups) then
		-- A Blitz that can't use Grenades, like Blades of Faith, refills from ammo only through its own talent
		refills = talent_extension:has_special_rule(special_rules.ammo_pickups_refills_grenades)
	else
		refills = pickup_data.refill_grenades
			or pickup_data.allow_grenade_sharing and _side_shares_grenades(interactor_unit)
	end

	if not refills then
		return 0, 0
	end

	local max_charges = ability_extension:max_ability_charges(GRENADE_ABILITY_TYPE)

	return _split_blitz_charges(ability_extension, max_charges, pickup_ammo_amount(pickup_data, max_charges, 0))
end

-- An amount with the amount wasted joined on, if any was
local function _with_wasted(text, wasted)
	if wasted > 0 then
		return mod:localize(JOIN_KEY, text, mod:localize(wasted == 1 and WASTED_ONE_KEY or WASTED_KEY, wasted))
	end

	return text
end

-- Every ammo and Grenade pickup is instant: the server starts it, adds the ammo or Blitz charges and stops it in the
-- same frame, and clients receive the start and stop together, before they read a teammate's new ammo and charges. So
-- what is read here is from before the pickup.
mod:hook_safe("InteracteeExtension", "started", function(self, interactor_unit)
	local scope = mod.setting(SETTING_ID)

	if scope ~= "all" and scope ~= "teammates" then
		return
	end

	local interaction_type = interactor_unit and self:interaction_type()
	local is_grenade = interaction_type == "grenade"

	if not is_grenade and interaction_type ~= "ammunition" then
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
	local pickup_data = pickup_name and Pickups.by_name[pickup_name]

	if not pickup_data then
		return
	end

	local ability_extension = ScriptUnit.has_extension(interactor_unit, "ability_system")
	local has_blitz = ability_extension and ability_extension:ability_is_equipped(GRENADE_ABILITY_TYPE)
	local message_key, gained_key, amount, wasted
	local blitz_charges, blitz_wasted = 0, 0

	if is_grenade then
		if has_blitz then
			blitz_charges, blitz_wasted = _split_blitz_charges(
				ability_extension,
				ability_extension:max_ability_charges(GRENADE_ABILITY_TYPE),
				pickup_data.charges_restored or 0
			)
		end

		-- the game only allows a Grenade pickup that refills something
		if blitz_charges <= 0 then
			return
		end

		message_key, gained_key, amount, wasted = GRENADE_MESSAGE_KEY, false, 0, 0
	else
		local is_crate = CRATE_PICKUPS[pickup_name]

		if not is_crate and not MESSAGE_KEYS[pickup_name] then
			return
		end

		local ammo_reserve, max_ammo_reserve, ammo_clip, max_ammo_clip, ammo_slot_name =
			weapon_ammo_totals(interactor_unit)

		-- without a weapon that uses ammo, the pickup gives no ammo to report
		if not ammo_reserve then
			return
		end

		local pickup_amount = pickup_ammo_amount(pickup_data, max_ammo_reserve, max_ammo_clip)
		local gained

		gained, wasted = split_pickup_ammo(pickup_amount, ammo_reserve + ammo_clip, max_ammo_reserve + max_ammo_clip)

		if has_blitz then
			blitz_charges, blitz_wasted = _ammo_pickup_blitz_charges(interactor_unit, ability_extension, pickup_data)
		end

		if is_crate then
			-- The share of the reserve refilled, rounded down. The ammo a crate adds for a part-empty magazine can take
			-- the reserve past its max, so the share stops at 100%.
			local refilled_percent = math_floor(math_min(gained, max_ammo_reserve) * 100 / max_ammo_reserve)

			message_key = refilled_percent == 0 and gained > 0 and CRATE_UNDER_ONE_PERCENT_MESSAGE_KEY
				or CRATE_MESSAGE_KEY
			-- the share stands in for the ammo gained and wasted; the Blitz charges keep their count and waste
			gained_key, amount, wasted = false, refilled_percent, 0
		else
			local ammo_unit = _ammo_unit(interactor_unit, ammo_slot_name)

			message_key = MESSAGE_KEYS[pickup_name]
			gained_key = gained == 1 and GAINED_ONE_KEYS[ammo_unit] or GAINED_KEYS[ammo_unit]
			amount = gained
		end
	end

	if not entry then
		entry = {
			interactee = false,
			t = 0,
			message_key = false,
			gained_key = false,
			amount = 0,
			wasted = 0,
			blitz_name_key = false,
			blitz_charges = 0,
			blitz_wasted = 0,
		}
		pending_by_interactor[interactor_unit] = entry
	end

	entry.interactee = self
	entry.t = t
	entry.message_key = message_key
	entry.gained_key = gained_key
	entry.amount = amount
	entry.wasted = wasted
	entry.blitz_name_key = blitz_charges > 0 and _blitz_name_key(ability_extension)
	entry.blitz_charges = blitz_charges
	entry.blitz_wasted = blitz_wasted
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
	local blitz_name_key = entry.blitz_name_key
	-- the Blitz charges the pickup restored, and any it wasted
	local blitz_text = blitz_name_key
		and _with_wasted(
			mod:localize(BLITZ_GAINED_KEY, Localize(blitz_name_key), entry.blitz_charges),
			entry.blitz_wasted
		)
	local message_key = entry.message_key
	local gained_key = entry.gained_key
	local message

	if message_key == GRENADE_MESSAGE_KEY then
		message = mod:localize(GRENADE_MESSAGE_KEY, player_name, blitz_text)
	else
		if gained_key then
			-- A tin or stash: the ammo gained in the weapon's ammo unit, and any wasted
			message = mod:localize(
				message_key,
				player_name,
				_with_wasted(mod:localize(gained_key, entry.amount), entry.wasted)
			)
		else
			-- A crate: the share of ammo it refilled
			message = mod:localize(message_key, player_name, entry.amount)
		end

		-- any Blitz charges the ammo pickup also restored, after the ammo
		if blitz_text then
			message = mod:localize(WITH_BLITZ_MESSAGE_KEY, message, blitz_text)
		end
	end

	Managers.event:trigger("event_add_combat_feed_message", message)
end)

-- Pickups that never stopped, and the units of players who died or left, must not outlive the mission
mod.clear_ammo_pickup_notifications = function()
	table.clear(pending_by_interactor)
end
