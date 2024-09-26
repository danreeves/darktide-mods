local mod = get_mod("NumericUI")
local decals = mod:persistent_table("medical_crate_decals")
local medical_crate_config = require("scripts/settings/deployables/medical_crate")
local decal_unit_name = "content/levels/training_grounds/fx/decal_aoe_indicator"
local package_name = "content/levels/training_grounds/missions/mission_tg_basic_combat_01"

local function unit_spawned(unit, dont_load_package)
	if not mod:get("show_medical_crate_radius") then
		return
	end

	if not Managers.package:has_loaded(package_name) and not dont_load_package then
		Managers.package:load(package_name, "NumericUI", function()
			unit_spawned(unit, true)
		end)
		return
	end

	if not unit then
		return
	end

	local world = Unit.world(unit)
	local position = Unit.local_position(unit, 1)

	-- Create decal unit
	local decal_unit = World.spawn_unit_ex(world, decal_unit_name, nil, position + Vector3(0, 0, 0.1))

	-- Set size of unit
	local diameter = medical_crate_config.proximity_radius * 2 + 1.5
	Unit.set_local_scale(decal_unit, 1, Vector3(diameter, diameter, 1))

	-- Set color of unit
	local material_value = Quaternion.identity()
	Quaternion.set_xyzw(material_value, 0, 1, 0, 0.5)
	Unit.set_vector4_for_material(decal_unit, "projector", "particle_color", material_value, true)

	-- Set low opacity
	Unit.set_scalar_for_material(decal_unit, "projector", "color_multiplier", 0.05)

	decals[unit] = decal_unit
end

local function pre_unit_destroyed(unit)
	local world = Unit.world(unit)
	local decal_unit = decals[unit]
	if decal_unit then
		World.destroy_unit(world, decal_unit)
		decals[unit] = nil
	end
end

mod:hook_require("scripts/extension_systems/unit_templates", function(instance)
	mod:hook_safe(instance.medical_crate_deployable, "husk_init", function(unit)
		unit_spawned(unit, false)
	end)

	if instance.medical_crate_deployable.pre_unit_destroyed then
		mod:hook_safe(instance.medical_crate_deployable, "pre_unit_destroyed", pre_unit_destroyed)
	else
		instance.medical_crate_deployable.pre_unit_destroyed = pre_unit_destroyed
	end
end)
