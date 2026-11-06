![Ammo Discipline](docs/banner.png)

# Ammo Discipline: realistic ammo limits and scavenging for SpaceBourne 2

You carry a few magazines, not a thousand rounds. A dead enemy gives you what was left in their
magazine, or nothing. Crates give a handful, and a magazine you drop during a reload is gone.
Every magazine counts, and the weapon you bring matters.

An idea by TheCalcMan (Steam).

**Links:** [GitHub](https://github.com/hubertdungen/SpaceBourne2-AmmoDiscipline) ·
[Nexus Mods](https://www.nexusmods.com/spacebourne2/mods/12) · UE4SS Lua mod · works alone or with
[Hardcore Tactical Realism](https://github.com/hubertdungen/SpaceBourne2-HardcoreTacticalRealism)
and the rest of the realism set.
**Install the whole realism set in one go:** the
[SpaceBourne 2 Realism installer](https://github.com/hubertdungen/SpaceBourne2-Realism)
([Nexus](https://www.nexusmods.com/spacebourne2/mods/11)).

## Features

### Carry limits

- **A limit per ammo type.** These are the spare rounds you carry, next to the game's own limit:

| Ammo | Limit | Game's limit |
|---|---|---|
| rifle and SMG rounds or cells | 240 | 999 |
| sniper and hunter rounds | 40 | 99 |
| laser sniper and hunter cells | 60 | 125 |
| shotgun shells | 32 | 299 |
| laser shotgun cells | 48 | 99 |
| pistol rounds or cells | 60 | 999 / 299 |

- **A few magazines.** Rifle magazines hold 50 to 100 rounds, so 240 rounds is a few magazines, plus
  the one in your gun.
- **Full means full.** Once you reach a limit, pickups of that type stop, with "Pouch full" on the
  HUD. On an old save with hundreds of rounds, the excess is left behind once, and the HUD says so.

### Scavenging

- **Dead enemies give what they carried.** You get the rounds left in the enemy's magazine,
  sometimes a spare magazine (bosses always have one), and sometimes nothing usable. Heavy rounds
  come from a sniper, rifle rounds from everyone else; nothing from melee fighters and robots.
- **Crates and loot give less.** An ammo crate gives about a quarter of your limit for each type
  (about 60 rifle rounds, 8 shotgun shells). Ammo lying around gives about 15 % of the limit (about
  36 rifle rounds). Shops and rewards are never reduced (you paid), but they stop at the limit.

### Reloading

- **Reloading drops the magazine.** The rounds left in it are lost, and the new magazine comes from
  your pouch. Reload when you're nearly empty, not after every burst.
- **Your pistol needs ammo too.** Pistols use pistol rounds or cells from the pouch instead of
  infinite ammo. Ammo crates have them, and some dead enemies carry their sidearm's rounds.
- **One click on an empty gun.** Pulling the trigger on an empty gun clicks once, not over and over
  while you hold it.

### HUD

- **The counter follows your pouch.** The HUD's spare-rounds number updates right after each pickup.
- **Short lines when it matters:** "Last magazine: 37 rifle rounds left", "Out of spare rifle
  rounds", "Pouch full: max 240 rifle rounds". They make no beep, stay about 5 seconds, and the same
  line comes back at most once in 30 seconds. A line for each pickup ("+18 rifle rounds") is off by
  default: the HUD counter shows it.

### On by default

- Ammo Discipline is on as soon as it is installed. **Shift+0** switches it off (the game's limits
  come back) and on again.

## Requirements

- SpaceBourne 2 (Steam).
- [UE4SS 3.0.1](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/v3.0.1), a free script loader
  for Unreal Engine games (the realism installer installs it for you).

## Install

**A. SpaceBourne 2 Realism installer (recommended)**
Get it on [Nexus](https://www.nexusmods.com/spacebourne2/mods/11) or
[GitHub](https://github.com/hubertdungen/SpaceBourne2-Realism/releases/latest). Tick Ammo
Discipline and any other mods of the set: it installs UE4SS if you don't have it, switches the mods
on and keeps them updated.

**B. Manual** (Nexus file, or the zip on the [releases page](https://github.com/hubertdungen/SpaceBourne2-AmmoDiscipline/releases))
1. Extract the zip into your game folder (`...\SpaceBourne 2`, the one with `SpaceBourne2.exe`).
   It creates `SB2\Binaries\Win64\Mods\AmmoDiscipline` and switches itself on.
2. No UE4SS yet? Get [RE-UE4SS 3.0.1](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/v3.0.1)
   and copy `dwmapi.dll`, `UE4SS.dll` and `UE4SS-settings.ini` into
   `SpaceBourne 2\SB2\Binaries\Win64\`.

**Uninstall:** untick Ammo Discipline in the installer or delete the `AmmoDiscipline` folder. The
game's limits come back next time you play; rounds that were left behind or never picked up do not
come back.
**Your save:** the spare rounds are part of the game's own data, so the limits are saved with your
game like any ammo you spend. Ammo Discipline writes no files of its own to your saves.

## Controls

**Shift+0** switches Ammo Discipline on/off (change it with `ToggleKey` in `scripts\config.lua`).

## Settings

Edit `Mods\AmmoDiscipline\scripts\config.lua` with Notepad. Every line is optional.

- `Caps`: the limit per ammo type.
- `TrimToLimit`: whether extra rounds on an old save are left behind.
- `Scavenge`:
  - what bodies give: `NothingChance` (25 %), `SpareMagazineChance` (20 %), `HeavyRoundsShare`,
    `RobotsCarryAmmo`, `SidearmChance`;
  - crates: `CrateShare` (25 % of the limit);
  - loot: `LootShare` (15 % of the limit);
  - `Enemies`, `Crates` and `Loot` switch each one off.
- `Reload.DropMagazine`: `false` keeps the game's top-up reload. `Reload.OneDryClick`: `false` gives
  back the game's clicking on an empty gun.
- `Pistols.LimitedAmmo`: `false` gives back infinite pistol ammo.
- `Messages`: switch off any HUD line. `DroppedMagazine` adds a line on every reload; `Pickups` a
  line for each pickup. `Quiet = false` gives the lines the HUD's beep back.

## Works with the realism set

- **Hardcore Tactical Realism:** HTR sets the enemies' magazines (30 or 40 rounds), and Ammo
  Discipline reads them when an enemy dies. HTR's ballistics are unchanged.
- **Tactical Engineering:** your turret keeps its own 300 rounds and its refill at the ship. It does
  not use your pouch.
- **Silent Ops:** fitting a suppressor still blocks firing as before.
- **Gear Without Levels:** independent.

## Known limits

- **The game's ammo counter shows your spare rounds, not the limit.** The limits are in the table
  above.
- **Enemies with no data.** If the game drops ammo for an enemy Ammo Discipline did not see, you get
  a quarter of the game's amount.
- **Swapping weapons in the inventory** unloads the magazine into your pouch. One magazine may sit
  on top of a full pouch.

Design notes and research: [DESIGN.md](DESIGN.md). Version history: [CHANGELOG.md](CHANGELOG.md).

## The SpaceBourne 2 realism set

Separate mods that work alone or in any combination. The
[SpaceBourne 2 Realism installer](https://github.com/hubertdungen/SpaceBourne2-Realism)
([Nexus](https://www.nexusmods.com/spacebourne2/mods/11)) installs the ones you tick and keeps them updated.

- **[Hardcore Tactical Realism](https://github.com/hubertdungen/SpaceBourne2-HardcoreTacticalRealism)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/4)): realistic ballistics, wounds and tactical AI. The core of the set.
- **[Silent Ops](https://github.com/hubertdungen/SpaceBourne2-SilentOps)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/6)): stealth, silent takedowns and suppressors.
- **[Ammo Discipline](https://github.com/hubertdungen/SpaceBourne2-AmmoDiscipline)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/12)): carried ammo limits and scavenging, so every magazine counts.
- **[Gear Without Levels](https://github.com/hubertdungen/SpaceBourne2-GearWithoutLevels)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/7)): use gear above your level, with small handling penalties.
- **[Tactical First Person](https://github.com/hubertdungen/SpaceBourne2-TacticalFirstPerson)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/15)): first person on foot, weapons held up, aiming down the sights.
- **[Tactical Engineering](https://github.com/hubertdungen/SpaceBourne2-TacticalEngineering)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/10)): realistic deployable turrets.
- **[Get Out of the Way](https://github.com/hubertdungen/SpaceBourne2-GetOutOfTheWay)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/14)): NPCs step aside naturally when you walk through them.
- **[Ground Waypoints](https://github.com/hubertdungen/SpaceBourne2-GroundWaypoints)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/13)): planet waypoints on foot and on the hoverbike.
- **[Faction Power](https://github.com/hubertdungen/SpaceBourne2-FactionPower)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/9)): dungeons, strategic sales and missions earn your faction power.
- **[Bigger Armies](https://github.com/hubertdungen/SpaceBourne2-BiggerArmies)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/17)): twice the general slots for your faction's ground and space forces.
- **[Clear HUD](https://github.com/hubertdungen/SpaceBourne2-ClearHUD)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/16)): a reticle you can see and HUD colours of your choice.
- **[Split Controls](https://github.com/hubertdungen/SpaceBourne2-SplitControls)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/5)): separate vertical invert for ship and on foot, per device.
- **[SB2 HOTAS](https://github.com/hubertdungen/SpaceBourne2-HOTAS)**
  ([Nexus](https://www.nexusmods.com/spacebourne2/mods/8)): HOTAS, rudder pedals, triple screens and head tracking.

## Thanks

**TheCalcMan** (Steam), for the idea of this mod and for play-testing the realism set.

## License

MIT. See [LICENSE](LICENSE).
