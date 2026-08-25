local addonName, ns = ...

-- 1. THE SHARED MEMORY BANK
ns.Modules = {}          -- Where the BG modules register themselves
ns.ActiveModule = nil    -- Tracks which BG module is currently turned on

-- Auto-Logging Memory
ns.AutoLogActive = false 
ns.WasCombatLogged = false
ns.WasChatLogged = false

-- Shared Tactical Data (Modules write to this, UI reads from this)
ns.FlagCarriers = {}     -- Tracks who holds a flag/orb
ns.Timers = {}           -- Tracks Arathi Basin node timers
ns.ThreatDB = {}         -- Tracks high K/D players
ns.CC_DB = {}            -- Tracks who is currently crowd-controlled

-- 2. THE MODULE REGISTRY SYSTEM
-- Modules will call this function to introduce themselves to the Core
function ns.RegisterModule(bgName, enableFunc, disableFunc, eventHandler)
    ns.Modules[bgName] = {
        Enable = enableFunc,
        Disable = disableFunc,
        OnEvent = eventHandler
    }
end

-- 3. THE DISPATCHER (The Brain)
local CoreFrame = CreateFrame("Frame")
CoreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
CoreFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

local function UpdateActiveBattleground()
    -- Are we in a Battleground?
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "pvp" then
        -- We left the BG. Shut down whatever module is running.
        if ns.ActiveModule then
            ns.ActiveModule.Disable()
            ns.ActiveModule = nil
            -- Wipe the shared tactical data
            wipe(ns.FlagCarriers)
            wipe(ns.Timers)
            wipe(ns.ThreatDB)
            wipe(ns.CC_DB)
            print("|cff00ff00[Incahoots]|r: Exited Battleground. Tactical modules offline.")
        end
        
        -- Disable auto-logging when leaving a Battleground
        if ns.AutoLogActive then
            ns.AutoLogActive = false
            
            -- Only turn them off if Incahoots was the one that turned them on
            if not ns.WasCombatLogged and LoggingCombat() then LoggingCombat(0) end
            if not ns.WasChatLogged and LoggingChat() then LoggingChat(0) end
            
            print("|cff00ffff[Incahoots]|r: Chat and Combat auto-logging disabled.")
        end
        
        return
    end

    -- We are entering or currently inside a Battleground
    -- Enable auto-logging if it isn't already active
    if not ns.AutoLogActive then
        ns.AutoLogActive = true
        
        -- Record current state so we don't overwrite manual logging choices later
        ns.WasCombatLogged = LoggingCombat() and true or false
        ns.WasChatLogged = LoggingChat() and true or false
        
        -- Turn them on if they are currently off
        if not ns.WasCombatLogged then LoggingCombat(1) end
        if not ns.WasChatLogged then LoggingChat(1) end
        
        print("|cff00ffff[Incahoots]|r: Chat and Combat auto-logging active.")
    end

    -- Which Battleground are we in?
    local currentMap = GetRealZoneText()
    
    -- If the map hasn't changed, do nothing
    if ns.ActiveModule and ns.ActiveModule.name == currentMap then return end

    -- If a different module is running, shut it down
    if ns.ActiveModule then
        ns.ActiveModule.Disable()
        ns.ActiveModule = nil
    end

    -- Find the module for this map and turn it on
    local targetModule = ns.Modules[currentMap]
    if targetModule then
        ns.ActiveModule = targetModule
        ns.ActiveModule.name = currentMap
        ns.ActiveModule.Enable()
        print("|cff00ff00[Incahoots]|r: " .. currentMap .. " detected. Tactical module online.")
    else
        print("|cffff0000[Incahoots]|r: No tactical module found for " .. currentMap)
    end
end

-- 4. EVENT ROUTING
CoreFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        UpdateActiveBattleground()
    end

    -- If a module is active, route all raw game events directly to it
    if ns.ActiveModule and ns.ActiveModule.OnEvent then
        ns.ActiveModule.OnEvent(event, ...)
    end
end)

-- 5. LOGGING STATUS UI
local LogFrame = CreateFrame("Frame", "IncahootsLogStatusFrame", UIParent, "BackdropTemplate")
LogFrame:SetSize(130, 45)
LogFrame:SetPoint("TOP", UIParent, "TOP", 0, -20) -- Anchored at the top center
LogFrame:SetFrameStrata("LOW")
LogFrame:EnableMouse(true)
LogFrame:SetMovable(true)
LogFrame:SetClampedToScreen(true)
LogFrame:RegisterForDrag("LeftButton")
LogFrame:SetScript("OnDragStart", LogFrame.StartMoving)
LogFrame:SetScript("OnDragStop", LogFrame.StopMovingOrSizing)

LogFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
LogFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
LogFrame:SetBackdropBorderColor(0, 0, 0, 1)

local CombatLogText = LogFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
CombatLogText:SetPoint("TOP", LogFrame, "TOP", 0, -8)

local ChatLogText = LogFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ChatLogText:SetPoint("TOP", CombatLogText, "BOTTOM", 0, -4)

-- Update loop to keep the text accurate
local logTimer = 0
LogFrame:SetScript("OnUpdate", function(self, elapsed)
    logTimer = logTimer + elapsed
    if logTimer >= 2.0 then -- Polls the native API every 2 seconds
        logTimer = 0
        
        if LoggingCombat() then
            CombatLogText:SetText("Combat Log: |cff00ff00ON|r")
        else
            CombatLogText:SetText("Combat Log: |cffff0000OFF|r")
        end
        
        if LoggingChat() then
            ChatLogText:SetText("Chat Log: |cff00ff00ON|r")
        else
            ChatLogText:SetText("Chat Log: |cffff0000OFF|r")
        end
    end
end)