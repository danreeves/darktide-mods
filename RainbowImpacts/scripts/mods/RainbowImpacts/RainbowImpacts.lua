local mod = get_mod("RainbowImpacts")

local hits = mod:persistent_table("hits")

mod:hook_safe(
	"FxSystem",
	"play_surface_impact_fx",
	function(
		self,
		hit_position,
		hit_direction,
		source_parameters,
		attacking_unit,
		optional_hit_normal,
		damage_type,
		hit_type,
		optional_will_be_predicted
	)
		table.insert(hits, {
			created_t = Managers.time:time("main"),
			position = Vector3Box(hit_position),
			direction = Vector3Box(hit_direction),
			decal_unit = nil,
		})
	end
)

local function create_decal_unit(world, position, rotation)
	local decal_unit_name = "content/levels/training_grounds/fx/decal_aoe_indicator"
	local rx, ry, rz = Vector3.to_elements(rotation)
	local orientation = Quaternion.from_euler_angles_xyz(rx, ry, rz)
	local decal_unit = World.spawn_unit_ex(world, decal_unit_name, nil, position, orientation)
	local diameter = 0.1
	Unit.set_local_scale(decal_unit, 1, Vector3(diameter, diameter, 1))

	local material_value = Quaternion.identity()
	Quaternion.set_xyzw(material_value, math.random(), math.random(), math.random(), math.random())
	Unit.set_vector4_for_material(decal_unit, "projector", "particle_color", material_value, true)
	return decal_unit
end

mod.update = function(dt)
	local t = Managers.time:time("main")
	local player = Managers.player:local_player_safe(1)
	if not player or not player.player_unit then
		return
	end
	local world = Unit.world(player.player_unit)

	for i = 1, #hits do
		local hit = hits[i]
		if not hit then
			break
		end

		if not hit.decal_unit then
			hit.decal_unit = create_decal_unit(world, hit.position:unbox(), hit.direction:unbox())
		end

		if hit.decal_unit then
			local diameter = math.ease_out_exp(t - hit.created_t) * 2
			Unit.set_local_scale(hit.decal_unit, 1, Vector3(diameter, diameter, 1))
		end

		if t - hit.created_t > 1 then
			World.destroy_unit(world, hit.decal_unit)
			table.remove(hits, i)
		end
	end
end
