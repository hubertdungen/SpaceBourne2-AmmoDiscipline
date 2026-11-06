# Changelog

## 0.1.3 (2026-11-06)

- **Fix: a "Fatal Error!" crash that could come at any moment.** The mod's timed work (the pouch
  checks, HUD refreshes and on-screen lines) ran on a UE4SS background thread. When two mods of the
  set did that at the same moment, UE4SS's own bookkeeping broke and the game crashed. All of it now
  runs on the game's own thread, driven by the game's tick (the same fix in every mod of the
  realism set).
- Tested in game with the whole realism set (13 mods together, a few minutes on foot): no crash,
  and every mod's timed work ran.

## 0.1.2 (2026-11-06)

Thanks to **TheCalcMan** (Steam) for the reports.

- **The ammo counter follows your pickups (for real this time).** 0.1.1 looked for the HUD in the
  wrong place on foot, so the number still changed only on your next reload. Now the HUD re-reads
  your spare rounds right after each pickup.
- **Crates and loot no longer fill you up.** A crate gives about a quarter of your limit for each
  type (about 60 rifle rounds, 8 shotgun shells), ammo lying around about 15 % (about 36 rifle
  rounds), give or take a quarter. 0.1.1 gave a share of the game's own amount, which filled a
  shotgun or sniper pouch in one go.
- **No more "tututu".** The game's HUD beeped on every Ammo Discipline line. The lines are now
  silent, stay about 5 seconds, and the same line shows at most once in 30 seconds. The
  "+18 rifle rounds" line for each pickup is off by default (`Messages.Pickups`): the counter shows it.
- **One click on an empty gun.** Holding the trigger on an empty gun clicked five times a second;
  now it clicks once per trigger pull (`Reload.OneDryClick`).
- A dead enemy's ammo case no longer shows "Pouch full" for rounds you did not get.
- Tested in game with HTR 0.4.11, Silent Ops 0.3.2 and Gear Without Levels 0.1.1.

## 0.1.1 (2026-11-01)

Thanks to **TheCalcMan** (Steam) for the report.

- **The ammo counter now goes up when you pick ammo up.** The game only refreshes the spare-rounds
  number on the HUD after a reload or when you draw a weapon, so "+30 rifle rounds" showed but the
  number stayed the same until your next reload. The rounds were in your pouch all along; now the
  number changes right away.
- **A pickup can no longer cost you rounds just after loading a save.** In the first seconds after a
  load, a crate or a body could leave a nearly full pouch with fewer rounds than before.
- Install section: the realism set installer first, the manual install second.

## 0.1.0 (2026-10-31)

First release. Idea: **TheCalcMan** (Steam).

- **Carry limits per ammo type.** Rifle rounds and cells 240, sniper rounds 40, laser sniper cells 60,
  shotgun shells 32, laser shotgun cells 48, pistol rounds and cells 60. Pickups stop at the limit.
  Extra rounds on an old save are left behind once, keeping one magazine on top.
- **Dead enemies give what they carried.** You get the rounds left in their magazine, sometimes a
  spare magazine, and sometimes nothing. A sniper gives heavy rounds, melee fighters and robots
  nothing. The game gave 40 to 100 random rounds.
- **Crates and loot give less.** Crates give 30 % and ammo lying around 50 %. Shops are untouched.
- **Reloading drops the magazine.** The rounds left in it are lost.
- **Pistols need ammo.** They use pistol rounds or cells from the pouch.
- **HUD lines**, without the alarm sound:
  - last magazine, out of spare rounds;
  - pouch full;
  - what you scavenged.
- **Shift+0** (top-row zero) switches it on or off. It is on by default.
- Tested in game with HTR 0.4.8, Silent Ops, Split Controls, Gear Without Levels and SB2 HOTAS
  (see DESIGN.md, section 4).
