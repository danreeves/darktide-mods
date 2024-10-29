local mod = get_mod("RagdollTogether")
local wsf = get_mod("wsf")

wsf:register(mod)

local function anim(player, event)
	local player_unit = player.player_unit
	local animation_extension = ScriptUnit.extension(player_unit, "animation_system")
	animation_extension:anim_event(event)
end

function mod:on_message(event, player)
	anim(player, event)
end

local ragdolling = false
function mod.ragdoll_toggle()
	ragdolling = not ragdolling

	local event = ragdolling and "ragdoll" or "reset"
	anim(Managers.player:local_player(1), event)
	mod:send_message(event)
end
