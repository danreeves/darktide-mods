# PingMonitor: packet loss feasibility

Findings for [issue #316](https://github.com/danreeves/darktide-mods/issues/316): can a DMF Lua mod read a meaningful packet loss figure for the active game-server connection?

## Decision

**No-go for a live packet loss percentage.** In the inspected build the engine keeps a loss figure for each connection, but no way to read it from Lua was found. PingMonitor should not show a loss percentage.

This describes one build. It does not claim the engine has no such API: the engine clearly has the value, and only a Lua read path is missing.

**Evidence status:** the decision rests on static analysis of the game source and executable, one real engine log dump, and an in-game run of the [runtime probe](#runtime-probe) on 2026-11-02. The probe confirmed the `Network` list and found nothing that reads loss.

## Inspected versions

| Item | Version |
|---|---|
| Game source mirror | [Aussiemon/Darktide-Source-Code `e46b892`][mirror], "Added Version 1.13.4 10-22-26". A decompiled research aid, not official API documentation |
| Game executable | `binaries/Darktide.exe`, file date 2026-10-22, engine branch `2026_08_11_Patch1.13.x` (from paths embedded in the executable) |
| Client logs | 23 console logs from 2026-10-27 to 2026-10-31, all logging svn revision 139617 and `game_version = 1.13.0-b819406`. The build string reads 1.13.0, while the executable's date matches the mirror's 1.13.4 label |
| DMF | Installed Vortex package `Darktide Mod Framework-8-23-10-04-1696478703`, deployed 2026-10-23. No version constant was found, so the package name is the identifier |
| PingMonitor | This repository at `4254b5c` |

**Executable method.** Read-only static analysis, without running the game:

1. Extract the printable strings.
2. Scan `.text` for RIP-relative `lea` sequences of module name, function name and function pointer, which is how the engine registers Lua bindings. This found 1,941 functions in 123 modules, 39 of them in `Network`.
3. Use `.pdata` for function boundaries and `call`/`jmp` targets for direct callers.

The scan is pattern-based, so on its own it isn't proof that the list is complete. Lua also adds names to `Network` at runtime ([`network_init.lua`][network_init]). The in-game probe matched the scan's `Network` list exactly.

## What the engine tracks

The retail engine can write this block to the console log. This is the only one found in the 23 logs, with the peer id redacted:

```text
[Connection] Pong timeout for <peer> last pong: 10.008212, last receive: 9.254269, last transmit: 0.016672
[Connection] Endpoint stats for peer_id: <peer>
Ping: 29.9738 ms
Loss: 100 %
Time since last transmit: 0.0166716 seconds
Time since last receive: 9.25427 seconds
Time since last pong: 10.0082 seconds
Time since last resend: 0.0833579 seconds
Send: 101.925 kbit/s  (average last 10 sec)
Receive: 8.97338 kbit/s (average last 10 sec)
Resend: 0.23021 kbit/s (average last 10 sec)
Unacked messages: 466
Bidirectional comparison:
Send: 143.936 kbit/s (recent)
Remote Receive: 38.72 kbit/s (inaccurate)
```

| Property | What is known |
|---|---|
| Connection scope | One remote peer, per the block's header. The host changes between hub and mission: the same log joins hub, mission, hub and mission hosts on channels 91, 95, 101 and 105 |
| Units | Percent, as printed |
| Direction | **Unknown** |
| Datagrams or reliable retransmissions | **Unknown.** The block lists `Resend` and `Unacked messages` separately, which doesn't settle it |
| Denominator and window | **Unknown.** It read 100% about 39 minutes into the mission, after 9.25 s without receiving. A lifetime ratio couldn't reach 100% that late, so it looks like a recent window, but that is an inference from one sample |
| Reset on reconnect | **Unknown** |
| When it is written | The dump follows the only `Pong timeout` in the logs, and the other 120 `[Handshaker] Lost connection` lines have none. None of the dump function's 21 direct-call ancestors (10 callers, 11 callers of those) is a Lua binding. Those holding identifiable strings come from Endpoint send, receive and connection-failure code. The chain ends at virtual dispatch, which the trace does not follow |
| Lua access | **None found** |

The executable also holds a congestion-control path with the strings `Detected congestion for peer`, `loss signal` and `loss smoothed`. None of them appears in the 23 logs. [`GameParameters.qos_config`][qos_param] defaults to `""`, so [`ConnectionManager`][qos_call] doesn't call `Network.set_qos_config` by default, and whether this path is active in retail is not established.

## Lua surface

The 39 `Network` functions found in the executable, all present in game:

```text
account_id, channel_state, config_hash, create_game_session, default_network_address,
fatal_error, game_session, init_table_cache, init_wan_client, join_lan_lobby,
leave_lan_lobby, limit_mtu, message_info, object_has_field, object_info, pack_unpack,
peer_id, ping, reliable_send_buffer_capacity, reliable_send_buffer_left, set_log_level,
set_max_transmit_rate, set_ping_resend_time, set_ping_send_time, set_pong_timeout,
set_qos_config, set_qos_enable, set_resend_time, set_upload_limit, shutdown_game_session,
shutdown_lan_client, shutdown_table_cache, time_since_receive, type_index, type_info,
update, update_receive, update_transmit, write_dump_tag
```

Across all registered names, searching for `loss`, `packet`, `resend`, `retrans`, `bandwidth`, `congest`, `endpoint`, `net_stat`, `quality`, `kbit`, `kbps`, `rtt`, `unacked` and `throughput` finds only `Network.set_resend_time` and `Network.set_ping_resend_time`. Both are setters by name.

| API | Scope and units | Verdict |
|---|---|---|
| `Network.ping(peer_id)` | Per peer, seconds. [`PingReporter`][ping_reporter] multiplies it by 1000 and [`AdaptiveClockHandlerClient`][adaptive_clock] treats it as round-trip time | Latency, not loss |
| `Network.time_since_receive` | Registered, but nothing in the mirror calls it. Signature unverified | A time gap by its name, not a rate |
| `Network.reliable_send_buffer_left(peer_id)` | Per peer. Used by [`RPCQueue`][rpc_queue] for backpressure. `reliable_send_buffer_capacity` has no caller in the mirror | Also moves with send volume, and has no packet denominator |
| `Network.channel_state(channel_id)` | Per channel. Returns state and reason, as in [`RemoteInSessionState`][channel_state] | No counters |
| `Network.set_log_level`, `write_dump_tag`, `limit_mtu`, `set_upload_limit`, `set_qos_config`, `set_qos_enable`, `set_resend_time`, `set_ping_resend_time`, `set_ping_send_time`, `set_pong_timeout`, `set_max_transmit_rate` | Setters and writers by name | Nothing to read |
| `GameSession.*` (29 functions) | Game objects and session membership | No transport statistics |
| `Ping.ping(timeout, targets...)` | [`PingManager`][ping_manager]'s own probe to listed targets | Not the game connection, and the issue rules out a second probe |
| `Steam.*`, `Stats.*`, `Profiler.lua_stats` | Account and overlay, Steam achievement stats, Lua profiling | Unrelated |
| `Application.console_command("perfhud", "network…")` | Called only by [dev parameters][perfhud] | `console_command`, `network_peers`, `network_ping` and `network_messages` don't appear in the executable's strings, and `perfhud` appears only inside `set_perfhud_pie_update_interval` |
| [`PingReporter`][ping_reporter] | One-second sampling of `Network.ping` for telemetry | Latency only. It skips samples when the client has no host, so gaps don't mean loss |

DMF's Lua never uses `Network`. In the Lua of the mods in the local Vortex staging folder, nothing calls `Network.ping`, `time_since_receive`, `set_log_level` or `reliable_send_*`, or mentions packet loss.

## Simulation controls are not telemetry

[`params.packet_loss` and `params.packet_duplication`][simulation] are dev parameters that call `Managers.state.game_session:set_simulated_packet_loss` and `set_simulated_packet_duplication`. They configure a test input and measure nothing.

In this build, no Lua file in the mirror defines those methods, and the executable has no matching network-simulation string. No monitor proposed here enables them.

## Rejected workarounds

| Route | Why not |
|---|---|
| Read the console log through `Mods.lua.io` | The block appeared once, at a connection failure, where it read 100%. It can't drive a live reading |
| Raise `Network.set_log_level` or `--network-log-level`, then read the log | Changes engine logging for everything, and which level prints what is unverified. The loss lines never appear at the default level, and the path that prints them may not be active |
| Read engine memory through `Mods.lua.ffi` | Depends on build-specific offsets with no stable contract, and a wrong read crashes the game |
| Windows network counters through `Mods.lua.ffi` | System-wide, not scoped to the game connection |
| A second network probe | Measures other traffic, and the issue rules it out |
| Infer loss from ping, jitter, missing `PingReporter` samples or disconnect counts | None of these measures loss, and the issue rules them out |

## Research questions

| # | Question | Answer |
|---|---|---|
| 1 | Counters or rates available in the retail client | One internal loss figure, written to the log only. No Lua API was found in the build above |
| 2 | What a candidate measures | Direction, denominator, window and reset behaviour of the internal figure are all unknown. No Lua candidate exists to characterise |
| 3 | Runtime read access | Nothing to read. The [probe](#runtime-probe) ran in a mission without errors and found no name that reads loss. It calls no binding, so unsupported APIs and missing connections can't raise errors |
| 4 | Percentage from counters | No counters or denominator are available to Lua, so no percentage can be computed. The checks a future candidate must pass are under [reopening conditions](#reopening-conditions) |
| 5 | Go or no-go | No-go, limited to this build |

## Acceptance criteria

| Criterion | Status |
|---|---|
| Findings name versions, revision, explored APIs and a conclusion | Met, see above |
| Any viable metric is documented and backed by a runtime experiment | No viable metric. Properties of the internal figure are recorded, with the unknowns marked. The in-game probe confirmed there is no Lua read path |
| Missing data, startup, reconnects and resets are covered, and a missing measurement never renders as verified zero | PingMonitor renders no loss value, so absent data can't appear as 0%. Its existing `mod.ping` stays `nil` until a valid sample and resets on game state change, which is the pattern any future value must follow |
| Simulation controls are distinguished from telemetry | Met, see above |
| Bounded plan if feasible | Not applicable. See [reopening conditions](#reopening-conditions) |
| If infeasible, the issue can close without a misleading percentage or delaying other fixes | Met. No mod code changed |

## Runtime probe

This confirms the Lua surface in the real client. It is not shipped in the mod.

1. Append the snippet to `PingMonitor.lua`.
2. Run `/pm_net_probe` in chat once during a mission.
3. Remove the snippet.
4. Read the `[MOD][PingMonitor][INFO]` lines in `%APPDATA%\Fatshark\Darktide\console_logs\`. DMF's default logging mode writes `mod:info` there.

```lua
-- Only reads names and types. It calls no binding, because a C binding can crash the game
-- on a bad call instead of raising a Lua error, which pcall can't catch
local PROBE_TERMS = {
	"loss",
	"packet",
	"resend",
	"retrans",
	"bandwidth",
	"congest",
	"endpoint",
	"stats",
	"quality",
	"kbit",
	"kbps",
	"rtt",
	"unacked",
}

mod:command("pm_net_probe", "List network bindings for the packet loss research", function()
	local names = {}

	for name, value in pairs(Network) do
		names[#names + 1] = string.format("%s:%s", tostring(name), type(value))
	end

	table.sort(names)
	mod:info("Network (%d): %s", #names, table.concat(names, " "))

	local num_candidates = 0

	for module_name, module in pairs(_G) do
		if type(module) == "table" then
			for name, value in pairs(module) do
				if type(name) == "string" then
					local lower_name = string.lower(name)

					for i = 1, #PROBE_TERMS do
						if string.find(lower_name, PROBE_TERMS[i], 1, true) then
							num_candidates = num_candidates + 1
							mod:info("candidate %s.%s:%s", tostring(module_name), name, type(value))

							break
						end
					end
				end
			end
		end
	end

	mod:echo("Probe done, %d candidates. See the console log.", num_candidates)
end)
```

The crash warning comes from the installed SoloSandbox mod, which documents it for `Network.peer_id()` without a network session.

**Result, 2026-11-02.** Run once in a mission on the build above, with no errors afterwards:

- `Network` holds 43 keys: exactly the 39 functions from the static scan, the Lua-added `is_active`, and the non-function keys `_is_active`, `_name` and `__index`.
- The name scan matched 180 names. The only network-related ones are:
  - the setters `Network.set_resend_time` and `Network.set_ping_resend_time`;
  - the RPC handler `LocalRequestMissionSeedState.rpc_resend_mission_seed_request`;
  - `ConnectionManager.accelerated_endpoint`, `ConnectionClient.accelerated_endpoint` and `DefaultGameParameters.wan_disable_accelerated_endpoint`, which choose the [server address][accelerated] to connect through.

  None of these returns a loss value.
- The other matches are noise: gameplay and UI `stats`, graphics `quality`, dialogue ids containing `loss`, and `rtt` inside names such as `SmartTag`.

If a later run finds a function that could return a network loss value, the decision is revisited.

## Reopening conditions

A Lua binding that exposes endpoint statistics would reopen this, so re-run the probe after engine updates. Before any display work, a candidate must have documented connection scope, units, direction, denominator and window, and must pass these checks in a controlled session:

- Zero traffic gives "unavailable", not 0%.
- Startup and missing connections give "unavailable", without errors.
- Reconnects and hub or mission host changes reset the value.
- Counter resets and rollover produce no false spikes.
- Polling stays bounded, at about the existing one-second sample rate, with no second network probe.

A different feature would need its own name and issue, for example a "no data from server" stall indicator built on `Network.time_since_receive`. It would not be a packet loss measurement.

[mirror]: https://github.com/Aussiemon/Darktide-Source-Code/tree/e46b8926cfa3fa35503e4b80b15aab7a804314e4
[network_init]: https://github.com/Aussiemon/Darktide-Source-Code/blob/e46b8926cfa3fa35503e4b80b15aab7a804314e4/scripts/foundation/patches/network_init.lua#L3-L8
[qos_param]: https://github.com/Aussiemon/Darktide-Source-Code/blob/e46b8926cfa3fa35503e4b80b15aab7a804314e4/scripts/foundation/utilities/parameters/default_game_parameters.lua#L24
[qos_call]: https://github.com/Aussiemon/Darktide-Source-Code/blob/e46b8926cfa3fa35503e4b80b15aab7a804314e4/scripts/managers/multiplayer/connection_manager.lua#L791-L797
[ping_reporter]: https://github.com/Aussiemon/Darktide-Source-Code/blob/e46b8926cfa3fa35503e4b80b15aab7a804314e4/scripts/managers/telemetry/reporters/ping_reporter.lua#L26-L43
[adaptive_clock]: https://github.com/Aussiemon/Darktide-Source-Code/blob/e46b8926cfa3fa35503e4b80b15aab7a804314e4/scripts/managers/player/player_game_states/utilities/adaptive_clock_handler_client.lua#L87-L88
[rpc_queue]: https://github.com/Aussiemon/Darktide-Source-Code/blob/e46b8926cfa3fa35503e4b80b15aab7a804314e4/scripts/utilities/rpc_queue.lua#L40-L47
[channel_state]: https://github.com/Aussiemon/Darktide-Source-Code/blob/e46b8926cfa3fa35503e4b80b15aab7a804314e4/scripts/multiplayer/session/remote_states/remote_in_session_state.lua#L24
[ping_manager]: https://github.com/Aussiemon/Darktide-Source-Code/blob/e46b8926cfa3fa35503e4b80b15aab7a804314e4/scripts/managers/ping/ping_manager.lua#L10-L22
[perfhud]: https://github.com/Aussiemon/Darktide-Source-Code/blob/e46b8926cfa3fa35503e4b80b15aab7a804314e4/scripts/foundation/utilities/parameters/default_dev_parameters.lua#L3728-L3769
[simulation]: https://github.com/Aussiemon/Darktide-Source-Code/blob/e46b8926cfa3fa35503e4b80b15aab7a804314e4/scripts/foundation/utilities/parameters/default_dev_parameters.lua#L4893-L4912
[accelerated]: https://github.com/Aussiemon/Darktide-Source-Code/blob/e46b8926cfa3fa35503e4b80b15aab7a804314e4/scripts/multiplayer/party_immaterium_mission_session_boot.lua#L112-L117
