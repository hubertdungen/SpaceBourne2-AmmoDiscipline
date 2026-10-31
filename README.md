![Ammo Discipline](docs/banner.png)

# Ammo Discipline: realistic ammo limits and scavenging for SpaceBourne 2

You carry a few magazines, not a thousand rounds. A dead enemy gives you what was left in their
magazine, or nothing. Crates give a handful, and a magazine you drop during a reload is gone.
Every magazine counts, and the weapon you bring matters.

An idea by TheCalcMan (Steam).

Version 0.1.0 · UE4SS Lua mod · [GitHub](https://github.com/hubertdungen/SpaceBourne2-AmmoDiscipline) ·
works alone or with [Hardcore Tactical Realism](https://github.com/hubertdungen/SpaceBourne2-HardcoreTacticalRealism)
and the rest of the realism set.

## What it does

- **Carry limits per ammo type.** These are the spare rounds you carry, with the game's own limit in brackets:

  | Ammo | Limit | Game's limit |
  |---|---|---|
  | rifle and SMG rounds or cells | 240 | 999 |
  | sniper and hunter rounds | 40 | 99 |
  | laser sniper and hunter cells | 60 | 125 |
  | shotgun shells | 32 | 299 |
  | laser shotgun cells | 48 | 99 |
  | pistol rounds or cells | 60 | 999 / 299 |

  Rifle magazines hold 50 to 100 rounds, so 240 rounds is a few magazines, plus the one in your gun.
  Once you reach a limit, pickups of that type stop, with "Pouch full" on the HUD. On an old save
  with hundreds of rounds, the excess is left behind once, and the HUD says so.
- **Dead enemies give what they carried.** The game gives 40 to 100 rounds of a random type from 70 % of
  the dead. With Ammo Discipline you get:
  - the rounds left in the enemy's magazine;
  - sometimes a spare magazine (bosses always have one);
  - sometimes nothing usable;
  - heavy rounds from a sniper, rifle rounds from everyone else;
  - nothing from melee fighters and robots.
- **Crates and loot give less.** An ammo crate gives 30 rounds of each type instead of 100. Ammo
  lying around gives half. Shops and rewards are never reduced (you paid), but they stop at the limit.
- **Reloading drops the magazine.** The rounds left in it are lost, and the new magazine comes
  from your pouch. Reload when you're nearly empty, not after every burst.
- **Your pistol needs ammo too.** The game gives pistols infinite ammo. Here they use pistol rounds or
  cells from the pouch. Ammo crates have them, and some dead enemies carry their sidearm's rounds.
- **HUD lines** when it matters:
  - "Last magazine: 37 rifle rounds left";
  - "Out of spare rifle rounds";
  - "Pouch full: max 240 rifle rounds";
  - "+18 rifle rounds" or "No usable ammo" from a body;
  - the totals from a crate.

  None of them play the game's warning alarm.
- **On by default.** **Shift+0** (the top-row zero) switches it off: the game's limits come back. Press it again to switch it back on.

## Requirements

- SpaceBourne 2 (Steam).
- [UE4SS 3.0.1](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/v3.0.1). Installing HTR or the
  realism installer installs it too.

## Install

1. Download `AmmoDiscipline-0.1.0.zip` from the
   [releases](https://github.com/hubertdungen/SpaceBourne2-AmmoDiscipline/releases).
2. Extract it into the game folder (`...\steamapps\common\SpaceBourne 2\`). It adds
   `SB2\Binaries\Win64\Mods\AmmoDiscipline\`, and the `enabled.txt` inside turns it on.
3. That's it: it is on in game.

Manual install: copy the `AmmoDiscipline` folder from this repository into
`SpaceBourne 2\SB2\Binaries\Win64\Mods\`.

To uninstall, delete `SB2\Binaries\Win64\Mods\AmmoDiscipline`. The game's limits come back next time you
play. Rounds that were left behind or never picked up do not come back.

**Your save:** the spare rounds are part of the game's own data, so the limits are saved with your
game like any ammo you spend. Ammo Discipline writes no files of its own to your saves.

## Controls

| Key | What it does |
|---|---|
| **Shift+0** | Ammo Discipline on / off (on by default). Off = the game's limits and drops. |

0 is the zero above the letters, not the numeric keypad. The game never uses it. Plain 0 belongs to
Ground Waypoints, which stays quiet while Shift is held. You can change the key with
`ToggleKey` in `scripts\config.lua`. The game's own keys (F1–F6, F8, F10, F11, F12) are refused
without Shift.

## Settings

Edit `Mods\AmmoDiscipline\scripts\config.lua` with Notepad. Every line is optional.
- `Caps`: the limit per ammo type.
- `TrimToLimit`: whether extra rounds on an old save are left behind.
- `Scavenge`:
  - what bodies give: `NothingChance` (25 %), `SpareMagazineChance` (20 %), `HeavyRoundsShare`,
    `RobotsCarryAmmo`, `SidearmChance`;
  - crates: `CrateShare` (30 %);
  - loot: `LootShare` (50 %);
  - `Enemies`, `Crates` and `Loot` switch each one off.
- `Reload.DropMagazine`: `false` keeps the game's top-up reload.
- `Pistols.LimitedAmmo`: `false` gives back infinite pistol ammo.
- `Messages`: switch off any HUD line. `DroppedMagazine` adds a line on every reload.

## Works with the realism set

- **Hardcore Tactical Realism:** HTR sets the enemies' magazines (30 or 40 rounds), and Ammo
  Discipline reads them when an enemy dies. HTR's ballistics are unchanged.
- **Tactical Engineering:** your turret keeps its own 300 rounds and its refill at the ship. It does
  not use your pouch.
- **Silent Ops:** fitting a suppressor still blocks firing as before.
- **Gear Without Levels:** independent.

## Status and known limits

Tested in game on 2026-10-31, with HTR 0.4.8, Silent Ops, Split Controls, Gear Without Levels and SB2 HOTAS:
- limits on load: an old save's 999 rounds were cut to the limit plus one magazine;
- a shop-style pickup stopping at the limit;
- reloading with 10 rounds left: the magazine was dropped and a full one came from the pouch;
- enemy drops: the game's 50–79 rounds became 17–39, of the type the enemy carried;
- an ammo crate (100 → 30 of each type) and ammo lying around (40 → 20);
- the pistol reloading from pistol rounds;
- the on/off key with a real key press, off and on (tested as Shift+P; 0.1.0 ships Shift+0, the same
  mechanism, because the game closes windows on a raw P press);
- frame times with and without the mod.

Known limits:
- **The game's ammo counter shows your spare rounds, not the limit.** The limits show in the HUD
  lines above.
- **Enemies with no data.** If the game drops ammo for an enemy Ammo Discipline did not see, you get
  a quarter of the game's amount.
- **Swapping weapons in the inventory** unloads the magazine into your pouch. One magazine may sit on
  top of a full pouch.

Design notes, research and the test log: [DESIGN.md](DESIGN.md).

## Part of the SpaceBourne 2 realism set

Part of the realism set, built around [Hardcore Tactical Realism](https://www.nexusmods.com/spacebourne2/mods/4)
as the core mod. HTR is not required: this mod works on its own or with any of the others.
To install them all at once, use the installer:
[SpaceBourne 2 Realism](https://github.com/hubertdungen/SpaceBourne2-Realism)
([Nexus](https://www.nexusmods.com/spacebourne2/mods/11)).

| Mod | Status |
|---|---|
| **Hardcore Tactical Realism (HTR)**: realistic ballistics and tactical AI | released: [GitHub](https://github.com/hubertdungen/SpaceBourne2-HardcoreTacticalRealism) · [Nexus Mods](https://www.nexusmods.com/spacebourne2/mods/4) |
| **Split Controls**: separate invert for ship and on foot | released: [GitHub](https://github.com/hubertdungen/SpaceBourne2-SplitControls) · [Nexus Mods](https://www.nexusmods.com/spacebourne2/mods/5) |
| **Silent Ops**: realistic stealth | released: [GitHub](https://github.com/hubertdungen/SpaceBourne2-SilentOps) · [Nexus Mods](https://www.nexusmods.com/spacebourne2/mods/6) |
| **Gear Without Levels**: use gear regardless of level | released: [GitHub](https://github.com/hubertdungen/SpaceBourne2-GearWithoutLevels) · [Nexus Mods](https://www.nexusmods.com/spacebourne2/mods/7) |
| **SB2 HOTAS**: HOTAS, triple screens, head tracking | released: [GitHub](https://github.com/hubertdungen/SpaceBourne2-HOTAS) · [Nexus Mods](https://www.nexusmods.com/spacebourne2/mods/8) |
| **Faction Power**: your faction's power and the galaxy's reaction | released: [GitHub](https://github.com/hubertdungen/SpaceBourne2-FactionPower) · [Nexus Mods](https://www.nexusmods.com/spacebourne2/mods/9) |
| **Tactical Engineering**: deployable turrets | released: [GitHub](https://github.com/hubertdungen/SpaceBourne2-TacticalEngineering) · [Nexus Mods](https://www.nexusmods.com/spacebourne2/mods/10) |
| **Ammo Discipline**: ammo limits and scavenging (this mod) | released: [GitHub](https://github.com/hubertdungen/SpaceBourne2-AmmoDiscipline) |
| Tactical First Person | coming |
| Ground Waypoints | coming |

## Thanks

**TheCalcMan** (Steam), for the idea of this mod and for play-testing the realism set.

## License

MIT. See [LICENSE](LICENSE).
