--[[
  The pouch: carry limits, scavenging, reloads. See DESIGN.md in the repository.

  Every change to your spare rounds goes through Game_Builder:Add Ammo. Its post-hook runs before the
  caller continues, so:
    * a reload (negative amount) can still change the magazine the weapon is about to fill;
    * a pickup is recorded; the source's own post-hook (enemy ammo case, crate, loot) runs right
      after, in the same call, takes those rounds back and gives what that source should give.
  Pickups from anything else (shops, rewards) are only held to the limit.
]]

local U = require("ad.util")
local G = require("ad.gamedefs")
local GT = require("ad.gametick") -- timed work on the game thread (0.1.3: no ExecuteWithDelay)
local P = G.P

local M = {
    on = true,
    gb = nil,          -- the Game_Builder (re-checked with IsValid before each use)
    snap = {},         -- row -> spare rounds after our last change (fallback when the game clamped an add)
    recent = {},       -- pickups recorded by the Add Ammo hook, claimed by the source hook
    cases = {},        -- ammo case address -> { t, info }
    lastCase = nil,
    notified = {},     -- row -> true once the "left behind" line was shown on this map
}
local cfg
local SAME_CALL = 0.004 -- s: a source's post-hook runs microseconds after its own Add Ammo

function M.init(c)
    cfg = c
    M.on = c.StartOn ~= false
    math.randomseed(os.time())
end

-- Limits ----------------------------------------------------------------------------------
local function cap(t)
    local v = cfg.Caps[t.row]
    if type(v) == "number" and v >= 0 then return math.floor(v) end
    return t.vanilla
end

local function gameBuilder()
    if U.valid(M.gb) then return M.gb end
    M.gb = nil
    return nil
end

-- Calls fn(t, entry) for every pouch entry. entry is the live S_Ammo_Data inside Game_Builder.Ammos.
local function eachEntry(gb, fn)
    local arr = U.get(gb, P.Ammos, nil)
    if not arr then return end
    arr:ForEach(function(_, elem)
        local e = elem:get()
        local t = G.TypeById[U.str(U.get(e, P.AmmoId, ""))]
        if t then fn(t, e) end
    end)
end

local function entryOf(gb, t)
    local found
    eachEntry(gb, function(tt, e) if tt == t and not found then found = e end end)
    return found
end

-- Short type labels for HUD lines.
local function label(t) return t.label end

-- row -> magazine of the biggest weapon you carry that uses it: an unloaded magazine may sit on
-- top of a full pouch (the inventory unloads a weapon's magazine when you swap it).
local function carriedMagazines(gb)
    local m = {}
    for i = 0, 2 do
        local s = U.get(gb, P.Slots[i], nil)
        if s and U.get(s, P.SlotInfinite, false) ~= true then
            local row = U.str(U.get(s, P.SlotAmmoType, ""))
            m[row] = math.max(m[row] or 0, U.num(s, P.SlotMagSize, 0))
        end
    end
    return m
end

-- HUD lines ----------------------------------------------------------------------------------
-- Lines are collected during a call and shown a moment later (a source hook may still change the
-- result), at most one every 2 s; the newest wins.
local pending, flushScheduled, lastShown = nil, false, -1e9
local GAP = 5.0 -- s: a line stays about 5 s (ad/hudmsg.lua); the next one waits for it
local function flush()
    flushScheduled = false
    if not pending then return end
    local now = os.clock()
    if now - lastShown < GAP and not pending.force then
        flushScheduled = true
        GT.after(GAP - (now - lastShown) + 0.05, flush)
        return
    end
    local gb = gameBuilder()
    local pawn = gb and U.playerPawn(gb)
    if pawn and U.notify(pawn, pending.text, pending.force) then lastShown = now end
    pending = nil
end

function M.say(text, force)
    if not text then return end
    pending = { text = text, force = force }
    if not flushScheduled then
        flushScheduled = true
        GT.after(0.06, flush)
    end
end

-- The spare-rounds number on the HUD ------------------------------------------------------------
-- The game's on-foot HUD (Curved_Widget_Test) re-reads your spare rounds only 2 s after a reload
-- or when you draw a weapon, never after a pickup (vanilla too). Next to our "+30 rifle rounds"
-- line that looked as if nothing was given (TheCalcMan, 0.1.1). So after a pickup or a trim we
-- run the HUD's own reload handler (CustomEvent_13), which re-reads the count 2 s later with the
-- game's own code. (0.1.2 builds wrote the text from Lua; one test game closed right after that,
-- so the mod no longer makes any text itself.)

-- Finding that HUD widget. 0.1.1 went through Q1Hud's "Ship Main Widget" property, which is empty
-- on foot, so nothing was refreshed (TheCalcMan). The game keeps it on the player controller
-- (Q1Controller.ShipMainWidget, as Q1FunctionLibary:GetShipMainWidget reads it); the HUD is a child
-- of it. Direct references only: no search of all objects (test builds that searched closed the
-- game during loads).
local function hudWidget(pc)
    local main = U.valid(pc) and U.get(pc, P.HudMain, nil) or nil
    if not U.valid(main) then return nil end
    local w = U.get(main, P.HudCurved, nil)
    if U.valid(w) then return w end
    local ok, r = pcall(function() return main:GetWidgetFromName(FName(P.HudCurved)) end)
    return ok and U.valid(r) and r or nil
end

local hudScheduled, hudRetried = false, false
local pcPath -- the player controller found last time, found again by path (no search)
local function pathOf(o)
    local ok, full = pcall(function() return o:GetFullName() end)
    return ok and type(full) == "string" and full:match("^%S+%s+(.+)$") or nil
end
local function refreshHud()
    hudScheduled = false
    local gb = gameBuilder()
    local pc = pcPath and StaticFindObject(pcPath)
    local why = "no game builder"
    if not U.valid(pc) then
        pc = nil
        if gb then
            local ok, r = pcall(function() return U.gameplayStatics():GetPlayerController(gb, 0) end)
            if ok and U.valid(r) then pc = r else why = tostring(r) end
        end
    end
    if pc then pcPath = pathOf(pc) end
    local w = hudWidget(pc)
    if not w then
        U.log("HUD widget not found (" .. (pc and "no HUD under ShipMainWidget" or ("no player controller: " .. why)) .. ")")
        if not hudRetried then hudRetried = true; M.refreshHudSoon(600) end -- once more, a moment later
        return
    end
    hudRetried = false
    -- (Publisher, Payload, Metadata): the handler only stores them; any object will do
    local ok, err = pcall(function() w[P.HudRefresh](w, w, w, {}) end)
    U.log("HUD spare count refresh asked: " .. (ok and "ok" or tostring(err)))
end

-- After the source hook of the same call had its say (it may still change the pouch).
function M.refreshHudSoon(ms)
    if hudScheduled then return end
    hudScheduled = true
    GT.after((ms or 80) / 1000, refreshHud)
end

-- Give n rounds of type t, within the limit; never takes rounds away. Returns gained, full.
local function grant(gb, t, n)
    local e = entryOf(gb, t)
    if not e then
        if n <= 0 then return 0, false end
        -- no entry yet for this type: let the game create it (our own hook stays out), then hold it to the limit
        M.inside = true
        pcall(function() gb["Add Ammo"](gb, t.index, n, false, FName("None")) end)
        M.inside = false
        e = entryOf(gb, t)
        if not e then return 0, false end
        local now = U.num(e, P.Current, 0)
        if now > cap(t) then U.set(e, P.Current, cap(t)); now = cap(t) end
        U.set(e, P.Max, cap(t))
        M.snap[t.row] = now
        return now, now >= cap(t)
    end
    local before = U.num(e, P.Current, 0)
    local final = math.max(before, math.min(cap(t), before + math.max(0, n)))
    U.set(e, P.Current, final)
    U.set(e, P.Max, cap(t))
    M.snap[t.row] = final
    return final - before, before + n > final
end

-- Add Ammo ------------------------------------------------------------------------------------
local function typeOfCall(rowP, byNameP, nameP)
    if U.param(byNameP) == true then
        return G.TypeByRow[U.str(U.param(nameP))]
    end
    local r = U.param(rowP)
    if type(r) ~= "number" then return nil end
    return G.Types[r + 1]
end

local function onReload(gb, t)
    local pawn = U.playerPawn(gb)
    local comp = pawn and U.get(pawn, P.CurrentWeapon, nil)
    local w = comp and U.get(comp, "ChildActor", nil)
    if not U.valid(w) or U.get(w, P.Reloading, false) ~= true then return end
    if U.num(w, P.WeaponAmmoType, -1) ~= t.index then return end
    local idx = U.num(w, P.WeaponIndex, -1)
    local slot = P.Slots[idx] and U.get(gb, P.Slots[idx], nil)
    local e = entryOf(gb, t)
    if not (slot and e) then return end
    local old = U.num(slot, P.SlotMag, 0)
    local spare = U.num(e, P.Current, 0)
    local lost = 0
    if cfg.Reload.DropMagazine and old > 0 then
        -- the old magazine is dropped: the new one is filled from the pouch alone
        local extra = math.min(old, spare)
        if extra > 0 then
            U.set(e, P.Current, spare - extra)
            spare = spare - extra
            U.set(w, P.AmmoToAdd, U.num(w, P.AmmoToAdd, 0) + extra)
        end
        pcall(function() gb[G.Call.SetMagazine](gb, idx, 0) end)
        lost = old
    end
    M.snap[t.row] = spare
    local m = cfg.Messages
    local magSize = U.num(w, P.MagazineSize, 0)
    if m.LowAmmo and spare <= 0 then
        M.say("Out of spare " .. label(t))
    elseif m.LowAmmo and magSize > 0 and spare < magSize then
        M.say(string.format("Last magazine: %d %s left", spare, label(t)))
    elseif m.DroppedMagazine and lost > 0 then
        M.say(string.format("Magazine dropped: %d rounds lost", lost))
    end
    U.log(string.format("reload %s: old magazine %d (%s), spare now %d", t.row, old, lost > 0 and "dropped" or "kept", spare))
end

function M.onAddAmmo(selfP, rowP, amountP, byNameP, nameP)
    if not M.on or M.inside then return end
    local gb = U.param(selfP)
    if not U.valid(gb) then return end
    M.gb = gb
    local t = typeOfCall(rowP, byNameP, nameP)
    local amount = U.param(amountP)
    if not t or type(amount) ~= "number" then return end
    local e = entryOf(gb, t)
    if not e then return end
    local c = cap(t)
    if amount <= 0 then
        U.set(e, P.Max, c) -- the game wrote its own limit back
        if amount == 0 then return end
        -- The game clamps any add that ends at or above the limit, a reload too: from a pouch above
        -- the limit (an unloaded magazine on top) it would take more than it put in the weapon.
        local after, before = U.num(e, P.Current, 0), M.snap[t.row]
        if before and after >= c and before + amount > after then U.set(e, P.Current, before + amount) end
        if M.wake then M.wake() end -- a fight: look for enemies and their ammo cases
        onReload(gb, t)
        return
    end
    local after = U.num(e, P.Current, 0)
    local before
    if after < c then
        before = math.max(0, after - amount)                   -- the game did not clamp: exact
    else
        -- Clamped: the last value we saw. Without one (just after a load) assume nothing was
        -- added, so taking the add back can never cost rounds (0.1.0 used after - amount here,
        -- which could take rounds away from a pouch near its limit).
        before = M.snap[t.row] or after
    end
    local final = math.max(before, math.min(c, before + amount)) -- a pickup never takes rounds away
    if final ~= after then U.set(e, P.Current, final) end
    U.set(e, P.Max, c) -- the game wrote its own limit back
    M.snap[t.row] = final
    local now = os.clock()
    -- forget old records
    for i = #M.recent, 1, -1 do
        if now - M.recent[i].time > 1 then table.remove(M.recent, i) end
    end
    local rec = { t = t, amount = amount, before = before, final = final, time = now }
    M.recent[#M.recent + 1] = rec
    -- unclaimed after the call: a source we do not know; look for crates and loot again
    GT.after(0.06, function()
        for _, r in ipairs(M.recent) do
            if not r.claimed and os.clock() - r.time < 1 then
                if M.wake then M.wake() end
                return
            end
        end
    end)
    U.log(string.format("+%d %s: %d -> %d", amount, t.row, before, final))
    rec.time = os.clock() -- after the log: a slow log write must not hide this add from its source
    -- "Pouch full" only if no source took the add back (a dead enemy's case first takes it all back,
    -- then gives its own rounds; test 10 showed the line anyway)
    if cfg.Messages.PouchFull and before + amount > final then
        GT.after(0.04, function()
            if not rec.claimed then M.say(string.format("Pouch full: max %d %s", c, label(t))) end
        end)
    end
    M.refreshHudSoon()
end

-- Sources ---------------------------------------------------------------------------------------
-- The pickups recorded during the current call (newest first), claimed and taken back.
local function takeBack(gb, window)
    local now, list = os.clock(), {}
    for i = #M.recent, 1, -1 do
        local r = M.recent[i]
        if not r.claimed and now - r.time <= (window or SAME_CALL) then
            r.claimed = true
            list[#list + 1] = r
        end
    end
    for _, r in ipairs(list) do -- newest first, so repeated adds of one type end at the first "before"
        local e = entryOf(gb, r.t)
        if e then
            U.set(e, P.Current, r.before)
            M.snap[r.t.row] = r.before
        end
    end
    return list
end

local function summary(gains)
    local parts = {}
    for _, g in ipairs(gains) do
        if g.n > 0 then parts[#parts + 1] = string.format("+%d %s", g.n, label(g.t)) end
    end
    return table.concat(parts, ", ")
end

-- What a dead enemy carried: the rounds left in its magazine, maybe a spare one.
local function npcInfo(npc)
    local info = {
        left = U.num(npc, P.NpcAmmo, -1), mag = U.num(npc, P.NpcMaxAmmo, 0), sub = U.num(npc, P.SubType, 0),
        sniper = U.get(npc, P.Sniper, false) == true, robot = U.get(npc, P.Robot, false) == true,
        boss = U.get(npc, P.Boss, false) == true,
    }
    local cls = U.get(npc, P.NpcAmmoClass, nil)
    local name = ""
    if cls then
        local ok, n = pcall(function() return cls:GetFName():ToString() end)
        name = ok and n or ""
    end
    if name:find("Lazer") or name:find("Laser") then info.laser = true
    elseif name:find("Bullet") then info.laser = false end
    return info
end

function M.onCaseBegin(selfP)
    if not M.on then return end
    local case = U.param(selfP)
    local a = U.addr(case)
    if not a then return end
    local c = { t = os.clock() }
    M.cases[a] = c
    M.lastCase = c
end

function M.onThrowAmmo(selfP)
    if not M.on then return end
    local c = M.lastCase
    -- the case spawns inside ThrowAmmo (70 % of deaths): its BeginPlay ran just before this
    if not (c and not c.info and os.clock() - c.t <= SAME_CALL) then return end
    c.info = npcInfo(U.param(selfP))
end

local function caseRounds(info, gameT, gameAmount)
    local sc = cfg.Scavenge
    if math.random() < sc.NothingChance then return nil, 0 end
    if not info then
        return gameT, math.floor(gameAmount * sc.FallbackShare + 0.5)
    end
    if info.sub == G.SubType.Melee or info.sub == G.SubType.Mage then return nil, 0 end
    if info.robot and not sc.RobotsCarryAmmo then return nil, 0 end
    local laser = info.laser
    if laser == nil then laser = gameT.index >= 4 end
    local mag = info.mag > 0 and info.mag or 30
    if cfg.Pistols.LimitedAmmo and math.random() < sc.SidearmChance then
        local t = G.TypeByRow[laser and "Small_Laser" or "Small_Bullet"]
        return t, math.random(1, math.max(1, math.floor(mag / 3)))
    end
    local rounds = info.left
    if rounds < 0 or rounds > mag then rounds = math.random(0, mag) end
    if info.boss or math.random() < sc.SpareMagazineChance then rounds = rounds + math.random(math.floor(mag / 2), mag) end
    local row
    if info.sniper then
        row = laser and "Large_Laser" or "Large_Bullet"
        rounds = rounds * sc.HeavyRoundsShare
    else
        row = laser and "Medium_Laser" or "Medium_Bullet"
    end
    return G.TypeByRow[row], math.floor(rounds + 0.5)
end

-- AmmoThrowCase: Timeline_0__UpdateFunc / __FinishedFunc (the add happens inside one of them)
function M.onCase(selfP)
    if not (M.on and cfg.Scavenge.Enemies) then return end
    if #M.recent == 0 then return end -- every frame of the flight: nothing to do
    local gb = gameBuilder()
    if not gb then return end
    local list = takeBack(gb)
    if #list == 0 then return end
    local a = U.addr(U.param(selfP))
    local c = a and M.cases[a]
    if a then M.cases[a] = nil end
    local r = list[#list]
    local t, n = caseRounds(c and c.info, r.t, r.amount)
    local gained, full = 0, false
    if t and n > 0 then gained, full = grant(gb, t, n) end
    if not cfg.Messages.Pickups then return end
    if gained > 0 then
        M.say(string.format("+%d %s", gained, label(t)) .. (full and " (pouch full)" or ""))
    elseif t and n > 0 then
        M.say(string.format("Pouch full: max %d %s", cap(t), label(t)))
    else
        M.say("No usable ammo")
    end
    U.log(string.format("enemy case: game gave %d %s; now %s %d (%s)", r.amount, r.t.row, t and t.row or "-", n,
        c and c.info and "enemy known" or "enemy unknown"))
end

-- Crates and ammo lying around give a share of your carry limit for that type, give or take a
-- quarter, never more than the game's own amount. 0.1.1 gave a share of the game's amount (100 per
-- crate, 88-114 on the ground), which filled a 32-shell or 40-round pouch in one go (user, 0.1.2).
local function shareOfLimit(t, share, gameAmount)
    local n = math.floor(cap(t) * share * (0.75 + math.random() * 0.5) + 0.5)
    return math.max(1, math.min(n, gameAmount))
end

local function shareSource(selfP, share, what)
    local gb = gameBuilder()
    if not gb then return end
    local list = takeBack(gb, 0.25) -- crates and loot: all their adds come within one frame
    U.log(string.format("%s: %d adds claimed", what, #list))
    if #list == 0 then return end
    local gains = {}
    for i = #list, 1, -1 do -- oldest first
        local r = list[i]
        local gained = grant(gb, r.t, shareOfLimit(r.t, share, r.amount))
        gains[#gains + 1] = { t = r.t, n = gained }
    end
    if cfg.Messages.Pickups then
        local s = summary(gains)
        M.say(what .. ": " .. (s ~= "" and s or "pouch full"))
    end
    return true
end

function M.onCrateOpened(selfP)
    if not (M.on and cfg.Scavenge.Crates) then return end
    if shareSource(selfP, cfg.Scavenge.CrateShare, "Ammo crate") then return end
    -- nothing to claim yet: look again once the lid's call is over (test 10: a crate gave +100)
    GT.after(0.1, function() shareSource(nil, cfg.Scavenge.CrateShare, "Ammo crate") end)
end

function M.onLoot(selfP)
    if not (M.on and cfg.Scavenge.Loot) or #M.recent == 0 then return end
    local loot = U.param(selfP)
    if U.get(loot, P.LootIsAmmo, false) ~= true then return end
    shareSource(selfP, cfg.Scavenge.LootShare, "Ammo")
end

-- Arrival somewhere new (Game_Builder:ReceiveBeginPlay) ------------------------------------------
function M.onArrival(selfP)
    local gb = U.param(selfP)
    if U.valid(gb) then M.gb = gb end
    M.snap, M.recent, M.cases, M.lastCase, M.notified = {}, {}, {}, nil, {}
    M.applyAt = os.clock() + 8 -- let the save load first
    if M.wake then M.wake() end
end

-- Pistols -------------------------------------------------------------------------------------------
local function setPistolInfinite(gb, infinite)
    local s = U.get(gb, P.Slots[0], nil)
    if s and U.get(s, P.SlotInfinite, nil) ~= infinite then
        U.set(s, P.SlotInfinite, infinite)
        -- an infinite pistol's magazine counts down below 0 forever; start the finite one from empty
        if not infinite and U.num(s, P.SlotMag, 0) < 0 then pcall(function() gb[G.Call.SetMagazine](gb, 0, 0) end) end
    end
    local pawn = U.playerPawn(gb)
    local comp = pawn and U.get(pawn, P.CurrentWeapon, nil)
    local w = comp and U.get(comp, "ChildActor", nil)
    if U.valid(w) and U.num(w, P.WeaponIndex, -1) == 0 then
        local d = U.get(w, P.WeaponData, nil)
        if d and U.get(d, P.SlotInfinite, nil) ~= infinite then U.set(d, P.SlotInfinite, infinite) end
    end
end

-- Poll (1 s) and switching -------------------------------------------------------------------------
-- While on: limits written into the pouch, spare rounds above limit + one carried magazine left behind.
local function applyLimits(gb)
    local trimmed = {}
    local mags = cfg.TrimToLimit and carriedMagazines(gb) or {}
    eachEntry(gb, function(t, e)
        local c = cap(t)
        if U.num(e, P.Max, -1) ~= c then U.set(e, P.Max, c) end
        local cur = U.num(e, P.Current, 0)
        if cfg.TrimToLimit then
            local keep = c + (mags[t.row] or 0)
            if cur > keep then
                U.set(e, P.Current, keep)
                trimmed[#trimmed + 1] = { t = t, n = cur - keep }
                cur = keep
            end
        end
        M.snap[t.row] = cur
    end)
    for _, x in ipairs(trimmed) do
        U.log(string.format("left behind %d %s (limit %d)", x.n, x.t.row, cap(x.t)))
    end
    if #trimmed > 0 and cfg.Messages.PouchFull and not M.notified.trim then
        M.notified.trim = true
        M.say("Carry limits: spare ammo above them left behind")
    end
    if #trimmed > 0 then M.refreshHudSoon() end
end

local function restoreVanilla(gb)
    eachEntry(gb, function(t, e) U.set(e, P.Max, t.vanilla) end)
    if cfg.Pistols.LimitedAmmo then setPistolInfinite(gb, true) end
end

local nextApply = 0
function M.poll(now)
    local gb = gameBuilder()
    if not gb then return end
    if M.on then
        if now >= nextApply and now >= (M.applyAt or 0) then
            nextApply = now + 2
            applyLimits(gb)
        elseif now < (M.applyAt or 0) then
            -- while the save settles: remember what the pouch holds, for a pickup in those seconds
            eachEntry(gb, function(t, e)
                if M.snap[t.row] == nil then M.snap[t.row] = U.num(e, P.Current, 0) end
            end)
        end
        if cfg.Pistols.LimitedAmmo then setPistolInfinite(gb, false) end
    end
    for a, c in pairs(M.cases) do
        if now - c.t > 20 then M.cases[a] = nil end
    end
end

function M.setOn(v)
    M.on = v
    local gb = gameBuilder()
    if gb then
        if v then nextApply = 0 else restoreVanilla(gb) end
    end
    M.say(v and "Ammo Discipline ON" or "Ammo Discipline OFF (vanilla ammo)", true)
    U.warn("switched " .. (v and "ON" or "OFF"))
end

function M.status()
    local gb = gameBuilder()
    if not gb then return "no Game_Builder yet" end
    local parts = {}
    eachEntry(gb, function(t, e)
        parts[#parts + 1] = string.format("%s %d/%d", t.row, U.num(e, P.Current, -1), U.num(e, P.Max, -1))
    end)
    return (M.on and "ON" or "OFF") .. " | " .. table.concat(parts, ", ")
end

-- Dry fire ---------------------------------------------------------------------------------------
-- Holding the trigger on an empty gun, the game clicks every 0.2 s (PlayOutOfAmmoSound). In vanilla
-- that hardly ever happens (999 rounds, endless pistol); with real limits it became a constant
-- "tututu" (user, 0.1.2). Now the first click plays, then the click is muted until 0.6 s pass without
-- one: one click per trigger pull. Same volume trick as the HUD alarm in util.lua.
local dryVolume, lastDry, dryMuted = nil, 0, false
local function dryCheck()
    if os.clock() - lastDry < 0.6 then
        GT.after(0.3, dryCheck)
        return
    end
    local s = StaticFindObject(G.DryClick)
    if U.valid(s) and dryVolume then pcall(function() s.Volume = dryVolume end) end
    dryMuted = false
end

function M.onDryFire()
    if not M.on then return end
    lastDry = os.clock()
    if dryMuted then return end
    local snd = StaticFindObject(G.DryClick)
    if not U.valid(snd) then return end
    if dryVolume == nil then
        local ok, v = pcall(function() return snd.Volume end)
        if not (ok and type(v) == "number" and v > 0) then return end
        dryVolume = v
    end
    dryMuted = true
    pcall(function() snd.Volume = 0.0 end)
    GT.after(0.7, dryCheck)
end

return M
