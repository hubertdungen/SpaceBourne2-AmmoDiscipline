--[[
  Ammo Discipline for SpaceBourne 2 - realistic ammo limits and scavenging.
  Idea: TheCalcMan (Steam). UE4SS Lua mod. Entry point: settings, hooks, the on/off key.

  Layout:
    config.lua       user settings
    ad/gamedefs.lua  every game-internal name (the only file to fix after a game patch)
    ad/util.lua      helpers (logging, safe property access, HUD messages)
    ad/hooks.lua     safe lazy hook registration (same design as HTR's)
    ad/pouch.lua     carry limits, scavenging, reloads
  Design notes and the test log: DESIGN.md in the repository.
]]

local VERSION = "0.1.2"

local U = require("ad.util")

-- Settings -------------------------------------------------------------------------------
local defaults = {
    Enabled = true, StartOn = true, ToggleKey = "Shift+0", TrimToLimit = true,
    Caps = { Medium_Bullet = 240, Medium_Laser = 240, Large_Bullet = 40, Large_Laser = 60, Bullet_Shell = 32,
        Laser_Shell = 48, Small_Bullet = 60, Small_Laser = 60 },
    Scavenge = { Enemies = true, NothingChance = 0.25, SpareMagazineChance = 0.20, HeavyRoundsShare = 0.30,
        RobotsCarryAmmo = false, SidearmChance = 0.20, FallbackShare = 0.25,
        Crates = true, CrateShare = 0.25, Loot = true, LootShare = 0.15 },
    Reload = { DropMagazine = true, OneDryClick = true },
    Pistols = { LimitedAmmo = true },
    Messages = { LowAmmo = true, PouchFull = true, Pickups = false, DroppedMagazine = false, Quiet = true },
    Debug = { Log = false, SlowHookMs = 8 },
}

local function fill(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = v
        elseif type(v) == "table" and type(dst[k]) == "table" then
            fill(dst[k], v)
        end
    end
end

local okCfg, cfg = pcall(require, "config")
if not okCfg or type(cfg) ~= "table" then
    U.warn("config.lua could not be read (" .. tostring(cfg) .. "); using defaults")
    cfg = {}
end
fill(cfg, defaults)
U.Verbose = cfg.Debug.Log == true
require("ad.hudmsg").Quiet = cfg.Messages.Quiet ~= false

if cfg.Enabled == false then
    U.warn("Ammo Discipline " .. VERSION .. " loaded, disabled in config.lua (Enabled = false)")
    return
end

AMMO_DISCIPLINE = { version = VERSION, cfg = cfg }

local H = require("ad.hooks")
H.SLOW = cfg.Debug.SlowHookMs / 1000
local G = require("ad.gamedefs")
local M = require("ad.pouch")
M.init(cfg)
M.wake = H.wake
AMMO_DISCIPLINE.pouch = M

-- Hooks (post-hooks on Blueprint functions; each returns at once while the mod is off) ---------
H.add(G.Fn.AddAmmo, M.onAddAmmo, "add ammo")
H.add(G.Fn.Arrival, M.onArrival, "arrival")
if cfg.Scavenge.Enemies then
    H.add(G.Fn.ThrowAmmo, M.onThrowAmmo, "enemy drops ammo", "wake")
    H.add(G.Fn.CaseBegin, M.onCaseBegin, "ammo case spawned", "wake")
    H.add(G.Fn.CaseUpdate, M.onCase, "ammo case flight", "wake")
    H.add(G.Fn.CaseFinished, M.onCase, "ammo case landed", "wake")
end
if cfg.Scavenge.Crates then H.add(G.Fn.CrateOpened, M.onCrateOpened, "ammo crate", "wake") end
if cfg.Scavenge.Loot then H.add(G.Fn.LootInteract, M.onLoot, "ammo loot", "wake") end
if cfg.Reload.OneDryClick then H.add(G.Fn.DryFire, M.onDryFire, "dry fire") end

U.warn(string.format("=== Ammo Discipline %s loaded: %s, key %s ===", VERSION, M.on and "ON" or "OFF",
    cfg.ToggleKey ~= "" and cfg.ToggleKey or "none"))

-- Poll --------------------------------------------------------------------------------------------
local lastStatus, profileAt = "", os.clock() + 30
LoopAsync(1000, function()
    ExecuteInGameThread(function()
        local now = os.clock()
        local ok, err = pcall(function()
            H.poll(now)
            M.poll(now)
        end)
        if not ok then U.warn("poll: " .. tostring(err)) end
        if U.Verbose and now > profileAt then
            profileAt = now + 30
            local prof = H.profile()
            if prof ~= "" then U.log("profile 30 s: " .. prof) end
        end
        local on, off = H.status()
        local s = string.format("hooks active %d, waiting %d", on, off)
        if s ~= lastStatus then lastStatus = s; U.log(s) end
    end)
    return false
end)

-- On/off key ----------------------------------------------------------------------------------------
-- Realism set key plan: only Shift as a modifier; keys the game uses are refused without one; a
-- plain key stays quiet while Shift/Ctrl/Alt is held.
local GAME_KEYS = { F1 = 1, F2 = 1, F3 = 1, F4 = 1, F5 = 1, F6 = 1, F8 = 1, F10 = 1, F11 = 1, F12 = 1 }
local KEY_ALIAS = { INSERT = "INS", DELETE = "DEL", PAGEDOWN = "PAGE_DOWN", PAGEUP = "PAGE_UP", ESC = "ESCAPE",
    ["0"] = "ZERO", ["1"] = "ONE", ["2"] = "TWO", ["3"] = "THREE", ["4"] = "FOUR", ["5"] = "FIVE", ["6"] = "SIX",
    ["7"] = "SEVEN", ["8"] = "EIGHT", ["9"] = "NINE" }
local MODS = { CTRL = "CONTROL", CONTROL = "CONTROL", SHIFT = "SHIFT", ALT = "ALT" }
local function parseKey(spec)
    if type(spec) ~= "string" or spec == "" then return nil end
    local mods, key = {}, nil
    for part in spec:upper():gsub("%s", ""):gmatch("[^+]+") do
        if MODS[part] then mods[#mods + 1] = MODS[part] else key = KEY_ALIAS[part] or part end
    end
    if not (key and Key and Key[key]) then return nil, "unknown key" end
    if #mods == 0 and GAME_KEYS[key] then return nil, "the game uses " .. key end
    return key, mods
end

local function toggle() M.setOn(not M.on) end

local key, mods = parseKey(cfg.ToggleKey)
if not key and cfg.ToggleKey ~= "" then
    U.warn(string.format("toggle key '%s' not usable (%s); using Shift+0", tostring(cfg.ToggleKey), tostring(mods)))
    key, mods = parseKey("Shift+0")
end
if key then
    if #mods > 0 and ModifierKey then
        local list = {}
        for _, m in ipairs(mods) do list[#list + 1] = ModifierKey[m] end
        RegisterKeyBind(Key[key], list, function() ExecuteInGameThread(toggle) end)
    else
        RegisterKeyBind(Key[key], function()
            ExecuteInGameThread(function() if not U.modifierDown() then toggle() end end)
        end)
    end
end
