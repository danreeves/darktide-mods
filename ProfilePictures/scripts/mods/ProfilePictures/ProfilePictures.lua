local mod = get_mod("ProfilePictures")

local cache = mod:persistent_table("cache")

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
		xuid = Steam.id_hex_to_dec(player_info:platform_user_id())
		url = "https://steam-profile-json.deno.dev/" .. xuid
		get_image_url = function(response)
			return response.body.profile.avatarFull
		end
	end

	if platform == "xbox" then
		xuid = Steam.id_hex_to_dec(player_info:platform_user_id())
		url = "https://xboxapi.mrmicky.workers.dev/profiles/" .. xuid
		get_image_url = function(response)
			return response.body.gamerpic
		end
	end

	if cache[url] then
		cb(cache[url])
		return
	end

	if url and get_image_url then
		Managers.backend:url_request(url):next(function(profile_res)
			Managers.url_loader
				:load_texture(get_image_url(profile_res))
				:next(function(data)
					cache[url] = data.texture
					cb(data.texture)
				end)
				:catch(function(error)
					mod:echo(cjson.encode(error))
				end)
		end)
	end
end

mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/PlayerPanel")
mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/SocialMenu")
-- mod:io_dofile("ProfilePictures/scripts/mods/ProfilePictures/Lobby") -- Doesn't work
