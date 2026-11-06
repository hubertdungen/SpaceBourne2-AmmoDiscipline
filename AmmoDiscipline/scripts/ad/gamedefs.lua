--[[
  Every SpaceBourne 2 internal name Ammo Discipline depends on lives in this file.
  After a game update that renames something, this is the only file to fix.
  Names come from the game's Blueprints (UE 4.27, build of 2026-10-26).
]]

local G = {}

-- Classes ---------------------------------------------------------------------------
G.GameBuilder = "/Game/1Data/Game_Builder.Game_Builder_C"
G.Shooter     = "/Game/1Data/11_AI/Q1_Shooter_AI.Q1_Shooter_AI_C"
G.AmmoCase    = "/Game/1Data/11_AI/Miscs/AmmoThrowCase.AmmoThrowCase_C"         -- a dead enemy's ammo, flies to you
G.AmmoCrate   = "/Game/JUPITER_SciFi_Kit/Blueprints/AmmoCrate.AmmoCrate_C"       -- +100 of each listed type
G.DropLoot    = "/Game/1Data/Interactives/Loots/Master_Drop_Loot.Master_Drop_Loot_C" -- ammo lying around (Ammo_C)
G.HandWeapon  = "/Game/1Data/Weapons/Hand_Weapons/Weapons/Master_Hand_Weapon.Master_Hand_Weapon_C"
-- the empty-gun click (SoundWave): PlayOutOfAmmoSound plays it at most every 0.2 s while you fire an empty gun
G.DryClick    = "/Game/BallisticsVFX/SFX/Guns/Weapon_Empty_SoundFx.Weapon_Empty_SoundFx"

-- Hooked Blueprint functions (all post-hooks) ---------------------------------------------
G.Fn = {
    AddAmmo       = G.GameBuilder .. ":Add Ammo",          -- (RowName: byte, Amount: int, ByName: bool, Name: FName)
    Arrival       = G.GameBuilder .. ":ReceiveBeginPlay",
    ThrowAmmo     = G.Shooter .. ":ThrowAmmo",             -- enemy death; spawns the case inside (70 %)
    CaseBegin     = G.AmmoCase .. ":ReceiveBeginPlay",
    CaseUpdate    = G.AmmoCase .. ":Timeline_0__UpdateFunc",   -- adds when closer than 50 cm
    CaseFinished  = G.AmmoCase .. ":Timeline_0__FinishedFunc", -- or when its flight ends
    CrateOpened   = G.AmmoCrate .. ":Opening__FinishedFunc",
    LootInteract  = G.DropLoot .. ":Interact",
    DryFire       = G.HandWeapon .. ":PlayOutOfAmmoSound",
}

-- Ammo types: Bullet_Types_For_Easy_Add index (0-based) -> DataTable row, S_Ammo_Data.AmmoType, vanilla limit
G.Types = {
    { row = "Small_Bullet",  id = "S_B",          vanilla = 999, label = "pistol rounds" },
    { row = "Medium_Bullet", id = "Medium_Ammo",  vanilla = 999, label = "rifle rounds" },
    { row = "Large_Bullet",  id = "Large_Bullet", vanilla = 99,  label = "heavy rounds" },
    { row = "Bullet_Shell",  id = "Bullet_Shell", vanilla = 299, label = "shotgun shells" },
    { row = "Small_Laser",   id = "Small_Laser",  vanilla = 299, label = "pistol cells" },
    { row = "Medium_Laser",  id = "Medium_Laser", vanilla = 999, label = "rifle cells" },
    { row = "Large_Laser",   id = "Large_Laser",  vanilla = 125, label = "heavy cells" },
    { row = "Laser_Shell",   id = "Laser_Shell",  vanilla = 99,  label = "shotgun cells" },
}
G.TypeByRow, G.TypeById = {}, {}
for i, t in ipairs(G.Types) do
    t.index = i - 1
    G.TypeByRow[t.row] = t
    G.TypeById[t.id] = t
end

-- Properties (names exactly as in the Blueprints) ------------------------------------------
G.P = {
    -- Game_Builder
    Ammos = "Ammos",
    Slots = { [0] = "Slot_0_Weapon", [1] = "Slot_1_Weapon", [2] = "Slot_2_Weapon" },
    -- S_Ammo_Data
    AmmoId    = "AmmoType_2_DB8069AA44C4F43C8691AFA41192632C",
    Current   = "CurrentAmount_5_78023E324398D36A9CC7F8BB6C72EB6D",
    Max       = "MaxCarryAmount_7_058A3DA34197CD55DC25299BC2E81874",
    -- S_Equiped_HandWeapon (weapon slots)
    SlotMag      = "CurrentBulletsAtMagazine_29_7DD6CACE4B8BA345F6E63286D0156C31",
    SlotMagSize  = "MagazineSize_27_BE70725E45D1163A74BB4F9CA34B8893",
    SlotAmmoType = "AmmoType_24_E5BE60684E8885FD12CA8A97223BC8C7",   -- row name string ("Medium_Bullet")
    SlotInfinite = "InfiniteAmmo?_31_34F62E7C47FDE7E72B48C78D18C1D265",
    SlotType     = "Type_11_9A3B3E8748ADB495918633AC6122BA46",        -- "Pistol", "Rifle", ...
    -- player (Q1_Character_C) and hand weapon (Master_Hand_Weapon_C)
    CurrentWeapon = "CurrentWeapon",   -- ChildActorComponent
    Reloading     = "Reloading",
    WeaponIndex   = "WeaponIndex",
    MagazineSize  = "MagazineSize",
    AmmoToAdd     = "Ammo_To_Add",
    WeaponAmmoType= "AmmoType",        -- byte (type index)
    WeaponData    = "Weapon_Data",     -- copy of the slot made when the weapon is drawn
    -- shooter NPC
    NpcAmmo = "Ammo", NpcMaxAmmo = "MaxAmmo", NpcAmmoClass = "AmmoClass", SubType = "SubType",
    Sniper = "IsSniper?", Robot = "Robot?", Boss = "IsBoss",
    -- loot
    LootIsAmmo = "Ammo?",
    -- on-foot HUD: Curved_Widget_Test_C (a child of Ship_MainWidget_C). Its SubGoalText_7 shows the
    -- spare rounds; CustomEvent_13 is its handler for the game's "Reload" event: 2 s later it re-reads
    -- the spare rounds of the weapon in hand (Curved_Widget_Test ubergraph 53466 -> 5392 -> 3991)
    HudMain = "ShipMainWidget", HudCurved = "Curved_Widget_Test",   -- Q1Controller.ShipMainWidget
    HudRefresh = "CustomEvent_13",
}

-- Functions we call ----------------------------------------------------------------------
G.Call = { SetMagazine = "SetMagazinAtSarjor" } -- Game_Builder:SetMagazinAtSarjor(index, rounds)

G.SubType = { Shooter = 0, Tank = 1, Melee = 2, Mage = 3 }

return G
