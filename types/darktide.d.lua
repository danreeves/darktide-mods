---@meta


---@class Imgui
Imgui = {}

---@class RESOLUTION_LOOKUP
RESOLUTION_LOOKUP = {}

---@type boolean
HAS_STEAM = false

---@type boolean
IS_WINDOWS = false

---@type any
HEALTH_ALIVE = nil

---@type any
ALIVE = nil

---@class cjson
cjson = {}

---Encode a table to JSON
---@param tbl table The table to encode
---@return string
function cjson.encode(tbl) end

---Decode a JSON string to a table
---@param json string The JSON string to decode
---@return table
function cjson.decode(json) end

---Check if a string starts with a prefix
---@param str string The string to check
---@param prefix string The prefix to look for
---@return boolean
function string.starts_with(str, prefix) end

---Split a string by a delimiter
---@param str string The string to split
---@param delimiter string The delimiter to split by
---@return table
function string.split(str, delimiter) end

---Trim whitespace from a string
---@param str string The string to trim
---@return string
function string.trim(str) end

---Check if an array contains a value
---@param tbl table The table to search
---@param value any The value to find
---@return boolean
function table.array_contains(tbl, value) end

---Clear all entries from a table
---@param tbl table The table to clear
function table.clear(tbl) end

---Return the item the test function returns true for
---@param tbl table The table to clear
---@param fn function The test function
function table.find_func_array(tbl, fn) end

---Clear array entries from a table
---@param tbl table The table to clear
---@param count number Number of entries to clear
function table.clear_array(tbl, count) end

---Find an entry in a table by key-value pair
---@param tbl table The table to search
---@param key string The key to match
---@param value any The value to match
---@return any
function table.find_by_key(tbl, key, value) end

---Get all keys from a table
---@param tbl table The table to get keys from
---@return table
function table.keys(tbl) end

---Clone a table
---@param tbl table The table to clone
---@return table
function table.clone(tbl) end

---Merge two tables
---@param target table The target table
---@param source table The source table to merge from
---@return table
function table.merge(target, source) end

---Recursively merge two tables
---@param target table The target table
---@param source table The source table to merge from
---@return table
function table.merge_recursive(target, source) end

---Map a function over a table
---@param tbl table The table to map over
---@param fn function The function to apply
---@param result? table Optional result table
---@return table
function table.map(tbl, fn, result) end

---Filter a table with a predicate function
---@param tbl table The table to filter
---@param fn function The predicate function
---@return table
function table.filter(tbl, fn) end

---Check if a table is empty
---@param tbl table The table to check
---@return boolean
function table.is_empty(tbl) end

---Calculate the average of numeric values in a table
---@param tbl table The table containing numbers
---@return number
function table.average(tbl) end

---Cubic ease-in function
---@param t number Time parameter (0-1)
---@return number
function math.easeInCubic(t) end

---Cubic ease-out function
---@param t number Time parameter (0-1)
---@return number
function math.easeOutCubic(t) end

---Round a number with precision
---@param value number The number to round
---@param precision number The decimal precision
---@return number
function math.round_with_precision(value, precision) end

---Clamp a value between min and max
---@param value number The value to clamp
---@param min number The minimum value
---@param max number The maximum value
---@return number
function math.clamp(value, min, max) end

---Round a number to the nearest integer
---@param value number The number to round
---@return number
function math.round(value) end

---Check if a value is NaN
---@param value any The value to check
---@return boolean
function math.is_nan(value) end

---Linear interpolation
---@param a number Start value
---@param b number End value
---@param t number Interpolation factor (0-1)
---@return number
function math.lerp(a, b, t) end

---Exponential ease function
---@param a number Start value
---@param b number End value
---@param t number Time parameter
---@return number
function math.ease_exp(a, b, t) end

---@class ScriptUnit
ScriptUnit = {}

---Check if a unit has an extension
---@param unit table The unit to check
---@param extension_name string The extension name
---@return boolean
function ScriptUnit.has_extension(unit, extension_name) end

---Get a unit's extension
---@param unit table The unit
---@param extension_name string The extension name
---@return any
function ScriptUnit.extension(unit, extension_name) end

---@class Window
Window = {}

---Check if the window has focus
---@return boolean
function Window.has_focus() end

---@class Wwise
Wwise = {}

---Set a Wwise parameter
---@param param string The parameter name
---@param value any The parameter value
function Wwise.set_parameter(param, value) end

---@class Application
Application = {}

---Get a user setting
---@param setting string The setting name
---@param default? string Optional default value
---@return any
function Application.user_setting(setting, default) end

---Get the back buffer size
---@return number, number
function Application.back_buffer_size() end

---Open a URL in the default browser
---@param url string The URL to open
function Application.open_url_in_browser(url) end

---Convert a 64-bit hex string to decimal
---@param hex string The hex string
---@return string
function Application.hex64_to_dec(hex) end

---@class Profiler
Profiler = {}

---Get Lua statistics
---@return table
function Profiler.lua_stats() end

---@class Vector3
Vector3 = {}

---Create a new Vector3
---@param x number X component
---@param y number Y component
---@param z number Z component
---@return table
function Vector3(x, y, z) end

---Normalize a vector
---@param vec table The vector to normalize
---@return table
function Vector3.normalize(vec) end

---Get the length of a vector
---@param vec table The vector
---@return number
function Vector3.length(vec) end

---Get the up vector (0, 1, 0)
---@return table
function Vector3.up() end

---Get the forward vector (0, 0, 1)
---@return table
function Vector3.forward() end

---Get the right vector (1, 0, 0)
---@return table
function Vector3.right() end

---Cross product of two vectors
---@param a table First vector
---@param b table Second vector
---@return table
function Vector3.cross(a, b) end

---Create axes from a vector
---@param vec table The vector
---@return table, table, table
function Vector3.make_axes(vec) end

---@class Vector3Box
Vector3Box = {}

---@class Quaternion
Quaternion = {}

---Get the identity quaternion
---@return table
function Quaternion.identity() end

---Set quaternion components
---@param q table The quaternion
---@param x number X component
---@param y number Y component
---@param z number Z component
---@param w number W component
function Quaternion.set_xyzw(q, x, y, z, w) end

---Create a quaternion from yaw, pitch, and roll
---@param yaw number Yaw rotation
---@param pitch number Pitch rotation
---@param roll number Roll rotation
---@return table
function Quaternion.from_yaw_pitch_roll(yaw, pitch, roll) end

---Rotate a vector by a quaternion
---@param q table The quaternion
---@param vec table The vector to rotate
---@return table
function Quaternion.rotate(q, vec) end

---Get the up direction from a quaternion
---@param q table The quaternion
---@return table
function Quaternion.up(q) end

---Get the forward direction from a quaternion
---@param q table The quaternion
---@return table
function Quaternion.forward(q) end

---Get the right direction from a quaternion
---@param q table The quaternion
---@return table
function Quaternion.right(q) end

---@class Matrix4x4
Matrix4x4 = {}

---Get rotation matrix from a transform
---@param matrix table The transform matrix
---@return table
function Matrix4x4.rotation(matrix) end

---Get translation from a transform
---@param matrix table The transform matrix
---@return table
function Matrix4x4.translation(matrix) end

---Get the right vector from a matrix
---@param matrix table The matrix
---@return table
function Matrix4x4.right(matrix) end

---Get the forward vector from a matrix
---@param matrix table The matrix
---@return table
function Matrix4x4.forward(matrix) end

---Get the up vector from a matrix
---@param matrix table The matrix
---@return table
function Matrix4x4.up(matrix) end

---Create a matrix from quaternion and position
---@param q table The quaternion
---@param pos table The position vector
---@return table
function Matrix4x4.from_quaternion_position(q, pos) end

---@class Unit
Unit = {}

---Get the world position of a unit
---@param unit table The unit
---@param node number Node index
---@return table
function Unit.world_position(unit, node) end

---Get a node from a unit
---@param unit table The unit
---@param node_name string The node name
---@return number
function Unit.node(unit, node_name) end

---Get the world of a unit
---@param unit table The unit
---@return table
function Unit.world(unit) end

---Get the local position of a unit
---@param unit table The unit
---@param node number Node index
---@return table
function Unit.local_position(unit, node) end

---Set the local scale of a unit
---@param unit table The unit
---@param node number Node index
---@param scale table The scale vector
function Unit.set_local_scale(unit, node, scale) end

---Set a vector4 parameter for a material
---@param unit table The unit
---@param material string Material name
---@param param string Parameter name
---@param value table The vector value
function Unit.set_vector4_for_material(unit, material, param, value) end

---Set a scalar parameter for a material
---@param unit table The unit
---@param material string Material name
---@param param string Parameter name
---@param value number The scalar value
function Unit.set_scalar_for_material(unit, material, param, value) end

---Set a vector3 parameter for all materials on a unit
---@param unit table The unit
---@param param string Parameter name
---@param value table The vector3 value
---@param apply_to_all boolean Whether to apply to all materials
function Unit.set_vector3_for_materials(unit, param, value, apply_to_all) end

---Set the local position of a unit
---@param unit table The unit
---@param node number Node index
---@param position table The position vector
function Unit.set_local_position(unit, node, position) end

---Get the world rotation of a unit
---@param unit table The unit
---@param node number Node index
---@return table
function Unit.world_rotation(unit, node) end

---Get the bounding box of a unit
---@param unit table The unit
---@return table
function Unit.box(unit) end

---@class World
World = {}

---Spawn a unit
---@param world table The world
---@param name string Unit name
---@param position table Position vector
---@param rotation table Rotation quaternion
---@return table
function World.spawn_unit_ex(world, name, position, rotation) end

---Destroy a unit
---@param world table The world
---@param unit table The unit to destroy
function World.destroy_unit(world, unit) end

---Update a unit and its children
---@param world table The world
---@param unit table The unit to update
function World.update_unit_and_children(world, unit) end

---Destroy a GUI
---@param world table The world
---@param gui table The GUI to destroy
function World.destroy_gui(world, gui) end

---Create a line object for debug drawing
---@param world table The world
---@return table
function World.create_line_object(world) end

---@class LineObject
LineObject = {}

---Add a line to the line object
---@param line_object table The line object
---@param color table Color vector
---@param from table Start position vector
---@param to table End position vector
function LineObject.add_line(line_object, color, from, to) end

---Reset the line object
---@param line_object table The line object
function LineObject.reset(line_object) end

---Dispatch the line object for rendering
---@param line_object table The line object
---@param world table The world
function LineObject.dispatch(line_object, world) end

---Set the color of the line object
---@param line_object table The line object
---@param color table Color vector
function LineObject.set_color(line_object, color) end

---Add a sphere to the line object
---@param line_object table The line object
---@param color table Color vector
---@param position table Position vector
---@param radius number Sphere radius
---@param segments number Number of segments
---@param iterations number Number of iterations
function LineObject.add_sphere(line_object, color, position, radius, segments, iterations) end

---Add a capsule to the line object
---@param line_object table The line object
---@param color table Color vector
---@param start table Start position vector
---@param end_pos table End position vector
---@param radius number Capsule radius
function LineObject.add_capsule(line_object, color, start, end_pos, radius) end

---Add a box to the line object
---@param line_object table The line object
---@param color table Color vector
---@param position table Position vector
---@param size table Size vector
function LineObject.add_box(line_object, color, position, size) end

---Add a cone to the line object
---@param line_object table The line object
---@param color table Color vector
---@param position table Position vector
---@param direction table Direction vector
---@param length number Cone length
---@param angle number Cone angle
---@param segments number Number of segments
function LineObject.add_cone(line_object, color, position, direction, length, angle, segments) end

---Add a circle to the line object
---@param line_object table The line object
---@param color table Color vector
---@param radius number Circle radius
---@param x number X component
---@param y number Y component
---@param z number Z component
function LineObject.add_circle(line_object, color, radius, x, y, z) end

---@class Actor
Actor = {}

---Debug draw an actor
---@param actor table The actor
---@param line_object table Line object for drawing
---@param color table Color vector
---@param duration table Duration
function Actor.debug_draw(actor, line_object, color, duration) end

---@class Backend
Backend = {}

---@type string
Backend.AUTH_METHOD_STEAM = "steam"

---Get the authentication method
---@return string
function Backend.get_auth_method() end

---@class Steam
Steam = {}

---Get the Steam user ID
---@return string
function Steam.user_id() end

---Convert a Steam ID from hex to decimal
---@param hex string The hex string
---@return string
function Steam.id_hex_to_dec(hex) end

---Retrieve an auth session ticket
---@return number
function Steam.retrieve_auth_session_ticket() end

---Poll an auth session ticket
---@param ticket_handle number The ticket handle
---@return boolean
function Steam.poll_auth_session_ticket(ticket_handle) end

---@class XboxLive
XboxLive = {}

---Get the Xbox Live user ID
---@return string
function XboxLive.user_id() end

---Convert an Xbox Live XUID from hex to decimal
---@param hex string The hex string
---@return string
function XboxLive.xuid_hex_to_dec(hex) end

---Create a callback function
---@param obj any The object context
---@param method string|function The method name or function
---@return function
function callback(obj, method) end
