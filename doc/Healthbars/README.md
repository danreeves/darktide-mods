## Healthbars

**Healthbars** brings Psykhanium-style enemy healthbars into regular missions and expands them with optional combat readouts. The mod can show enemy health bars, floating damage numbers, a DPS readout, a configurable info label, and a set of DoT and debuff indicators above the bar.

### What it includes
- **Enemy healthbars** for selected enemy types in regular game modes
- **Damage numbers** when tracked enemies take damage
- **DPS report** for tracked targets after the damage window ends
- **Info label** above the bar
  - **Armour type**
  - **Enemy name**
- **Localized enemy names** using the game's normal display names
- **Safe localization fallback** that avoids showing internal ids or `<unlocalized ...>` text
- **DoT indicators**
  - **Bleed** stacks
  - **Burn** stacks
  - **Warpfire / Soulblaze** stacks
  - **Toxin** stacks
- **Debuff indicators**
  - **Brittleness indicator** (rending % against relevant armor types)
  - **Electrocuted** (presence indicator)
  - **Skullcrusher** (damage vs staggered, stacks / % / time)
  - **Thunderstrike** (impact modifier, stacks / % / time)
  - **Melee damage taken** (from multiple sources, icon-only or %)
  - **Increased total damage taken** (combined from several buffs, icon-only or %)
  - **Empyric Shock** (warp damage taken, stacks / % / time)

---

## Configuration

Open the mod options and look under **"Toggle features"**.

### Toggles (on/off)
- Show health bar
- Show damage numbers
- Show DPS report
- Show info label
- Show bleed stacks
- Show burn stacks
- Show warpfire (Soulblaze) stacks
- Show toxin stacks
- Show brittleness indicator
- Show electrocution debuff
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

### Display modes (per effect)
Some effects have a display dropdown:
- **Info label**: `Armour type` / `Enemy name`
- **Brittleness**: `Icon + text %` / `Icon only` / `Time (s)`
- **Skullcrusher**: `Stacks` / `Percent %` / `Icon only` / `Time (s)`
- **Thunderstrike**: `Stacks` / `Percent %` / `Icon only` / `Time (s)`
- **Melee damage taken**: `Icon + text %` / `Icon only`
- **Increased damage taken**: `Icon + text %` / `Icon only`
- **Empyric Shock**: `Stacks` / `Percent %` / `Time (s)`

### Text placement behavior
- `Percent` and `Icon + text %` modes render the text **centered and smaller** inside the icon.
- `Stacks` and `Time (s)` render a **bigger number** in the **bottom-right** of the icon.
- If the game reports active stacks but no reliable duration progress, the icon remains visible and the **time text is hidden** instead of showing a misleading `0`.

---

## Layout rules (how they appear above the healthbar)

- Indicators are displayed in an **8-column grid** with up to **2 rows**.
- If any debuff is active:
  - **Debuffs** occupy the first visual row.
  - **DoTs** shift into the second visual row.
- If no debuff is active:
  - **DoTs** occupy the first visual row.

### Ordering
- DoTs: `Bleed` -> `Burn` -> `Warpfire` -> `Toxin`
- Debuffs: `Brittleness` -> `Damage Taken` -> `Melee Damage Taken` -> `Skullcrusher` -> `Thunderstrike` -> `Empyric Shock` -> `Electrocuted`

---

## Status reference table (icons + color/state progression)

| Status | Icon | What it detects / measures | Text display options | Color/state progression |
|---|---:|---|---|---|
| **Bleed** | <img src="icons/bleed.png" width="50"> | DoT stacks from `bleed` | Stacks | Fixed color, blood red tint. |
| **Burn** | <img src="icons/burn.png" width="50"> | DoT stacks from `burning` | Stacks | Fixed color, orange flame tint. |
| **Warpfire (Soulblaze)** | <img src="icons/warpfire_color_option_three.png" width="50"> | DoT stacks from `warp_fire` | Stacks | <img src="icons/warpfire_color_option_one.png" width="25"> **Warp-Core**<br/><img src="icons/warpfire_color_option_two.png" width="25"> **Soulblaze Cyan**<br/><img src="icons/warpfire_color_option_three.png" width="25"> **Sanctified Cerulean** (default)<br/><img src="icons/warpfire_color_option_four.png" width="25"> **Ethereal Blue**<br/><img src="icons/warpfire_color_option_five.png" width="25"> **Peril Purple** |
| **Toxin** | <img src="icons/toxin.png" width="50"> | Combined DoT stacks from the tracked neurotoxin and exploding toxin interval buffs | Stacks | Fixed color, toxic green tint. |
| **Brittleness** | <img src="icons/brittleness_white.png" width="50"> | Total rending % from: `rending_debuff` (2.5%/stack, cap 16), `rending_burn_debuff` (1%/stack, cap 20), `shotgun_special_rending_debuff` (25%/stack, cap 1), `saw_rending_debuff` (2.5%/stack, cap 15). **Only shown for armor types:** Flak, Carapace, Maniac, Unyielding. Hidden below **2.5%**. | `Icon + %` / `Icon only` / `Time (s)` | <img src="icons/brittleness_white.png" width="25"> **2.5-19.9%**<br/><img src="icons/brittleness_yellow.png" width="25"> **20-29.9%**<br/><img src="icons/brittleness_orange.png" width="25"> **30-39.9%**<br/><img src="icons/brittleness_red.png" width="25"> **40-59.9%**<br/><img src="icons/brittleness_magenta.png" width="25"> **>=60%** |
| **Electrocuted** | <img src="icons/electrocuted.png" width="50"> | Presence of any supported electrocution-related buff template, for example shock effects, mauls, mines, or chain lightning style effects | No text | Fixed color, pale electrocuted tint. |
| **Skullcrusher** | <img src="icons/skullcrusher_white.png" width="50"> | Stagger damage taken debuff: `increase_damage_received_while_staggered` with fallback `damage_vs_staggered`. **10% per stack**, cap **8**. | `Stacks` / `Percent %` / `Icon only` / `Time (s)` | <img src="icons/skullcrusher_white.png" width="25"> **1-2** / 10-20%<br/><img src="icons/skullcrusher_yellow.png" width="25"> **3-4** / 30-40%<br/><img src="icons/skullcrusher_orange.png" width="25"> **5-6** / 50-60%<br/><img src="icons/skullcrusher_red.png" width="25"> **7-8** / 70-80% |
| **Thunderstrike** | <img src="icons/thunderstrike_white.png" width="50"> | Impact modifier debuff: `increase_impact_received_while_staggered` with fallback `impact_modifier`. **10% per stack**, cap **8**. | `Stacks` / `Percent %` / `Icon only` / `Time (s)` | <img src="icons/thunderstrike_white.png" width="25"> **1-2** / 10-20%<br/><img src="icons/thunderstrike_yellow.png" width="25"> **3-4** / 30-40%<br/><img src="icons/thunderstrike_orange.png" width="25"> **5-6** / 50-60%<br/><img src="icons/thunderstrike_red.png" width="25"> **7-8** / 70-80% |
| **Melee damage taken** | <img src="icons/melee_damage_taken_white.png" width="50"> | Counts active sources: `ogryn_staggering_damage_taken_increase` and `adamant_staggering_enemies_take_more_damage`. Each source adds **+15%** additively. | `Icon + %` / `Icon only` | <img src="icons/melee_damage_taken_white.png" width="25"> **1 source (15%)**<br/><img src="icons/melee_damage_taken_red.png" width="25"> **2 sources (30%)** |
| **Increased damage taken (total)** | <img src="icons/damage_taken_white.png" width="50"> | Computes combined damage taken increase from multiple supported buffs, additive modifiers, multipliers, tag stacks, and special cases | `Icon + %` / `Icon only` | <img src="icons/damage_taken_white.png" width="25"> **0-14.9%**<br/><img src="icons/damage_taken_yellow.png" width="25"> **15-29.9%**<br/><img src="icons/damage_taken_orange.png" width="25"> **30-44.9%**<br/><img src="icons/damage_taken_red.png" width="25"> **45-59.9%**<br/><img src="icons/damage_taken_magenta.png" width="25"> **>=60%** |
| **Empyric Shock** | <img src="icons/empyric_shock_white.png" width="50"> | Psyker debuff `psyker_force_staff_quick_attack_debuff`: **+6% warp damage taken per stack**, cap **5**, combined multiplicatively | `Stacks` / `Percent %` / `Time (s)` | <img src="icons/empyric_shock_white.png" width="25"> **1-2** / 6-12%<br/><img src="icons/empyric_shock_yellow.png" width="25"> **3** / 19%<br/><img src="icons/empyric_shock_orange.png" width="25"> **4** / 26%<br/><img src="icons/empyric_shock_red.png" width="25"> **5** / 34% |

---

## Notes / Implementation details
- Healthbars are anchored natively to the enemy **head node** instead of relying on custom world-position logic, which helps prevent the occasional bar-at-the-feet issue.
- Debuff changes trigger the same visibility window as damage, so indicators can appear when a debuff is applied even if the enemy has not taken direct damage yet.
- The mod supports **per-enemy healthbar toggles**, grouped by Horde/Roamer, Elite, Special, Monster/Captain, and Ritualist.
- **Damage numbers**, **DPS**, and the **info label** are handled independently, so the label can still work when damage numbers are disabled.
- **Enemy name** mode uses the game's localized `breed.display_name`.
- If localization data is missing or broken, the mod hides the label instead of showing internal names or `<unlocalized ...>` placeholders.
- **Armour type** uses the exact last hit zone when that data is available.
- In regular missions, the game does not always provide exact hit-zone data for networked enemies on the client, so armour type may fall back to the enemy's default/body armour instead of a more specific head or limb result.
- **Brittleness** is intentionally suppressed on armor types where it is not meaningful.
- **Electrocuted** is **presence-only**.
- **Warpfire** uses a player-selectable icon tint, with **Sanctified Cerulean** as the default option.
- **Increased damage taken (total)** is a **combined value**, so it can jump between color tiers quickly depending on team debuffs.
- Vanilla Psykhanium damage indicators are suppressed only in the **Psykhanium**, which avoids duplicate bars there while keeping regular mission behavior intact.

## Known issues
- **Brittleness `Time (s)`** depends on the game exposing reliable duration progress for the active rending buff. On some enemies or situations the icon may remain visible while the timer text is blank.
- **Armour type** in normal missions may reflect the enemy's default/body armour when exact hit-zone data is unavailable on the client.
- Percentage text can still be hard to read depending on icon color and background contrast.
- Very dense fights can produce a lot of simultaneous information if many status toggles are enabled at once.

## Recent additions
- Added a configurable **info label** that can show either **armour type** or **enemy name**.
- Added safe localized enemy-name handling to prevent `<unlocalized ...>` strings or internal breed ids from appearing in the HUD.
- Decoupled the info label from damage-number rendering so the label can still display when damage numbers are disabled.
- Added a fallback for **armour type** in regular missions when exact hit-zone data is not available on the client.
- Added support for a broader status suite, including **Bleed**, **Burn**, **Warpfire**, **Toxin**, **Brittleness**, **Electrocuted**, **Skullcrusher**, **Thunderstrike**, **Melee damage taken**, **Increased damage taken**, and **Empyric Shock**.
- Added `Time (s)` display mode for **Skullcrusher** and **Thunderstrike**.
- Improved `Time (s)` behavior so invalid duration data hides the number instead of displaying a misleading `0`.
- Increased the indicator layout to an **8-column / 2-row** grid.
- Switched healthbar anchoring to the native head node.
- Added a resync path so healthbars can recover more reliably for already-existing enemies when settings or marker state change.

## Future features
- Extend `Time (s)` display mode to other debuffs where reliable durations are available.
- Optional visual "about to expire" cue, for example blinking or alpha fade, when remaining time is low.
- Additional layout and readability options for players who prefer a cleaner or denser HUD.
