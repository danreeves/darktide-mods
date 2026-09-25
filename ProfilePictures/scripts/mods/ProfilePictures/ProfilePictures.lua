local mod = get_mod("ProfilePictures")

-- Every picture the mod holds a url loader reference for, keyed by profile url and size. The loader refcounts by image url instead, so each entry keeps the url that actually loaded to give its reference back with.
local cache = mod:persistent_table("texture_cache")

-- Profile requests in flight, keyed like the texture cache. Deliberately not persistent: a reload leaves the promises behind.
local pending_requests = {}

local math_clamp = math.clamp
local math_floor = math.floor
local string_byte = string.byte
local string_find = string.find
local string_format = string.format
local string_gsub = string.gsub
local string_match = string.match
local string_sub = string.sub

local DEFAULT_PROXY_PATH = "/avatar?url="

local DEFAULT_STEAM_WORKER_URL = "https://steam-profile-xml-to-json.dnrvs.workers.dev"
local DEFAULT_XBOX_WORKER_URL = "https://xboxapi-workers.dnrvs.workers.dev"
-- Test deployment of PsnAPI-Workers until its host is decided. The psn_worker_url placeholder shows it too.
local DEFAULT_PSN_WORKER_URL = "https://psnapi-workers.lucleto.workers.dev"

-- The resize workers reject anything outside this range
local PROFILE_PICTURE_SIZE_MIN = 50
local PROFILE_PICTURE_SIZE_MAX = 90

-- Part of the texture cache key, which every portrait load builds, so keep it out of the settings lookup path
local profile_picture_size, profile_picture_size_cache_suffix

local function _cache_profile_picture_size()
	local size = mod:get("profile_picture_size")

	if type(size) ~= "number" then
		size = PROFILE_PICTURE_SIZE_MAX
	end

	size = math_floor(math_clamp(size, PROFILE_PICTURE_SIZE_MIN, PROFILE_PICTURE_SIZE_MAX) + 0.5)

	-- A slider drag fires this every frame, so only build the suffix when the value actually moved
	if size ~= profile_picture_size then
		profile_picture_size = size
		profile_picture_size_cache_suffix = "#profile_picture_size=" .. size
	end
end

-- Steam serves the same avatar from several CDN aliases, but `load_texture` fails on the Akamai/Cloudflare ones for some players, so prefer the plain Valve host and keep the url the profile actually returned as a fallback.
local function _steam_avatar_urls(avatar_url)
	local preferred_url = string_gsub(avatar_url, "%.cloudflare%.steamstatic%.com", ".steamstatic.com")

	preferred_url = string_gsub(preferred_url, "%.akamai%.steamstatic%.com", ".steamstatic.com")

	if preferred_url ~= avatar_url then
		return preferred_url, avatar_url
	end

	return avatar_url
end

local function _encode_char(char)
	return string_format("%%%02X", string_byte(char))
end

local function _encoded_url(image_url)
	local encoded_url = string_gsub(image_url, "([^%w%-%_%.%~])", _encode_char)

	return encoded_url
end

local function _proxied_url(proxy_url, image_url)
	return proxy_url .. _encoded_url(image_url)
end

-- The workers answer with a 90x100 transparent png that has the square picture centred at `size`, so it fills the portrait slot without being stretched
local function _resize_url(resize_url, image_url, size)
	return resize_url .. _encoded_url(image_url) .. "&size=" .. size
end

-- Turns whatever the user typed into a prefix the picture url can be appended to, so that "127.0.0.1:8123" and "http://127.0.0.1:8123/avatar?url=" both work.
local function _proxy_url_prefix(proxy_url)
	local prefix = string_match(proxy_url, "^%s*(.-)%s*$")

	if prefix == "" then
		return nil
	end

	local _, scheme_end = string_find(prefix, "://", 1, true)

	if not scheme_end then
		prefix = "http://" .. prefix
		scheme_end = 7
	end

	local last_char = string_sub(prefix, -1)

	-- Already ends where the picture url goes
	if last_char == "=" or last_char == "?" or last_char == "&" then
		return prefix
	end

	if string_find(prefix, "?", scheme_end + 1, true) then
		return prefix .. "&url="
	end

	if last_char == "/" then
		prefix = string_sub(prefix, 1, -2)
	end

	-- Only a host was given, so assume the endpoint of the shim from issue #208
	if not string_find(prefix, "/", scheme_end + 1, true) then
		return prefix .. DEFAULT_PROXY_PATH
	end

	return prefix .. "?url="
end

local _proxy_url_setting, _proxy_url_prefix_cache

local function _image_proxy_prefix()
	local setting = mod:get("image_proxy_url")

	if type(setting) ~= "string" or setting == "" then
		return nil
	end

	-- Only re-parse when the setting actually changed
	if setting ~= _proxy_url_setting then
		_proxy_url_setting = setting
		_proxy_url_prefix_cache = _proxy_url_prefix(setting)
	end

	return _proxy_url_prefix_cache
end

-- Turns whatever the user typed into a base the paths are appended to, so that "my-worker.workers.dev" and "https://my-worker.workers.dev/" both work. Nothing left after the scheme means the built-in deployment.
local function _worker_base_url(setting)
	local base_url = string_match(setting, "^%s*(.-)%s*$")

	if base_url == "" then
		return nil
	end

	local _, scheme_end = string_find(base_url, "://", 1, true)

	if not scheme_end then
		base_url = "https://" .. base_url
		scheme_end = 8
	end

	-- The added paths start with "/", so a trailing one would double up
	base_url = string_match(base_url, "^(.-)/*$")

	if #base_url <= scheme_end then
		return nil
	end

	return base_url
end

-- A platform's profile lookup and /resize both come from the same worker deployment
local steam_worker = {
	setting_id = "steam_worker_url",
	default_url = DEFAULT_STEAM_WORKER_URL,
	profile_path = "/",
}

local xbox_worker = {
	setting_id = "xbox_worker_url",
	default_url = DEFAULT_XBOX_WORKER_URL,
	profile_path = "/profiles/",
}

local psn_worker = {
	setting_id = "psn_worker_url",
	default_url = DEFAULT_PSN_WORKER_URL,
	profile_path = "/profiles/",
}

local WORKERS = {
	steam_worker,
	xbox_worker,
	psn_worker,
}

-- Part of the texture cache key, which every portrait load builds, so resolve the urls here rather than on each load
local function _cache_worker_urls()
	for i = 1, #WORKERS do
		local worker = WORKERS[i]
		local setting = mod:get(worker.setting_id)

		if type(setting) ~= "string" then
			setting = ""
		end

		-- Only re-parse when the setting actually changed
		if setting ~= worker.setting then
			local base_url = _worker_base_url(setting) or worker.default_url

			worker.setting = setting
			worker.profile_url = base_url .. worker.profile_path
			worker.resize_url = base_url .. "/resize?url="
		end
	end
end

local function _steam_image_url(response)
	local body = response and response.body
	local profile = body and body.profile
	local avatar_url = profile and profile.avatarFull

	if type(avatar_url) ~= "string" or avatar_url == "" then
		return nil
	end

	return _steam_avatar_urls(avatar_url)
end

local function _xbox_image_url(response)
	local body = response and response.body
	local gamerpic = body and body.gamerpic

	if type(gamerpic) ~= "string" or gamerpic == "" then
		return nil
	end

	return gamerpic
end

local function _psn_image_url(response)
	local body = response and response.body
	local avatar = body and body.avatar

	if type(avatar) ~= "string" or avatar == "" then
		return nil
	end

	return avatar
end

-- Tries each url in turn and keeps the first one that loads. The url loader remembers a failed url, so a fallback that is needed once is reached straight away afterwards.
local function _load_texture(image_urls, index, cache_key, callbacks)
	local image_url = image_urls[index]

	-- Public urls on third party CDNs, so don't attach the backend auth token
	Managers.url_loader
		:load_texture(image_url, false)
		:next(function(data)
			local entry = cache[cache_key]

			-- A joined profile request ends when the profile answers, not when its picture lands, so a second load for the same picture can finish while this one downloads. Keep the texture that landed first and give this reference back.
			if entry then
				Managers.url_loader:unload_texture(image_url)
			else
				entry = {
					texture = data.texture,
					image_url = image_url,
				}

				cache[cache_key] = entry
			end

			entry.requested = true

			local texture = entry.texture

			for i = 1, #callbacks do
				callbacks[i](texture)
			end
		end)
		:catch(function(_error)
			if image_urls[index + 1] then
				_load_texture(image_urls, index + 1, cache_key, callbacks)

				return
			end

			mod:info("Failed to load profile image '%s'", image_url)
		end)
end

function mod.player_info_for_player(player)
	local is_bot = not player:is_human_controlled()

	if is_bot then
		return
	end

	local player_info = Managers.data_service.social:_get_player_info_for_player(player)

	return player_info
end

-- The platform is resolved lazily through presence, so an account we are the first to ask about reports "" until the stream delivers. Retry once when the first update lands.
local function _load_profile_image(player_info, cb, allow_retry)
	local platform = player_info:platform()

	local xuid, url, get_image_url, resize_url

	if platform == "steam" then
		xuid = Application.hex64_to_dec(player_info:platform_user_id())
		url = steam_worker.profile_url .. xuid
		get_image_url = _steam_image_url
		resize_url = steam_worker.resize_url
	end

	if platform == "xbox" then
		xuid = Application.hex64_to_dec(player_info:platform_user_id())
		url = xbox_worker.profile_url .. xuid
		get_image_url = _xbox_image_url
		resize_url = xbox_worker.resize_url
	end

	-- Darktide keeps PSN ids in decimal, only Steam and Xbox ids are converted to hex. An id that is still empty, or isn't the 1-20 digits the worker accepts, would only come back as an error, so it sends no request.
	if platform == "psn" then
		local psn_account_id = player_info:platform_user_id()

		if type(psn_account_id) == "string" and #psn_account_id <= 20 and string_match(psn_account_id, "^%d+$") then
			url = psn_worker.profile_url .. psn_account_id
			get_image_url = _psn_image_url
			resize_url = psn_worker.resize_url
		end
	end

	if not (url and get_image_url) then
		if allow_retry and player_info:account_id() then
			player_info
				:first_update_promise()
				:next(function()
					_load_profile_image(player_info, cb, false)
				end)
				:catch(function(_error)
					mod:info("Presence lookup failed, no profile image")
				end)

			return
		end

		mod:info("No profile image for platform '%s'", platform)

		return
	end

	-- Captured together, so the texture that lands under this key is always the one resized to this size
	local size = profile_picture_size
	local cache_key = url .. profile_picture_size_cache_suffix

	local entry = cache[cache_key]

	if entry then
		entry.requested = true

		cb(entry.texture)

		return
	end

	local pending = pending_requests[cache_key]

	-- Several panels ask for the same player at once, so join a request that is already running. A cancelled promise never runs its handlers, so check that this one is still alive rather than waiting on it forever.
	if pending and pending.promise and pending.promise:is_pending() then
		local callbacks = pending.callbacks

		callbacks[#callbacks + 1] = cb

		return
	end

	local request = {
		callbacks = {
			cb,
		},
	}

	pending_requests[cache_key] = request
	request.promise = Managers.backend
		:url_request(url)
		:next(function(profile_res)
			pending_requests[cache_key] = nil

			local image_url, fallback_image_url = get_image_url(profile_res)

			if not image_url then
				mod:info("No profile image in response from '%s'", url)

				return
			end

			-- The workers only resize pictures from the hosts the profile services hand out, so they get the url the profile actually returned rather than the rewritten Steam one
			local resized_image_url = _resize_url(resize_url, fallback_image_url or image_url, size)
			local proxy_url = _image_proxy_prefix()
			local image_urls

			-- With a proxy configured, try it first and fall back to loading directly. The resized picture is an https url as well, so it goes through the proxy too.
			if proxy_url then
				image_urls = {
					_proxied_url(proxy_url, resized_image_url),
					_proxied_url(proxy_url, image_url),
					image_url,
				}
			else
				image_urls = {
					resized_image_url,
					image_url,
					fallback_image_url,
				}
			end

			_load_texture(image_urls, 1, cache_key, request.callbacks)
		end)
		:catch(function(_error)
			pending_requests[cache_key] = nil

			mod:info("Failed to request profile from '%s'", url)
		end)
end

-- Called with whatever the surface holds, and the loader goes straight on to PlayerInfo methods, so anything that is not one has to stop here rather than error inside a hook
function mod.load_profile_image(player_info, cb)
	if not player_info or type(player_info.platform) ~= "function" then
		return
	end

	_load_profile_image(player_info, cb, true)
end

-- The portrait is a render target fed into the frame material's icon slot, so the picture goes into that same slot instead of being drawn over the panel. The equipped frame keeps rendering around it, and each panel's own tint, shadowing and fades still apply.
function mod.apply_profile_image(widget, style_id, texture)
	local style = widget and widget.style[style_id]

	if not style then
		return
	end

	local material_values = style.material_values

	material_values.use_placeholder_texture = 0
	material_values.rows = 1
	material_values.columns = 1
	material_values.grid_index = 0
	material_values.texture_icon = texture
	widget.dirty = true
end

-- Read on every portrait load, so keep the toggles out of the settings lookup path. Mutated in place, so the integrations can hold a local reference to it.
local location_enabled = {}

mod.location_enabled = location_enabled

local LOCATION_SETTING_IDS = {
	player_hud = "location_player_hud",
	social_menu = "location_social_menu",
	lobby = "location_lobby",
	end_screen = "location_end_screen",
	party_finder = "location_party_finder",
	inventory = "location_inventory",
}

local function _cache_location_settings()
	for location, setting_id in pairs(LOCATION_SETTING_IDS) do
		-- A setting that was never written stays enabled, so an update keeps the current behavior
		location_enabled[location] = mod:get(setting_id) ~= false
	end
end

_cache_location_settings()
_cache_profile_picture_size()
_cache_worker_urls()

-- A new size only reaches portraits as their views reload them, the same as the location toggles
mod.on_setting_changed = function()
	_cache_location_settings()
	_cache_profile_picture_size()
	_cache_worker_urls()
end

-- Constant elements outlive the game state, and the feed only counts a notification down while it is drawn, which it isn't on the loading screen. A portrait notification can so sit out a loading screen and draw its picture again afterwards.
local function _notification_textures()
	local textures = {}
	local ui_manager = Managers.ui
	local constant_elements = ui_manager and ui_manager:ui_constant_elements()
	local notification_feed = constant_elements and constant_elements:element("ConstantElementNotificationFeed")
	local notifications = notification_feed and notification_feed._notifications

	if not notifications then
		return textures
	end

	for i = 1, #notifications do
		local notification = notifications[i]
		local texture = notification and notification.profile_picture_texture

		if texture then
			textures[texture] = true
		end
	end

	return textures
end

-- Releasing the last reference destroys a texture there and then, even with a widget still drawing it. So a picture is only released once nothing asked for it through a whole game state, by when the views and panels of the state it was shown in are gone, including an end screen still fading out under the loading screen.
local function _release_unrequested_textures()
	local url_loader = Managers.url_loader

	if not url_loader then
		return
	end

	local notification_textures = _notification_textures()
	local num_released = 0
	local num_kept = 0

	for cache_key, entry in pairs(cache) do
		if entry.requested or notification_textures[entry.texture] then
			entry.requested = false
			num_kept = num_kept + 1
		else
			-- Dropped before the release, so neither a reload nor an error part way through can give the same reference back twice
			cache[cache_key] = nil

			url_loader:unload_texture(entry.image_url)

			num_released = num_released + 1
		end
	end

	mod:info("Released %d unused profile pictures, kept %d", num_released, num_kept)
end

-- Every trip between the hub and a mission goes through loading, and the pre-mission lobby only opens once it has started
mod.on_game_state_changed = function(status, state_name)
	if status == "enter" and state_name == "StateLoading" then
		_release_unrequested_textures()
	end
end

mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/PlayerPanel")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/NotificationFeed")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/SocialMenu")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/Lobby")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/EndScreen")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/GroupFinder")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/Inventory")
