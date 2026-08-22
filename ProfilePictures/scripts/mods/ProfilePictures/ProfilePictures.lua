local mod = get_mod("ProfilePictures")

local cache = mod:persistent_table("cache")

-- Profile requests in flight, keyed by url. Deliberately not persistent: a reload leaves the promises behind.
local pending_requests = {}

local string_byte = string.byte
local string_find = string.find
local string_format = string.format
local string_gsub = string.gsub
local string_match = string.match
local string_sub = string.sub

local DEFAULT_PROXY_PATH = "/avatar?url="

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

local function _proxied_url(proxy_url, image_url)
	local encoded_url = string_gsub(image_url, "([^%w%-%_%.%~])", _encode_char)

	return proxy_url .. encoded_url
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

local function _load_texture(image_url, fallback_image_url, cache_key, callbacks)
	-- Public urls on third party CDNs, so don't attach the backend auth token
	Managers.url_loader
		:load_texture(image_url, false)
		:next(function(data)
			local texture = data.texture

			cache[cache_key] = texture

			for i = 1, #callbacks do
				callbacks[i](texture)
			end
		end)
		:catch(function(_error)
			if fallback_image_url then
				_load_texture(fallback_image_url, nil, cache_key, callbacks)

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

	local xuid, url, get_image_url

	if platform == "steam" then
		xuid = Application.hex64_to_dec(player_info:platform_user_id())
		url = "https://steam-profile-xml-to-json.dnrvs.workers.dev/" .. xuid
		get_image_url = _steam_image_url
	end

	if platform == "xbox" then
		xuid = Application.hex64_to_dec(player_info:platform_user_id())
		url = "https://xboxapi-workers.dnrvs.workers.dev/profiles/" .. xuid
		get_image_url = _xbox_image_url
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

	if cache[url] then
		cb(cache[url])
		return
	end

	local pending = pending_requests[url]

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

	pending_requests[url] = request
	request.promise = Managers.backend
		:url_request(url)
		:next(function(profile_res)
			pending_requests[url] = nil

			local image_url, fallback_image_url = get_image_url(profile_res)

			if not image_url then
				mod:info("No profile image in response from '%s'", url)

				return
			end

			local proxy_url = _image_proxy_prefix()

			-- With a proxy configured, try it first and fall back to loading directly
			if proxy_url then
				fallback_image_url = image_url
				image_url = _proxied_url(proxy_url, image_url)
			end

			_load_texture(image_url, fallback_image_url, url, request.callbacks)
		end)
		:catch(function(_error)
			pending_requests[url] = nil

			mod:info("Failed to request profile from '%s'", url)
		end)
end

function mod.load_profile_image(player_info, cb)
	if not player_info then
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

mod.on_setting_changed = _cache_location_settings

mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/PlayerPanel")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/NotificationFeed")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/SocialMenu")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/Lobby")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/EndScreen")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/GroupFinder")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/Inventory")
