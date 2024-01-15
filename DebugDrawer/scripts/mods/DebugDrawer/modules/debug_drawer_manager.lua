local mod = get_mod("DebugDrawer")
local DebugDrawer = mod:io_dofile("scripts/mods/DebugDrawer/modules/debug_drawer")

local DebugManager = class("DebugManager")

DebugManager.init = function(self, world)
	self._world = world
	self._drawers = {}
	-- self._actor_draw = {}
end

DebugManager.drawer = function(self, drawer_name, mode)
	fassert(mode == "immediate" or mode == "stay", string.format("Invalid drawer mode %q", mode))

	local drawer = nil

	if drawer_name == nil then
		local line_object = World.create_line_object(self._world)
		drawer = DebugDrawer:new(line_object, mode)
		self._drawers[#self._drawers + 1] = drawer
	elseif self._drawers[drawer_name] == nil then
		local line_object = World.create_line_object(self._world)
		drawer = DebugDrawer:new(line_object, mode)
		self._drawers[drawer_name] = drawer
	else
		drawer = self._drawers[drawer_name]
	end

	return drawer
end

DebugManager.reset_drawer = function(self, drawer_name)
	if self._drawers[drawer_name] then
		self._drawers[drawer_name]:reset()
	end
end

DebugManager.update = function(self, dt, t)
	-- self:_update_actor_draw(dt)

	for _drawer_name, drawer in pairs(self._drawers) do
		drawer:update(self._world)
	end

	-- self:_clear_debug_draws()
end

-- DebugManager._clear_debug_draws = function (self)
-- 	if DebugKeyHandler.key_pressed("x", "clear quickdraw", "ai debugger", nil, "FreeFlight") then
-- 		QuickDrawerStay:reset()
-- 		Debug.reset_sticky_world_texts()
-- 	end
-- end

-- DebugManager._update_actor_draw = function (self, dt)
-- 	local world = self._world
-- 	local physics_world = World.get_data(world, "physics_world")
-- 	local pose = World.debug_camera_pose(world)

-- 	for _, data in pairs(self._actor_draw) do
-- 		PhysicsWorld.overlap(physics_world, function (...)
-- 			self:_actor_draw_overlap_callback(data, ...)
-- 		end, "shape", "sphere", "size", data.range, "pose", pose, "types", "both", "collision_filter", data.collision_filter)

-- 		if data.actors then
-- 			local drawer = self._actor_drawer

-- 			for _, actor in ipairs(data.actors) do
-- 				local box = ActorBox(actor)
-- 				local unboxed = box:unbox()

-- 				if unboxed then
-- 					drawer:actor(actor, data.color:unbox(), pose)
-- 				end
-- 			end
-- 		end
-- 	end
-- end

-- DebugManager._actor_draw_overlap_callback = function (self, data, actors)
-- 	data.actors = actors
-- end

-- DebugManager.enable_actor_draw = function (self, collision_filter, color, range)
-- 	local world = self._world
-- 	local physics_world = World.physics_world(world)

-- 	PhysicsWorld.immediate_overlap(physics_world, "shape", "sphere", "size", 0.1, "position", Vector3(0, 0, 0), "types", "both", "collision_filter", collision_filter)

-- 	self._actor_drawer = self:drawer({
-- 		mode = "immediate",
-- 		name = "_actor_drawer"
-- 	})
-- 	self._actor_draw[collision_filter] = {
-- 		color = QuaternionBox(color),
-- 		range = range,
-- 		collision_filter = collision_filter
-- 	}
-- end

-- DebugManager.disable_actor_draw = function (self, collision_filter)
-- 	self._actor_draw[collision_filter] = nil
-- end

-- DebugManager._create_screen_gui = function (self)
-- 	self._screen_gui = World.create_screen_gui(self._world, "material", "materials/fonts/gw_fonts", "immediate")
-- end

-- DebugManager.draw_screen_rect = function (self, x, y, z, w, h, color)
-- 	if not self._screen_gui then
-- 		self:_create_screen_gui()
-- 	end

-- 	Gui.rect(self._screen_gui, Vector3(x, y, z or 1), Vector2(w, h), color or Color(255, 255, 255, 255))
-- end

-- DebugManager.draw_screen_text = function (self, x, y, z, text, size, color, font)
-- 	if not self._screen_gui then
-- 		self:_create_screen_gui()
-- 	end

-- 	local font_type = font or "hell_shark"
-- 	local font_by_resolution = UIFontByResolution({
-- 		dynamic_font = true,
-- 		font_type = font_type,
-- 		font_size = size
-- 	})
-- 	local font, size, material = unpack(font_by_resolution)

-- 	Gui.text(self._screen_gui, text, font, size, material, Vector3(x, y, z), color or Color(255, 255, 255, 255))
-- end

-- DebugManager.screen_text_extents = function (self, text, size)
-- 	if not self._screen_gui then
-- 		self:_create_screen_gui()
-- 	end

-- 	local min, max = Gui.text_extents(self._screen_gui, text, GameSettings.ingame_font.font, size)
-- 	local width = max[1] - min[1]
-- 	local height = max[2] - min[2]

-- 	return width, height
-- end

DebugManager.destroy = function(self)
	if self._screen_gui then
		World.destroy_gui(self._world, self._screen_gui)

		self._screen_gui = nil
	end
end

return DebugManager
