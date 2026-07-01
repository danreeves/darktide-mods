## Healthbars

**Healthbars** brings Psykhanium-style enemy healthbars into regular missions and expands them with optional combat readouts. The mod can show enemy health bars, floating damage numbers, a DPS readout, a configurable info label, and a set of DoT and debuff indicators above the bar.

### What it includes
- **Enemy healthbars** for selected enemy types in regular game modes
- **Damage numbers** when tracked enemies take damage
- **DPS report** for tracked targets after the damage window ends
- **Configurable post-kill display duration** for the healthbar, info label, and DPS report
- **Info label** above the bar
  - **Armour type**
  - **Enemy name**
- **Localized enemy names** using the game's normal display names
- **Safe localization fallback** that avoids showing internal ids or `<unlocalized ...>` text
- **DoT indicators**
  - **Bleed** stacks or icon-only display
  - **Chordclaw Bleed** stacks or remaining time
  - **Burn** stacks or icon-only display
  - **Phosphor Burn** icon or remaining time
  - **Warpfire / Soulblaze** stacks
  - **Toxin** stacks or icon-only display
- **Debuff indicators**
  - **Brittleness indicator** (combined enemy-side rending, shown as equivalent stacks, total %, time, or icon-only)
  - **Electrocuted** (presence indicator covering the complete electrocution keyword group)
  - **Weapon Malfunction** (breed-gated presence indicator)
  - **Skullcrusher** (damage vs staggered, stacks / % / time)
  - **Thunderstrike** (impact modifier, stacks / % / time)
  - **Melee damage taken** (from multiple sources, icon-only or %)
  - **Increased total damage taken** (combined from several buffs, including the Skitarii Servo-Skull debuff, icon-only or %)
  - **Empyric Shock** (warp damage taken, stacks / % / time)
- **Optional DoT/debuff indicators on vanilla boss health bars**, using the same status settings as the Healthbars marker

---

## Configuration

Open the Healthbars page in the mod options.

The standard DMF page organizes settings into groups for general features, damage numbers, DoT/debuff indicators, and enemy selection.

If **Alf's DMF Mod Settings Extensions** is installed, the same settings are presented in localized tabs:
- **General** - general feature toggles and damage-number settings
- **DoT & Debuffs** - status indicators, display modes, text sizing, and Warpfire color
- **Enemies** - per-enemy healthbar toggles

The extension is optional. Healthbars retains the same settings and functionality with standard DMF.

### Toggles (on/off)
- Show health bar
- Show DoT/debuff markers on vanilla boss health bars
- Show damage numbers
- Show DPS report
- Show info label
- Show Bleed
- Show Chordclaw Bleed
- Show Burn
- Show Phosphor Burn
- Show warpfire (Soulblaze) stacks
- Show Toxin
- Show brittleness indicator
- Show electrocution debuff
- Show Weapon Malfunction debuff
- Show Skullcrusher debuff
- Show Thunderstrike debuff
- Show Melee damage taken debuff
- Show Increased damage taken debuff
- Show Empyric Shock debuff

### Enemy selection
Healthbars can be enabled or disabled per enemy within these groups:
- **Horde/Roamer**
- **Elite**
- **Special**
- **Monster/Captain**
- **Ritualist**

This lets you keep the display focused on the enemies that matter most to you.

### Color selection
- **Warpfire**: `Warp-Core` / `Soulblaze Cyan` / `Sanctified Cerulean` (default) / `Ethereal Blue` / `Peril Purple`

### Display duration
- **Post-kill display duration**: controls how long the healthbar, info label, and DPS report remain visible after an enemy dies. Range: `0.2-10` seconds, default: `1`, adjustable in `0.2` second steps.
- This duration only applies while the enemy unit still exists in the world. Healthbars are anchored to the enemy unit's head node, so when the game removes the body, the marker loses its world anchor and cannot continue rendering in the current implementation.

### Readability options
- **DOT stack number size**: adjusts the font size for Bleed, Chordclaw Bleed, Burn, Phosphor Burn, Warpfire / Soulblaze, and Toxin status text. Range: `10-24`, default: `14`.
- **Debuff stack/time text size**: adjusts the font size for debuff `Stacks` and `Time (s)` display modes. Range: `10-24`, default: `14`.
- **DOT numbers only**: hides eligible DOT icons and shows only their number, tinted with the DOT effect color. Effects explicitly configured as `Icon only`, and Phosphor Burn, retain their icon.

### Vanilla boss health bar indicators

When enabled, Healthbars can also draw the configured DoT and debuff indicators on the game's normal boss health bars.

This is independent from **Show health bar**, so players can disable the custom overhead boss healthbar while still seeing boss DoTs and debuffs on the vanilla boss UI.

The vanilla boss indicators reuse the existing status settings:
- Per-effect toggles
- Display modes such as stacks, percent, time, icon-only, and icon + text
- DOT stack number size
- Debuff stack/time text size
- DOT numbers only
- Warpfire color

### Display modes (per effect)
Some effects have a display dropdown:
- **Info label**: `Armour type` / `Enemy name`
- **Bleed**: `Stacks` / `Icon only`
- **Chordclaw Bleed**: `Stacks` / `Time (s)`
- **Burn**: `Stacks` / `Icon only`
- **Phosphor Burn**: `Icon only` / `Time (s)` (defaults to `Icon only`)
- **Toxin**: `Stacks` / `Icon only`
- **Brittleness**: `Stacks` / `Icon + text %` / `Icon only` / `Time (s)`
- **Skullcrusher**: `Stacks` / `Percent %` / `Icon only` / `Time (s)`
- **Thunderstrike**: `Stacks` / `Percent %` / `Icon only` / `Time (s)`
- **Melee damage taken**: `Icon + text %` / `Icon only`
- **Increased damage taken**: `Icon + text %` / `Icon only`
- **Empyric Shock**: `Stacks` / `Percent %` / `Time (s)`

With **Alf's DMF Mod Settings Extensions**, the Warpfire color and DoT/debuff display dropdowns include matching colored status icons. Dynamic-color debuffs use their base active color in the dropdown. These icons are a settings-menu enhancement only and do not change indicator behavior.

### Text placement behavior
- `Percent` and `Icon + text %` modes render the text **centered and smaller** inside the icon.
- `Stacks` and `Time (s)` render a **bigger number** in the **bottom-right** of the icon.
- DOT stack numbers use the configured **DOT stack number size**.
- Debuff `Stacks` and `Time (s)` modes use the configured **Debuff stack/time text size**.
- When **DOT numbers only** is enabled, DOT icons are hidden and the stack number is centered using the DOT effect color.
- If the game reports active stacks but no reliable duration progress, the icon remains visible and the **time text is hidden** instead of showing a misleading `0`.

---

## Layout rules: overhead Healthbars marker

- Indicators are displayed in an **8-column grid** with up to **2 rows**.
- If any debuff is active:
  - **Debuffs** occupy the first visual row.
  - **DoTs** shift into the second visual row.
- If no debuff is active:
  - **DoTs** occupy the first visual row.

## Layout rules: vanilla boss health bar indicators

- Indicators are displayed above the vanilla boss health bar.
- DoTs use the upper row when any tracked debuff is active.
- Debuffs use the lower row.
- If no tracked debuff is active, DoTs move to the lower row so they sit closer to the boss health bar.
- The game normally renders up to two vanilla boss health bars. Additional tracked enemies can still use the regular head-anchored Healthbars marker when enabled.

### Ordering
- DoTs: `Bleed` -> `Chordclaw Bleed` -> `Burn` -> `Phosphor Burn` -> `Warpfire` -> `Toxin`
- Debuffs: `Brittleness` -> `Damage Taken` -> `Melee Damage Taken` -> `Skullcrusher` -> `Thunderstrike` -> `Empyric Shock` -> `Electrocuted` -> `Weapon Malfunction`

---

## Status reference table (icons + color/state progression)

> **New icon placeholders:** `icons/chordclaw_bleed.png`, `icons/phosphor_burn.png`, and `icons/weapon_malfunction.png` are intentionally referenced before the image files exist. Add the finished images at those paths later.

| Status | Icon | What it detects / measures | Text display options | Color/state progression |
|---|---:|---|---|---|
| **Bleed** | <img src="icons/bleed.png" width="50"> | Regular DoT stacks from `bleed` | `Stacks` / `Icon only` | Fixed color, blood red tint. |
| **Chordclaw Bleed** | <img src="icons/chordclaw_bleed.png" width="50" alt="Chordclaw Bleed icon placeholder"> | Skitarii Chordclaw `bleed_long`: **9.5s** duration, **18** maximum stacks | `Stacks` / `Time (s)` | Fixed color, blood red tint. Tracked separately from regular Bleed. |
| **Burn** | <img src="icons/burn.png" width="50"> | Regular burn stacks from `flamer_assault`, including compatible companion-applied burn | `Stacks` / `Icon only` | Fixed color, orange flame tint. |
| **Phosphor Burn** | <img src="icons/phosphor_burn.png" width="50" alt="Phosphor Burn icon placeholder"> | Phosphor Blast Pistol `phosphor_burn`: **20s** duration, maximum **1** stack | `Icon only` / `Time (s)` | Fixed Phosphor-orange tint. Tracked separately from regular Burn and defaults to icon-only. |
| **Warpfire (Soulblaze)** | <img src="icons/warpfire_color_option_three.png" width="50"> | DoT stacks from `warp_fire` | Stacks | <img src="icons/warpfire_color_option_one.png" width="25"> **Warp-Core**<br/><img src="icons/warpfire_color_option_two.png" width="25"> **Soulblaze Cyan**<br/><img src="icons/warpfire_color_option_three.png" width="25"> **Sanctified Cerulean** (default)<br/><img src="icons/warpfire_color_option_four.png" width="25"> **Ethereal Blue**<br/><img src="icons/warpfire_color_option_five.png" width="25"> **Peril Purple** |
| **Toxin** | <img src="icons/toxin.png" width="50"> | Combined DoT stacks from the tracked neurotoxin and exploding toxin interval buffs | `Stacks` / `Icon only` | Fixed color, toxic green tint. |
| **Brittleness** | <img src="icons/brittleness_white.png" width="50"> | Combined enemy-side rending from `rending_debuff`, `rending_debuff_medium`, `rending_burn_debuff`, `phosphor_rending_debuff`, `shotgun_special_rending_debuff`, `saw_rending_debuff`, and the supported Horde grenade rending effect. Percentage is converted to equivalent **2.5% stacks**, with caps of **40 stacks** and **100%** total. **Only shown for armor types:** Flak, Carapace, Maniac, Unyielding. | `Stacks` / `Icon + %` / `Icon only` / `Time (s)` | <img src="icons/brittleness_white.png" width="25"> **Below 20%**<br/><img src="icons/brittleness_yellow.png" width="25"> **20-29.9%**<br/><img src="icons/brittleness_orange.png" width="25"> **30-39.9%**<br/><img src="icons/brittleness_red.png" width="25"> **40-59.9%**<br/><img src="icons/brittleness_magenta.png" width="25"> **>=60%** |
| **Electrocuted** | <img src="icons/electrocuted.png" width="50"> | Presence of any keyword in Darktide's electrocution group, including regular electrocution, chain lightning, Arc, Arc Ability, Arc Grenade, and Shock Mine variants | No text | Fixed color, pale electrocuted tint. Presence-only because some arc buffs mark targeting state rather than a ticking DoT. |
| **Weapon Malfunction** | <img src="icons/weapon_malfunction.png" width="50" alt="Weapon Malfunction icon placeholder"> | Presence of the `weapon_malfunction` keyword on an enemy breed whose behavior is actually affected: supported shotgunners, stalkers, flamers, gunners, Reaper, Scab Shooter, Radio Operator, Sniper, and Trapper variants | No text | Fixed pale yellow-green tint. Breed-gated to avoid displaying a behavior debuff on enemies where it has no effect. |
| **Skullcrusher** | <img src="icons/skullcrusher_white.png" width="50"> | Stagger damage taken debuff: `increase_damage_received_while_staggered` with fallback `damage_vs_staggered`. **10% per stack**, cap **8**. | `Stacks` / `Percent %` / `Icon only` / `Time (s)` | <img src="icons/skullcrusher_white.png" width="25"> **1-2** / 10-20%<br/><img src="icons/skullcrusher_yellow.png" width="25"> **3-4** / 30-40%<br/><img src="icons/skullcrusher_orange.png" width="25"> **5-6** / 50-60%<br/><img src="icons/skullcrusher_red.png" width="25"> **7-8** / 70-80% |
| **Thunderstrike** | <img src="icons/thunderstrike_white.png" width="50"> | Impact modifier debuff: `increase_impact_received_while_staggered` with fallback `impact_modifier`. **10% per stack**, cap **8**. | `Stacks` / `Percent %` / `Icon only` / `Time (s)` | <img src="icons/thunderstrike_white.png" width="25"> **1-2** / 10-20%<br/><img src="icons/thunderstrike_yellow.png" width="25"> **3-4** / 30-40%<br/><img src="icons/thunderstrike_orange.png" width="25"> **5-6** / 50-60%<br/><img src="icons/thunderstrike_red.png" width="25"> **7-8** / 70-80% |
| **Melee damage taken** | <img src="icons/melee_damage_taken_white.png" width="50"> | Counts active sources: `ogryn_staggering_damage_taken_increase` and `adamant_staggering_enemies_take_more_damage`. Each source adds **+15%** additively. | `Icon + %` / `Icon only` | <img src="icons/melee_damage_taken_white.png" width="25"> **1 source (15%)**<br/><img src="icons/melee_damage_taken_red.png" width="25"> **2 sources (30%)** |
| **Increased damage taken (total)** | <img src="icons/damage_taken_white.png" width="50"> | Computes the combined increase from all supported sources:<br/><br/>**Additive modifiers:**<br/>`ogryn_recieve_damage_taken_increase_debuff` - Soften Them Up, **+10%**<br/>`increase_damage_taken` - Pickaxe weapon special, **+10% per stack**, cap **8**<br/>`broker_passive_toxin_infected_enemies_take_increased_damage_debuff` - Virulent Strain, **+10%**<br/>`hordes_buff_broker_flash_grenade_increase_damage_taken_effect` - Blinding Weakness, **+200% per stack**, cap **6**<br/>`cryptic_servo_skull_debuff` - Servo-Skull attack, **+15%**<br/><br/>**Multipliers:**<br/>`ogryn_taunt_increased_damage_taken_buff` - Valuable Distraction, **+20%**<br/>`adamant_drone_enemy_debuff` - Nuncio-Aquila, **+15%**<br/>`psyker_discharge_damage_debuff` - Warp Rupture, **+10%**<br/>`zealot_bled_enemies_take_more_damage_effect` - Blinded by Blood, **+15%**<br/>`cryptic_overload_keystone_increase_damage_taken_debuff` - Critical Power Overload, **+15%**<br/><br/>**Stacked multiplier:**<br/>`veteran_improved_tag_debuff` - Focus Target, **+5% per stack**, cap **6**<br/><br/>**Enfeeble, +10% while active:**<br/>`psyker_protectorate_spread_chain_lightning_interval_improved`<br/>`psyker_protectorate_spread_charged_chain_lightning_interval_improved`<br/>`psyker_heavy_swings_shock_improved` | `Icon + %` / `Icon only` | <img src="icons/damage_taken_white.png" width="25"> **0-14.9%**<br/><img src="icons/damage_taken_yellow.png" width="25"> **15-29.9%**<br/><img src="icons/damage_taken_orange.png" width="25"> **30-44.9%**<br/><img src="icons/damage_taken_red.png" width="25"> **45-59.9%**<br/><img src="icons/damage_taken_magenta.png" width="25"> **>=60%** |
| **Empyric Shock** | <img src="icons/empyric_shock_white.png" width="50"> | Psyker debuff `psyker_force_staff_quick_attack_debuff`: **+6% warp damage taken per stack**, cap **5**, combined multiplicatively | `Stacks` / `Percent %` / `Time (s)` | <img src="icons/empyric_shock_white.png" width="25"> **1-2** / 6-12%<br/><img src="icons/empyric_shock_yellow.png" width="25"> **3** / 19%<br/><img src="icons/empyric_shock_orange.png" width="25"> **4** / 26%<br/><img src="icons/empyric_shock_red.png" width="25"> **5** / 34% |

---

## Notes / Implementation details
- Healthbars are anchored natively to the enemy **head node** instead of relying on custom world-position logic, which helps prevent the occasional bar-at-the-feet issue.
- Debuff changes trigger the same visibility window as damage, so indicators can appear when a debuff is applied even if the enemy has not taken direct damage yet.
- Debuff-only visibility also supports the **info label**, so armour type or enemy name can appear when a debuff is applied without direct damage.
- The **Post-kill display duration** extends the marker lifetime after damage has started, but it intentionally does not detach healthbars from enemy units. The current implementation relies on Fatshark's world marker anchoring to the enemy unit and its head node; once the game despawns that unit/body, there is no valid source transform for the healthbar to follow. Keeping a marker alive past that point would require a different fallback marker system, so Healthbars lets the marker disappear with the body instead of inventing a disconnected position.
- The mod supports **per-enemy healthbar toggles**, grouped by Horde/Roamer, Elite, Special, Monster/Captain, and Ritualist.
- **Damage numbers**, **DPS**, and the **info label** are handled independently, so the label can still work when damage numbers are disabled.
- **Enemy name** mode uses the game's localized `breed.display_name`.
- If localization data is missing or broken, the mod hides the label instead of showing internal names or `<unlocalized ...>` placeholders.
- **Armour type** uses the exact last hit zone when that data is available.
- In regular missions, the game does not always provide exact hit-zone data for networked enemies on the client, so armour type may fall back to the enemy's default/body armour instead of a more specific head or limb result.
- **Brittleness** combines separately stacking rending debuffs into one indicator so the player does not have to add multiple percentages mentally. Stack display uses one equivalent stack per **2.5%** rending.
- **Brittleness** is intentionally suppressed on armor types where it is not meaningful.
- **Chordclaw Bleed** and **Phosphor Burn** are independent from their regular Bleed and Burn indicators.
- **Electrocuted** uses Darktide's full electrocution keyword group and is **presence-only**.
- **Weapon Malfunction** is **presence-only** and restricted to enemy breeds whose behavior can be changed by the debuff.
- Companion-applied effects are read from the target's active buffs, so Servo-Skull burn and damage-taken debuffs do not require a normal player weapon source.
- **Warpfire** uses a player-selectable icon tint, with **Sanctified Cerulean** as the default option.
- **Increased damage taken (total)** is a **combined value**, so it can jump between color tiers quickly depending on team debuffs.
- Vanilla Psykhanium damage indicators are suppressed only in the **Psykhanium**, which avoids duplicate bars there while keeping regular mission behavior intact.

## Known issues
- **Brittleness `Time (s)`** depends on the game exposing reliable duration progress for the active rending buff. On some enemies or situations the icon may remain visible while the timer text is blank.
- **Armour type** in normal missions may reflect the enemy's default/body armour when exact hit-zone data is unavailable on the client.
- Percentage text can still be hard to read depending on icon color and background contrast.
- Very dense fights can produce a lot of simultaneous information if many status toggles are enabled at once.

## Recent additions
- Added Darktide 1.12 Skitarii/Cryptic support for **Chordclaw Bleed**, **Phosphor Burn**, grouped **Electrocution**, **Servo-Skull damage taken**, and **Weapon Malfunction**.
- Added independent settings and display modes for **Chordclaw Bleed** and **Phosphor Burn**.
- Added `Stacks` / `Icon only` display choices for regular **Bleed**, **Burn**, and **Toxin**.
- Combined Phosphor and other separately stacking enemy-side rending debuffs into the existing **Brittleness** indicator, using **2.5% per equivalent stack** with **40 stack / 100%** caps.
- Added explicit package coverage for the new status icons used both in Mod Options and during gameplay.
- Added optional support for **Alf's DMF Mod Settings Extensions**, including localized tabs and colored DoT/debuff dropdown icons.
- Reduced the minimum **Post-kill display duration** to `0.2` seconds, changed the default to `1` second, and added `0.2` second adjustment steps.
- Added optional DoT/debuff indicators for vanilla boss health bars, independent from the custom overhead healthbar.
- Added **Post-kill display duration** to keep the healthbar, info label, and DPS report visible for longer after an enemy dies.
- Improved info-label visibility so armour type or enemy name can appear from debuff-only marker visibility, even before direct damage is dealt.
- Added a configurable **info label** that can show either **armour type** or **enemy name**.
- Added safe localized enemy-name handling to prevent `<unlocalized ...>` strings or internal breed ids from appearing in the HUD.
- Decoupled the info label from damage-number rendering so the label can still display when damage numbers are disabled.
- Added a fallback for **armour type** in regular missions when exact hit-zone data is not available on the client.
- Added support for a broader status suite, including **Bleed**, **Burn**, **Warpfire**, **Toxin**, **Brittleness**, **Electrocuted**, **Skullcrusher**, **Thunderstrike**, **Melee damage taken**, **Increased damage taken**, and **Empyric Shock**.
- Added `Time (s)` display mode for **Skullcrusher** and **Thunderstrike**.
- Improved `Time (s)` behavior so invalid duration data hides the number instead of displaying a misleading `0`.
- Added readability options for status text: separate DOT and debuff font sizes, plus an optional DOT numbers-only mode.
- Increased the indicator layout to an **8-column / 2-row** grid.
- Switched healthbar anchoring to the native head node.
- Added a resync path so healthbars can recover more reliably for already-existing enemies when settings or marker state change.

## Future features
- Extend `Time (s)` display mode to other debuffs where reliable durations are available.
- Optional visual "about to expire" cue, for example blinking or alpha fade, when remaining time is low.
- Additional layout and readability options for players who prefer a cleaner or denser HUD.
