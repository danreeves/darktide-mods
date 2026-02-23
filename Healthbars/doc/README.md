## Healthbars fork for Added Status Indicators

This fork extends **Healthbars** with additional **DoT/debuff indicators** rendered as small icons over the enemy healthbar.

### What’s new
- **DoT**
    - **Warpfire / Soulblaze** stacks
- **Debuffs**
    - **Brittleness indicator** (rending % against relevant armor types)
    - **Electrocuted** (presence indicator)
    - **Skullcrusher** (damage vs staggered; stacks or %)
    - **Thunderstrike** (impact modifier; stacks or %)
    - **Melee damage taken** (from multiple sources; icon-only or %)
    - **Increased total damage taken** (combined from several buffs; icon-only or %)
    - **Empyric Shock** (warp damage taken; stacks or %)

---

## Configuration

Open the mod options and look under **"Toggle features"**:

### Toggles (on/off)
- Show warpfire (Soulblaze) stacks
- Show brittleness indicator
- Show electrocution debuff
- Show Skullcrusher debuff
- Show Thunderstrike debuff
- Show Melee damage taken debuff
- Show Increased damage taken debuff
- Show Empyric Shock debuff

### Display modes (per effect)
Some effects have a display dropdown:
- **Brittleness**: `Icon + text %` / `Icon only`
- **Skullcrusher**: `Stacks` / `Percent %` / `Icon only`
- **Thunderstrike**: `Stacks` / `Percent %` / `Icon only`
- **Melee damage taken**: `Icon + text %` / `Icon only`
- **Increased damage taken**: `Icon + text %` / `Icon only`
- **Empyric Shock**: `Stacks` / `Percent %`

### Text placement behavior
- "Percent" and "Icon + text %" modes render the text **centered/smaller** inside the icon.
- "Stacks" renders a **bigger number** in the **bottom-right** of the icon.

---

## Layout rules (how they appear above the healthbar)

- Indicators are displayed in a **6-column grid** (up to **2 rows**).
- **If any debuff is active**:
    - **Debuffs** go into the **first row**
    - **DoTs** shift into the **second row**
- **If no debuff is active**:
    - **DoTs** occupy the **first row**

### Ordering
- DoTs: `Bleed` → `Burn` → `Warpfire` → `Toxin`
- Debuffs: `Brittleness` → `Damage Taken` → `Melee Damage Taken` → `Skullcrusher` → `Thunderstrike` → `Empyric Shock` → `Electrocuted`

---

## Status reference table (icons + color/state progression)

| Status |                                                                     Icon | What it detects / measures | Text display options | Color/state progression                                                                                                                                                                                                                                                                                                                           |
|---|-------------------------------------------------------------------------:|---|---|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Warpfire (Soulblaze)** |                 <img src="icons/warpfire.png" width="50"> | DoT stacks from `warp_fire` | Stacks | Fixed color (warpfire tint).                                                                                                                                                                                                                                                                                                                      |
| **Brittleness** |        <img src="icons/brittleness_white.png" width="50"> | Total rending % from: `rending_debuff` (2.5%/stack, cap 16), `rending_burn_debuff` (1%/stack, cap 20), `shotgun_special_rending_debuff` (25%/stack, cap 1), `saw_rending_debuff` (2.5%/stack, cap 15). **Only shown for armor types:** Flak, Carapace, Maniac, Unyielding. Hidden below **2.5%**. | `Icon + %` / `Icon only` | <img src="icons/brittleness_white.png" width="25"> **2.5-19.9%**<br/><img src="icons/brittleness_yellow.png" width="25"> **20-29.9%**<br/><img src="icons/brittleness_orange.png" width="25"> **30-39.9%**<br/><img src="icons/brittleness_red.png" width="25"> **40-59.9%**<br/><img src="icons/brittleness_magenta.png" width="25"> **≥60%**    |
| **Electrocuted** |             <img src="icons/electrocuted.png" width="50"> | Presence of any "electrocution keyword" buff template (e.g. shock grenade/mine/mauls/chain lightning/etc.). | No text | Fixed color (pale electrocuted tint).                                                                                                                                                                                                                                                                                                             |
| **Skullcrusher** |       <img src="icons/skullcrusher_white.png" width="50"> | Stagger damage taken debuff: `increase_damage_received_while_staggered` (fallback `damage_vs_staggered`). **10% per stack**, cap **8**. | `Stacks` / `Percent %` / `Icon only` | <img src="icons/skullcrusher_white.png" width="25"> **1-2** / 10-20%<br/><img src="icons/skullcrusher_yellow.png" width="25"> **3-4** / 30-40%<br/><img src="icons/skullcrusher_orange.png" width="25"> **5-6** / 50-60%<br/><img src="icons/skullcrusher_red.png" width="25"> **7-8** / 70-80%                                                   |
| **Thunderstrike** |      <img src="icons/thunderstrike_white.png" width="50"> | Impact modifier debuff: `increase_impact_received_while_staggered` (fallback `impact_modifier`). **10% per stack**, cap **8**. | `Stacks` / `Percent %` / `Icon only` | <img src="icons/thunderstrike_white.png" width="25"> **1-2** / 10-20%<br/><img src="icons/thunderstrike_yellow.png" width="25"> **3-4** / 30-40%<br/><img src="icons/thunderstrike_orange.png" width="25"> **5-6** / 50-60%<br/><img src="icons/thunderstrike_red.png" width="25"> **7-8** / 70-80%                                               |
| **Melee damage taken** | <img src="icons/melee_damage_taken_white.png" width="50"> | Counts active sources: `ogryn_staggering_damage_taken_increase` and `adamant_staggering_enemies_take_more_damage`. Each source adds **+15%** (additive). | `Icon + %` / `Icon only` | <img src="icons/melee_damage_taken_white.png" width="25"> **1 source (15%)**<br/><img src="icons/melee_damage_taken_red.png" width="25"> **2 sources (30%)**                                                                                                                                                                                      |
| **Increased damage taken (total)** |       <img src="icons/damage_taken_white.png" width="50"> | Computes combined "damage taken" increase from multiple buffs (additive modifiers + multiplicative buffs + tag stacks + special cases). | `Icon + %` / `Icon only` | <img src="icons/damage_taken_white.png" width="25"> **0-14.9%**<br/><img src="icons/damage_taken_yellow.png" width="25"> **15-29.9%**<br/><img src="icons/damage_taken_orange.png" width="25"> **30-44.9%**<br/><img src="icons/damage_taken_red.png" width="25"> **45-59.9%**<br/><img src="icons/damage_taken_magenta.png" width="25"> **≥60%** |
| **Empyric Shock** |     <img src="icons/empyric_shock_white.png" width="50"> | Psyker debuff `psyker_force_staff_quick_attack_debuff`: **+6% warp damage taken per stack**, cap **5**, combined multiplicatively. | `Stacks` / `Percent %` | <img src="icons/empyric_shock_white.png" width="25"> **1-2** / 6-12%<br/><img src="icons/empyric_shock_yellow.png" width="25"> **3** / 19%<br/><img src="icons/empyric_shock_orange.png" width="25"> **4** / 26%<br/><img src="icons/empyric_shock_red.png" width="25"> **5** / 34%                                                               |

---

## Notes / Implementation details
- **Brittleness** is intentionally suppressed on armor types where it’s not meaningful (e.g. unarmored).
- "Electrocuted" is **presence-only** (no stacks shown, in source it can stack once).
- "Increased damage taken (total)" is a **combined value** (several different sources can contribute at once), so it may jump between color tiers quickly depending on team debuffs.
 
## Known issues
- Debuffs becomes visible only when enemy has taken damage.
- Percentage texts are sometimes hard to read.

## Future features
- Some visual effect to show when a debuff is running out. So that players can refresh in time.