# Ammo Discipline: design notes

Idea: TheCalcMan (Steam). Goal: every magazine counts. You carry a few magazines, scavenging gives
little, and a magazine dropped during a reload is gone.

Names come from the game's Blueprints (UE 4.27, build of 2026-10-26), read in a local dump that is
never committed. Everything below is a UE4SS 3.0 Lua post-hook on a Blueprint function, following the
set's rules: no FindAllOf, no native hooks, every UObject call guarded.

## 1. How the game stores ammo

- **Reserve (pouch):** `Game_Builder_C.Ammos`, an array of `S_Ammo_Data` with `AmmoType`, `CurrentAmount`,
  `MaxCarryAmount`, `AmmoName` and `Bullet_Icon`. One entry per type, created on the first pickup.
- **Types:** these come from the DataTable `/Game/1Data/Ammo_Data/Ammos`. Its rows hold the vanilla
  carry limits. The `Bullet_Types_For_Easy_Add` enum gives each type its index.

  | # | Row | `AmmoType` string | Used by | Vanilla max |
  |---|---|---|---|---|
  | 0 | Small_Bullet | `S_B` | bullet pistol | 999 |
  | 1 | Medium_Bullet | `Medium_Ammo` | rifle, SMG | 999 |
  | 2 | Large_Bullet | `Large_Bullet` | sniper, hunter | 99 |
  | 3 | Bullet_Shell | `Bullet_Shell` | shotgun | 299 |
  | 4 | Small_Laser | `Small_Laser` | laser pistol | 299 |
  | 5 | Medium_Laser | `Medium_Laser` | pulse rifle, beam SMG | 999 |
  | 6 | Large_Laser | `Large_Laser` | laser sniper, laser hunter | 125 |
  | 7 | Laser_Shell | `Laser_Shell` | laser shotgun | 99 |

- **Every change goes through one function:** `Game_Builder_C:Add Ammo(RowName, Amount, ByName, Name)`.
  A positive amount is a pickup and is clamped to the entry's `MaxCarryAmount`. A negative amount is a
  reload. Each call rewrites `MaxCarryAmount` from the DataTable. `GetAmmoCount` reads the same array.
- **Magazines:** each weapon slot has a magazine, `Game_Builder.Slot_N_Weapon.CurrentBulletsAtMagazine`
  (N = 0..2). The weapon writes it through `SetMagazinAtSarjor(index, n)`.
- **Pistols (slot 0) have infinite ammo:** `EquipHandWeaponToPack` always sets `InfiniteAmmo? = true` on
  slot 0, so the reserve is never used.
- **Reload:** `Master_Hand_Weapon_C:CustomEvent_2` sets `Reloading = true` and, in the same call, runs
  the refill. The refill does three things:
  1. `need = MagazineSize - magazine`, and `Ammo_To_Add = min(need, reserve)`;
  2. `Add Ammo(type, -Ammo_To_Add)`;
  3. `Add Ammo to Magazine(Ammo_To_Add)`, then `SetMagazinAtSarjor(index, magazine + Ammo_To_Add)`.

  So a vanilla reload tops up and keeps the rounds left in the old magazine.
- **Sources of new rounds:**
  - **Dead enemies:** `Q1_Shooter_AI_C:ThrowAmmo`. With a 70 % chance it spawns an `AmmoThrowCase_C`.
    The case flies to you and, in `Timeline_0__UpdateFunc` (closer than 50 cm) or
    `Timeline_0__FinishedFunc`, adds 40 to 100 rounds of a random type (1, 2, 3, 5, 6 or 7).
  - **Ammo crates:** `/Game/JUPITER_SciFi_Kit/Blueprints/AmmoCrate.AmmoCrate_C`. When `Opening__FinishedFunc`
    runs, the crate adds 100 rounds of every type in its list.
  - **Ammo lying around:** `/Game/1Data/Interactives/Loots/Master_Drop_Loot.Master_Drop_Loot_C:Interact`
    (child `Ammo_C`). It adds `AmmoAmount` of `Ammo_Type`.
  - **Others (shops, rewards):** these are not in the dump. They only go through `Add Ammo`.
- **What a dead enemy carried:** the enemy's `Ammo` is the rounds left in its magazine; `MaxAmmo` is its
  magazine (HTR sets it to 30 or 40). Its type comes from `SubType` (0 shooter, 1 tank, 2 melee, 3 mage),
  `IsSniper?` and `Robot?`. `AmmoClass` tells bullet (`ShooterBulletProjectile_C`) from laser
  (`ShooterLazerProjectile_C`) for some enemies only; the rest keep a visual-only class.

## 2. Design

### Carry limits per type (`Caps`)
- While the mod is on, the entry's `MaxCarryAmount` holds our limit. The game's own clamp in `Add Ammo`
  then stops pickups at the limit, and so does any menu that reads it. After each `Add Ammo` the game
  writes the DataTable value back, so the hook sets the limit again.
- **Trim:** the reserve is cut to the limit, plus one magazine of a weapon you carry that uses the type
  (switching weapons in the inventory unloads the magazine into the pouch). Old saves with 999 rounds
  drop the excess once, with a HUD line.
- **Switched off:** the vanilla limits are written back. Nothing is given back.

### Scavenging (`Scavenge`)
UE4SS 3.0 runs a Blueprint hook after the body. So the source's hook (the case, crate or loot that called
`Add Ammo`) runs right after `Add Ammo`'s own hook, in the same call.

1. The `Add Ammo` hook records each positive add: type, amount, the reserve before and after, and the time.
   - The reserve before is `after - amount`, unless the game clamped the add at the limit. In that case
     the last known value is used.
2. The source hook takes back the adds from the last few milliseconds (newest first). Then it gives the
   rounds for that source, within the limit.

What each source gives:
- **Enemy case:** what that enemy carried. The `ThrowAmmo` hook links the enemy to its case: the case's
  BeginPlay fires inside `ThrowAmmo`.
  - Melee, mage and robot enemies: nothing. Robots are optional.
  - A sniper gives large rounds, everyone else medium rounds.
  - Bullet or laser follows `AmmoClass` when it says so; otherwise it keeps the game's random choice.
  - Rounds: those left in its magazine, scaled by caliber.
  - `SpareMagazineChance`: one more partial magazine. `NothingChance`: nothing usable.
  - With no enemy data, it keeps `FallbackShare` of the game's amount.
- **Crate:** `CrateShare` of each 100.
- **Loot:** `LootShare`.
- **Unknown sources (shops, rewards):** untouched, only clamped. You paid for them.

### Reload (`Reload.DropMagazine`)
When `Add Ammo` gets a negative amount while the player's weapon has `Reloading = true`, the hook runs
before the weapon fills its magazine. It does three things:
1. It reads the old magazine count `old` and the weapon slot.
2. It sets the slot's magazine to 0. The rounds in the dropped magazine are lost.
3. It takes `extra = min(old, reserve)` more from the pouch and adds it to the weapon's `Ammo_To_Add`.

The new magazine then holds `min(MagazineSize, reserve before)`, as when you insert a fresh magazine.
This does nothing when the magazine was empty.

### Pistols (`Pistols.LimitedAmmo`)
The off switch for slot 0's `InfiniteAmmo?` (for the slot and the weapon's `Weapon_Data`) lets pistols
use small rounds. Enemy cases sometimes contain sidearm rounds (`SidearmChance`). Checked in game before
it can be on by default (section 4).

### HUD
`TMWPerkWarning` on the player, the same as HTR and TE. The GUI_Cant alarm is muted for 2 s (`Messages.Quiet`).
- When ammo runs low after a reload: "Last magazine: 37 rifle rounds left" or "Out of spare rifle rounds".
- When a limit stops a pickup: "Pouch full: 240 rifle rounds".
- Pickups: "+18 rifle rounds" or "No usable ammo".
- Messages come at most once every 2 s, except the on/off message.

### Toggle
`Shift+0` (top-row zero). First choice was `Shift+P`: P is unbound in every preset. But the Ground
Waypoints session's scan of raw key events found `Q1Controller.InpActEvt_P_K2Node_InputKeyEvent_17`,
which runs the same code as Escape: it closes widgets such as the bank and the skip-tutorial popup.
Zero is free in both the presets and the raw events. Ground Waypoints takes plain 0, quiet with Shift,
so we use Shift+0. RegisterKeyBind with SHIFT was verified in game with Shift+P. Original note:
P was unbound in every game preset (on foot, ship, interface and shared;
checked in the `1_Keybings` dump) and in every mod of the set. Rule 4 of the key plan: a rare on/off
toggle uses Shift+key. The key is configurable. Keys the game uses itself are refused without a modifier.

### Hooks and cost
All hooks are post-hooks on Blueprint functions. They register lazily, by class, as in HTR and TE.
- `Game_Builder_C:Add Ammo`: pickups and reloads only.
- `Game_Builder_C:ReceiveBeginPlay`: arrival. It finds the Game_Builder and wakes the class lookups.
- `Q1_Shooter_AI_C:ThrowAmmo` and `AmmoThrowCase_C:ReceiveBeginPlay`: once per death.
- `AmmoThrowCase_C:Timeline_0__UpdateFunc` and `:Timeline_0__FinishedFunc`: about 1 s per case.
- `AmmoCrate_C:Opening__FinishedFunc` and `Master_Drop_Loot_C:Interact`: when used.

A failed class lookup costs about 37 ms. So enemies, crates and loot are looked up only for about a
minute after a wake, never forever. Wakes happen on arrival, on a reload and on an unknown pickup.
The 1 s poll reads the 8 pouch entries.

### Compatibility
- **HTR:** it sets the enemy magazine (`MaxAmmo`/`Ammo`); we read it at death. Calibers do not overlap.
- **Silent Ops:** it uses the weapon's `Reloading` flag to block firing while fitting a suppressor. We act
  only inside a reload's `Add Ammo`.
- **Tactical Engineering:** turret rounds live in TE's own state, not in `Game_Builder.Ammos`. Untouched.
- **Gear Without Levels:** no shared state.

## 3. Config defaults (realistic)
Rifle magazines in SB2 hold 50 to 100 rounds (`C_W_MAG = rand(40,60) + 10 x tier`); shotgun and sniper
magazines hold 10 to 30.
- Defaults give about 3 to 5 rifle magazines (240 rounds), a few reloads for shotguns (32 shells), and
  40 sniper rounds.
- Crates give 30 % (30 of each type).
- An enemy drops what was left in its magazine, so about 15 rifle rounds on average, with a 20 % chance
  of a spare magazine and a 25 % chance of nothing.

## 4. Test log

2026-10-31. Setup:
- Slot ADTest, a copy of the pretest backup's CheckPoint: the Holder station, on foot.
- Mods: HTR 0.4.8, Silent Ops, Split Controls, Gear Without Levels and SB2 HOTAS.
- The dev console drove the tests, with real key presses for R, 1, 2 and Shift+P.

Results:
- **Hooks:** all 8 registered at the menu or on arrival, the crate and loot classes included. No Lua
  errors.
- **Writing a struct inside `Game_Builder.Ammos` through `ForEach` / `elem:get()[field] = v` works.**
- **Limits on load:** the old save held 787 rifle rounds, 999 cells and so on. Each type was cut to
  its limit plus one carried magazine, for example rifle rounds 302 = 240 + the rifle's 62. One HUD line.
- **Shop-style pickup** (Lua `Add Ammo(1, 50)`) at 302: it stays 302, with no gain or loss, and shows
  "Pouch full: max 240 rifle rounds" on the HUD. Screenshot checked.
- **Reload with the real R key**, 10 rounds left, 62-round magazine:
  - 0.1.0-dev: the pouch went 302 → 230 instead of 240. The game's `Add Ammo` also clamps a negative
    add whose result is at or above `MaxCarryAmount`: 302 - 52 = 250 became 240.
  - The hook now restores the value the game meant, from the last known value. Rerun: 302 → 240,
    and the magazine holds 62 = a fresh one. "Magazine dropped: 10 rounds lost".
- **Enemy drops** (spawned shooter with `Ammo = 17`, `ThrowAmmo()` called five times, three cases
  spawned): the enemy was always known.
  - The game gave 65, 79, 52 and 50; Ammo Discipline gave 30 (pouch full), 39, 17 and 35. The game's
    shotgun shells became rifle rounds, of the type the enemy carried.
  - The flight hook costs about 0.02 ms per frame (314 calls, 7 ms in total).
- **Ammo crate** (spawned `AmmoCrate_C`, `Interact`): six types at 100 each became 30 each, within
  the limits. One HUD line with the totals.
- **Ammo loot** (`Ammo_C` with `AmmoAmount = 40`, `Interact`): it gave 20. A spawned `Ammo_C`
  without its drop setup has `AmmoAmount = 0`: the game then calls `Add Ammo(…, 0)` and writes its limit
  back, so 0-round adds now restore our limit too.
- **Shift+P with the real key** (the toggle key then; now Shift+0, same code path): OFF puts the vanilla limits back (999/125/99/299/999/999/99/299 by
  type); ON puts ours back. Both have HUD lines.
- **Pistols:** an infinite pistol's magazine counts below zero (-16 of 7 here). With
  `InfiniteAmmo? = false`, a reload took 23 pistol rounds. So the magazine is now set to 0 when the
  pistol becomes finite. Rerun: slot 0 at 0/7, finite.
- **Frames, idle, on foot:**

  | Run | fps | median | p99 | max | spikes |
  |---|---|---|---|---|---|
  | without the mod, game in front, 77 s | 107 | 9.0 ms | 16 ms | 39 ms | 1, at the start |
  | with the mod, game in front, 43 s | 109 | 9.0 ms | 16 ms | 22 ms | 0 |
  | with the mod, game in the background, 61 s | 93 | 11 ms | 23 ms | 27 ms | 0 |
  | with the mod, focus lost during the run, 61 s | 104 | 9.0 ms | 19 ms | 205 ms | 12, at the focus changes |

  - The spikes in the last run come in clusters 0.1 s apart, at the moments the window lost or got
    focus. They do not follow the mod's 1, 2 or 5 s rhythm.
  - Measured mod costs: `Add Ammo` at most 1 ms per call, on pickups and reloads only; the ammo-case
    flight about 0.02 ms per frame, for about 1 s per drop.
- **Not tested in game:** a real fight with kills (`ThrowAmmo` was called directly), a level-placed
  crate, shops, the robot and sniper paths of the drop rule, and the inventory weapon swap with the
  pouch full.
- **Windows lock screen:** while the PC was locked, the game died during start-up with no crash
  report. That is not related to the mod.
