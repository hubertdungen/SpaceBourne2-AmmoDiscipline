# Changelog

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
