local mod = get_mod("ProfilePictures")

local cache = mod:persistent_table("cache")

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

local function _load_texture(image_url, fallback_image_url, cache_key, cb)
	-- Public urls on third party CDNs, so don't attach the backend auth token
	Managers.url_loader
		:load_texture(image_url, false)
		:next(function(data)
			local texture = data.texture

			cache[cache_key] = texture
			cb(texture)
		end)
		:catch(function(_error)
			if fallback_image_url then
				_load_texture(fallback_image_url, nil, cache_key, cb)

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

function mod.load_profile_image(player_info, cb)
	if not player_info then
		return
	end

	local platform = player_info:platform()

	local xuid, url, get_image_url

	if platform == "steam" then
		xuid = Application.hex64_to_dec(player_info:platform_user_id())
		url = "https://steam-profile-xml-to-json.dnrvs.workers.dev/" .. xuid
		get_image_url = function(response)
			local body = response and response.body
			local profile = body and body.profile
			local avatar_url = profile and profile.avatarFull

			if type(avatar_url) ~= "string" or avatar_url == "" then
				return nil
			end

			return _steam_avatar_urls(avatar_url)
		end
	end

	if platform == "xbox" then
		xuid = Application.hex64_to_dec(player_info:platform_user_id())
		url = "https://xboxapi-workers.dnrvs.workers.dev/profiles/" .. xuid
		get_image_url = function(response)
			local body = response and response.body
			local gamerpic = body and body.gamerpic

			if type(gamerpic) ~= "string" or gamerpic == "" then
				return nil
			end

			return gamerpic
		end
	end

	if cache[url] then
		cb(cache[url])
		return
	end

	if url and get_image_url then
		Managers.backend
			:url_request(url)
			:next(function(profile_res)
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

				_load_texture(image_url, fallback_image_url, url, cb)
			end)
			:catch(function(_error)
				mod:info("Failed to request profile from '%s'", url)
			end)
	end
end

mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/PlayerPanel")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/SocialMenu")
-- mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/Lobby") -- Doesn't work
