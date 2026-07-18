# Kortz Heist Helper
<img width="597" height="543" alt="image" src="https://github.com/user-attachments/assets/9c1ca007-8362-4dba-9db9-ff74d6f1ffb6" />

A [Cherax](https://cherax.menu/) Lua script for the new **Kortz Center Heist**.

> **Heads up:** this is my first script, expect bugs! I just wanted to share it with the community.

## Features

### Heist Setup
- **Complete Scope-Out** — marks every painting, item and POI as scoped
- **Primary Target** — pick any of the 27 vault paintings, read back the current one, apply your choice
- **Complete ALL Preps** — full prep skip: scope-out, every setup mission, all 3 unmarked
  weapon loadouts (Street / Security / Military) and your selected target in one click
- **Mansion Paintings** — own the entire mansion gallery (keep all paintings), or reset
  ownership to restore first-steal bonuses and full target rotation

### Heist Control
- **Buyer Requests** — choose up to 3 secondary targets by name (with payout values)
- **Clear Cooldowns** — resets normal and hard-mode heist cooldowns
- **Weekly Boost** — enables the weekly boost bitset
- **Force Setup Heist** — aggressive fallback that maxes every K26 bitset, rolls a fresh
  seed and clears cooldowns
- **Awards** — unlock or reset all Kortz Center heist awards/challenges

## Installation

1. Download `kortz.lua`
2. Drop it into your `Cherax\Lua` folder (or use **Cherax → Lua Editor → New Script → Save it**)
3. Run the script — a **Kortz Heist** tab appears in the Click GUI (INSERT menu)

## Usage

1. Be **online** with your character fully loaded
2. **⚠️ BUY THE HEIST FIRST** — accept the GTA$100,000 purchase prompt first at the planning
   board before completing any scope or prep button. The script only completes what the
   game thinks you've started; applying stats before buying the heist does nothing
   (or leaves the board in a weird state)
3. Pick your primary target (Optional if you wanna switch it), press **Complete ALL Preps**
4. **Step out of the art room (in the mansion) and back in** so the planning board
   reloads, can't figure out how to make it self reload (maybe some can help with that?)
5. Profit! 

## Notes

- **Board refresh is currently manual**: automatic board reloading is bugged, so after
  applying anything the planning board will NOT update on its own. Leave the art room
  in the mansion, walk back in, and the board will show your changes
- Owned mansion paintings count as already stolen: first-steal bonuses won't apply to
  them (use **Reset Owned Paintings** before grinding payouts)
- Primary target payout values other than La Dernière Débauche aren't publicly available yet so I didnt include all of em! 

## Credits & Thanks

- [SilentSalo/SilentNight-Script](https://github.com/SilentSalo/SilentNight-Script) —
  invaluable reference for the Cherax Lua API (FeatureMgr, ClickGUI, stat wrappers and
  overall script structure)
- [SourceModzZ/latest-decompiled-scripts-from-gta-v-enhanced_1.73](https://github.com/SourceModzZ/latest-decompiled-scripts-from-gta-v-enhanced_1.73) —
  decompiled `kortz_planning` / `fm_content_kortz_*` scripts used to map the K26 stats,
  prep bitsets and planning-board logic

## Disclaimer

For educational purposes. Modifying GTA Online stats can get your account suspended,
reset or banned — use at your own risk.
