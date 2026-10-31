--[[
  Shared helpers, adapted from Tactical Engineering's te/util.lua (same safety rules as HTR):
   * Game objects are only touched inside hook callbacks or the 1 s poll, always through pcall.
   * Post-hooks on Blueprint functions only. No FindAllOf; FindFirstOf only once, on a key press.
]]

local U = {}

-- Mod folder (UE4SS may report ...\Scripts\ or ...\scripts\).
do
    local src = debug.getinfo(1, "S").source:gsub("^@", "")
    local lower = src:lower()
    local cut
    for i in lower:gmatch("()[\\/]scripts[\\/]") do cut = i end
    U.Dir = cut and src:sub(1, cut) or ".\\Mods\\AmmoDiscipline\\"
end
U.LogFile = U.Dir .. "ad.log"
U.Verbose = false

function U.log(...)
    if not U.Verbose then return end
    local t = {}
    for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
    local f = io.open(U.LogFile, "a")
    if f then f:write(os.date("%H:%M:%S "), table.concat(t, " "), "\n"); f:close() end
end

-- Always printed (UE4SS.log) and logged.
function U.warn(...)
    local t = {}
    for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
    local msg = table.concat(t, " ")
    print("[AmmoDiscipline] " .. msg .. "\n")
    local f = io.open(U.LogFile, "a")
    if f then f:write(os.date("%H:%M:%S "), "WARN ", msg, "\n"); f:close() end
end

function U.valid(o)
    if o == nil then return false end
    local ok, v = pcall(function() return o:IsValid() end)
    return ok and v == true
end

function U.addr(o)
    local ok, a = pcall(function() return o:GetAddress() end)
    return ok and a or nil
end

function U.className(o)
    if not U.valid(o) then return nil end
    local ok, n = pcall(function() return o:GetClass():GetFName():ToString() end)
    return ok and n or nil
end

function U.get(o, prop, default)
    local ok, v = pcall(function() return o[prop] end)
    if ok and v ~= nil then return v end
    return default
end

function U.set(o, prop, value)
    return pcall(function() o[prop] = value end)
end

function U.num(o, prop, default)
    local v = U.get(o, prop, nil)
    if type(v) == "number" then return v end
    return default
end

-- Hook parameter value (RemoteUnrealParam) or nil.
function U.param(p)
    if p == nil then return nil end
    local ok, v = pcall(function() return p:get() end)
    if ok then return v end
    return nil
end

-- FString / FName / FText to a Lua string ("" on failure).
function U.str(v)
    if type(v) == "string" then return v end
    if v == nil then return "" end
    local ok, s = pcall(function() return v:ToString() end)
    return (ok and type(s) == "string") and s or ""
end

function U.clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end

local GS
function U.gameplayStatics()
    if not U.valid(GS) then GS = StaticFindObject("/Script/Engine.Default__GameplayStatics") end
    return GS
end

-- The player's pawn from any live object in the world (instant engine call).
function U.playerPawn(ctx)
    if ctx == nil then return nil end
    local ok, p = pcall(function() return U.gameplayStatics():GetPlayerPawn(ctx, 0) end)
    if ok and U.valid(p) then return p end
    return nil
end

-- Is Shift, Ctrl or Alt held right now? Asked of the game's own input (HTR 0.4.4's rule 3 of the
-- key plan). Key presses only: the first call looks the controller up (~50 ms, once).
local PC
local MOD_KEYS = { "LeftShift", "RightShift", "LeftControl", "RightControl", "LeftAlt", "RightAlt" }
function U.modifierDown()
    if not U.valid(PC) then PC = FindFirstOf("PlayerController") end
    if not U.valid(PC) then return false end
    for _, k in ipairs(MOD_KEYS) do
        local ok, down = pcall(function() return PC:IsInputKeyDown({ KeyName = FName(k) }) end)
        if ok and down then return true end
    end
    return false
end

-- The HUD warning plays the game's "can't do that" alarm (GUI_Cant). Like HTR 0.4.6 and TE, with
-- U.Quiet that one sound is muted for 2 s around our own messages; the game's own warnings keep it.
-- The set agrees on its normal volume through the shared variable "SB2R_CantVolume".
local CANT = "/Game/11Misc/LGUI/Audio/GUI_Cant.GUI_Cant"
local CANT_NORMAL = 2.0
local cantVolume, unmuteAt = nil, 0
local function muteAlarm()
    if not U.Quiet then return end
    local snd = StaticFindObject(CANT) -- loaded with the HUD
    if not U.valid(snd) then return end
    if cantVolume == nil then
        local okS, shared = pcall(function() return ModRef and ModRef:GetSharedVariable("SB2R_CantVolume") end)
        if okS and type(shared) == "number" and shared > 0 then
            cantVolume = shared
        else
            local ok, v = pcall(function() return snd.Volume end)
            if not (ok and type(v) == "number") then return end
            cantVolume = (v > 0) and v or CANT_NORMAL
            pcall(function() ModRef:SetSharedVariable("SB2R_CantVolume", cantVolume) end)
        end
    end
    pcall(function() snd.Volume = 0.0 end)
    unmuteAt = os.clock() + 2.0
    ExecuteWithDelay(2100, function()
        ExecuteInGameThread(function()
            if os.clock() < unmuteAt then return end
            local s = StaticFindObject(CANT)
            if U.valid(s) and cantVolume then pcall(function() s.Volume = cantVolume end) end
        end)
    end)
end

-- On-screen line on foot (the HUD warning used for "No Target Nearby"; verified in HTR 0.4.1).
-- Only on foot (in a ship the pawn is the ship).
function U.notify(pawn, text)
    if U.className(pawn) ~= "Q1_Character_C" then return false end
    U.log("msg: " .. tostring(text))
    pcall(muteAlarm)
    return pcall(function() pawn:TMWPerkWarning(FText(text)) end)
end

return U
