# Kortz Heist Helper

A [Cherax](https://cherax.menu/) Lua script for the new **Kortz Center Heist**.

<img width="596" height="538" alt="image" src="https://github.com/user-attachments/assets/46b47ad5-743c-429d-a07c-f24e07a0fa61" />

> **Heads up:** this is my first script, expect bugs and design ugliness 😅! This has been tested on EE only tho.

## Features

### Heist Setup
- **Complete Scope-Out**: marks every painting, item and POI as scoped
- **Primary Target**: pick any of the 27 vault paintings, read back the current one, apply your choice
- **Complete ALL Preps**: full prep skip: scope-out, every setup mission, all 3 unmarked
  weapon loadouts (Street / Security / Military) and your selected target in one click
- **Force Setup Heist**: aggressive fallback that maxes every K26 bitset, rolls a fresh
  seed and clears cooldowns (use if the normal prep skip isn't enough)
- **Mansion Paintings**: own the entire mansion gallery (keep all paintings) or reset
  ownership to restore first-steal bonuses and full target rotation

### Heist Minigames (use these DURING the finale)
- **Bypass Fingerprint Hack**: instantly completes the fingerprint hack while it's on screen
- **Bypass Vault Hack**: instantly completes the vault door / keypad hack while it's on screen
- **Disable Vault Lasers**: deactivates the entire green-vault laser grid (press it inside the laser room)

### Heist Control
- **Buyer Requests**: choose up to 3 secondary targets by name (with payout values)
- **Clear Cooldowns**: resets normal and hard-mode heist cooldowns
- **Weekly Boost**: enables the weekly boost bitset
- **Awards**: unlock or reset all Kortz Center heist awards/challenges

## Installation

1. Download `kortz.lua`
2. Drop it into your `Cherax\Lua` folder (or use **Cherax → Lua Editor → New Script → Save it**)
3. Run the script

## Usage

1. **⚠️ SETUP THE HEIST FIRST**: accept the GTA$100,000 setup purchase prompt first at the planning
   board before completing any scope or prep button. The script only completes what the
   game thinks you've started; applying stats before buying the heist does nothing
   (or leaves the board in a weird state)
2. Pick your primary target (Optional if you wanna switch it), press **Complete ALL Preps**
3. **Step out of the art room (in the mansion) and back in** so the planning board
   reloads, can't figure out how to make it self reload (maybe some can help with that?)
4. During the finale, use the **Heist Minigames** buttons when you reach each hack / the laser room
5. Profit! 

## Notes

- **Board refresh is currently manual**: automatic board reloading is bugged, so after
  applying anything the planning board will NOT update on its own. Leave the art room
  in the mansion, walk back in, and the board will show your changes
- The **Heist Minigames** buttons only work while you're actually in the finale: press
  each hack bypass WHILE its minigame is on screen, and Disable Vault Lasers inside the
  laser room
- Owned mansion paintings count as already stolen: first-steal bonuses won't apply to
  them (use **Reset Owned Paintings** before grinding payouts)
- Primary target payout values other than La Dernière Débauche aren't publicly available yet so I didnt include all of em! 
- Buyer request slot order is best-effort

## Credits & Thanks

- [SilentSalo/SilentNight-Script](https://github.com/SilentSalo/SilentNight-Script) —
  invaluable reference for the Cherax Lua API (FeatureMgr, ClickGUI, stat wrappers and
  overall script structure)
- [SourceModzZ/latest-decompiled-scripts-from-gta-v-enhanced_1.73](https://github.com/SourceModzZ/latest-decompiled-scripts-from-gta-v-enhanced_1.73) —
  decompiled `kortz_planning` / `fm_content_kortz_*` / `fm_mission_controller_v3` scripts
  used to map the K26 stats, prep bitsets and the in-heist minigame logic

## Disclaimer

For educational purposes. Modifying GTA Online stats can get your account suspended,
reset or banned: use at your own risk.
