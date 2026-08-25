local addonName, ns = ...

-- 1. THE AB MICRO-FRAMES
local ABFrame = CreateFrame("Frame")
local UpdateFrame = CreateFrame("Frame")

ns.Timers = ns.Timers or {}

local nodes = {
    ["blacksmith"] = "Blacksmith",
    ["farm"] = "Farm",
    ["stables"] = "Stables",
    ["gold mine"] = "Gold Mine",
    ["lumber mill"] = "Lumber Mill"
}

-- 2. THE DEDICATED AB TIMER UI
local TimerUI = CreateFrame("Frame", "IncahootsABTimers", UIParent, "BackdropTemplate")
TimerUI:SetSize(160, 20)
TimerUI:SetPoint("TOP", UIParent, "TOP", 0, -120) -- Spawns near the top center of the screen
TimerUI:SetFrameStrata("LOW")
TimerUI:EnableMouse(true)
TimerUI:SetMovable(true)
TimerUI:SetClampedToScreen(true)
TimerUI:RegisterForDrag("LeftButton")
TimerUI:SetScript("OnDragStart", TimerUI.StartMoving)
TimerUI:SetScript("OnDragStop", TimerUI.StopMovingOrSizing)

TimerUI:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
TimerUI:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
TimerUI:SetBackdropBorderColor(0, 0, 0, 1)
TimerUI:Hide()

local Title = TimerUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Title:SetPoint("TOP", TimerUI, "TOP", 0, -4)
Title:SetText("Assault Timers")
Title:SetTextColor(1, 1, 1)

-- Create 5 reusable text lines for the timers
TimerUI.textLines = {}
for i = 1, 5 do
    local fs = TimerUI:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    fs:SetPoint("TOP", TimerUI, "TOP", 0, -((i * 15) + 5))
    TimerUI.textLines[i] = fs
end

-- ElvUI Skinning for the Timer Box
local function SkinTimerUI()
    if IsAddOnLoaded("ElvUI") then
        local E = unpack(ElvUI)
        if E then
            TimerUI:SetBackdrop(nil)
            TimerUI:SetTemplate("Transparent")
        end
    end
end

-- 3. THE CHAT PARSER
local function ParseABMessage(msg)
    local lowerMsg = string.lower(msg)
    
    if ns.DebugMode then
        print("|cff00ffff[AB Module]|r: " .. msg)
    end
    
    -- Identify which node is being talked about
    local targetNode = nil
    local displayName = nil
    for key, name in pairs(nodes) do
        if string.find(lowerMsg, key) then
            targetNode = key
            displayName = name
            break
        end
    end
    
    if not targetNode then return end

    -- Identify the faction
    local faction = "Neutral"
    if string.find(lowerMsg, "horde") then 
        faction = "Horde"
    elseif string.find(lowerMsg, "alliance") then 
        faction = "Alliance" 
    end

    -- Identify the Action
    if string.find(lowerMsg, "assaulted") then
        -- Start a 60-second timer
        ns.Timers[targetNode] = { 
            endTime = GetTime() + 60, 
            name = displayName, 
            faction = faction 
        }
    elseif string.find(lowerMsg, "defended") or string.find(lowerMsg, "taken") or string.find(lowerMsg, "claims") then
        -- The base flipped or was saved. Kill the timer.
        ns.Timers[targetNode] = nil
    end
end

ABFrame:SetScript("OnEvent", function(self, event, msg)
    ParseABMessage(msg)
end)

-- 4. THE LIVE COUNTDOWN ENGINE
UpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    -- We only want this math running if we are actively in AB
    if not ns.ActiveModule or ns.ActiveModule.name ~= "Arathi Basin" then return end

    local hasTimers = false
    local lineIdx = 1
    local now = GetTime()
    
    -- Clear all text lines first
    for i = 1, 5 do TimerUI.textLines[i]:SetText("") end
    
    -- Draw the active timers
    for key, data in pairs(ns.Timers) do
        if data then
            local remaining = data.endTime - now
            if remaining > 0 then
                hasTimers = true
                -- Color the text based on who is attacking it
                local color = (data.faction == "Horde") and "|cffff2020" or "|cff0070dd"
                
                TimerUI.textLines[lineIdx]:SetText(color .. data.name .. ": " .. math.floor(remaining) .. "s|r")
                lineIdx = lineIdx + 1
            else
                -- The timer hit 0 without anyone defending it. The base flipped.
                ns.Timers[key] = nil 
            end
        end
    end
    
    -- Resize and show/hide the box dynamically
    if hasTimers then
        TimerUI:SetHeight((lineIdx * 15) + 10)
        TimerUI:Show()
    else
        TimerUI:Hide()
    end
end)

-- 5. THE POWER SWITCHES
local function OnEnable()
    SkinTimerUI()
    ABFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
    ABFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
    ABFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
    wipe(ns.Timers)
end

local function OnDisable()
    ABFrame:UnregisterAllEvents()
    wipe(ns.Timers)
    TimerUI:Hide()
end

-- 6. REGISTER WITH THE CORE
if ns.RegisterModule then
    ns.RegisterModule("Arathi Basin", OnEnable, OnDisable)
end