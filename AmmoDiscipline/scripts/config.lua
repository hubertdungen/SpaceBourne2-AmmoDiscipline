--[[
  Ammo Discipline for SpaceBourne 2
  =================================
  USER SETTINGS. Edit with any text editor, then restart the game.
  Everything here is optional: delete a line and the default is used.
]]

return {
    -- false = the mod does nothing at all (not even the on/off key).
    Enabled = true,

    -- Ammo Discipline starts ON. false = start off (vanilla ammo until you press the key).
    StartOn = true,
    -- On/off key. UE4SS key name or digit, optionally with Shift: "Shift+0" (default: 0 is the top-row
    -- zero, which the game never uses; plain 0 belongs to Ground Waypoints). Keys the game uses itself
    -- (F1-F6, F8 quick load, F10, F11 fullscreen, F12) are refused without a modifier. "" = no key.
    ToggleKey = "Shift+0",

    -- Spare rounds you can carry, per ammo type (the rounds in your weapons come on top).
    -- The game's own limits are in brackets. Rifle magazines hold 50-100 rounds, shotgun and
    -- sniper magazines 10-30.
    Caps = {
        Medium_Bullet = 240, -- rifle and SMG rounds           (999)
        Medium_Laser  = 240, -- pulse rifle and beam SMG cells (999)
        Large_Bullet  = 40,  -- sniper and hunter rounds       (99)
        Large_Laser   = 60,  -- laser sniper and hunter cells  (125)
        Bullet_Shell  = 32,  -- shotgun shells                 (299)
        Laser_Shell   = 48,  -- laser shotgun cells            (99)
        Small_Bullet  = 60,  -- pistol rounds                  (999)
        Small_Laser   = 60,  -- laser pistol cells             (299)
    },
    -- Spare rounds above the limit (an old save with 999 rounds) are left behind, keeping one
    -- magazine of a weapon you carry on top (the inventory unloads a magazine when you swap weapons).
    -- Shown once on the HUD. false = keep them; pickups still stop at the limit.
    TrimToLimit = true,

    Scavenge = {
        -- Dead enemies give what they carried: the rounds left in their magazine, sometimes a spare
        -- magazine. A sniper gives heavy rounds, the others rifle rounds; melee fighters nothing.
        -- (Vanilla: 40-100 rounds of a random type from 70 % of the dead.)
        Enemies             = true,
        NothingChance       = 0.25, -- the body has nothing usable
        SpareMagazineChance = 0.20, -- one more partial magazine (bosses always)
        HeavyRoundsShare    = 0.30, -- a sniper's rifle-sized magazine count, as heavy rounds
        RobotsCarryAmmo     = false, -- robots have built-in weapons: nothing to take
        SidearmChance       = 0.20, -- their sidearm's rounds instead (with Pistols.LimitedAmmo)
        FallbackShare       = 0.25, -- share of the game's amount when the enemy is unknown

        Crates    = true, CrateShare = 0.30, -- ammo crates (vanilla: 100 of each type)
        Loot      = true, LootShare  = 0.50, -- ammo lying around
        -- Shops and rewards are never reduced (you paid); they only stop at the limit.
    },

    Reload = {
        -- Reloading drops the magazine in the weapon: the rounds left in it are lost, the new
        -- magazine comes from your pouch. false = vanilla (the rounds go back into the pouch).
        DropMagazine = true,
    },

    Pistols = {
        -- The game gives pistols infinite ammo. true = your pistol uses pistol rounds / cells from
        -- the pouch like the other guns (Caps.Small_*). Ammo crates have them, and dead enemies
        -- sometimes carry them (Scavenge.SidearmChance). false = infinite, as in the game.
        LimitedAmmo = true,
    },

    Messages = {
        LowAmmo         = true, -- "Last magazine: 37 rifle rounds left" / "Out of spare rifle rounds"
        PouchFull       = true, -- "Pouch full: 240 rifle rounds" (a limit stopped a pickup)
        Pickups         = true, -- "+18 rifle rounds" / "No usable ammo" from bodies, crates and loot
        DroppedMagazine = false, -- "Magazine dropped: 12 rounds lost" on every reload
        -- Our HUD lines use the game's warning; true = without its alarm sound (like HTR).
        Quiet = true,
    },

    Debug = { Log = false, SlowHookMs = 8 },
}
