local addonName, ns = ...

-- 1. MAIN FRAME SETUP
local MainFrame = CreateFrame("Frame", "IncahootsFrame", UIParent)
-- Shrunk overall size from 310x260 down to 260x230
MainFrame:SetSize(260, 230) 
MainFrame:SetPoint("CENTER")
MainFrame:SetFrameStrata("DIALOG") 
MainFrame:EnableMouse(true)
MainFrame:SetMovable(true)
MainFrame:SetClampedToScreen(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)

local bg = MainFrame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(MainFrame)
bg:SetTexture(0, 0, 0, 0.9)

MainFrame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, tileSize = 0, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

-- 2. TITLE TEXT
local version = GetAddOnMetadata(addonName, "Version") or "2.0"
local Title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Title:SetPoint("TOP", MainFrame, "TOP", 0, -6)
Title:SetText("Incahoots v" .. version)
Title:SetTextColor(1, 0.82, 0)

-- 3. MAP ATTACHMENT
local function AttachMap()
    if not IsAddOnLoaded("Blizzard_BattlefieldMinimap") then
        LoadAddOn("Blizzard_BattlefieldMinimap")
    end

    if BattlefieldMinimap then
        BattlefieldMinimap:SetParent(MainFrame)
        BattlefieldMinimap:ClearAllPoints()
        BattlefieldMinimap:SetPoint("TOP", MainFrame, "TOP", 0, -22)
        -- Scaled the map down to 240x165 to fit the new frame width
        BattlefieldMinimap:SetSize(240, 165) 
        BattlefieldMinimap:SetFrameLevel(MainFrame:GetFrameLevel() + 1)
        BattlefieldMinimap:Show()
        
        if BattlefieldMinimapTab then BattlefieldMinimapTab:Hide() end
        if BattlefieldMinimapBackground then BattlefieldMinimapBackground:Hide() end
        if BattlefieldMinimapCloseButton then 
            BattlefieldMinimapCloseButton:Hide()
            BattlefieldMinimapCloseButton:SetAlpha(0)
            BattlefieldMinimapCloseButton.Show = function() end 
        end
    end
end

-- 4. REPORTING FUNCTION
local function SendIncReport(text)
    local loc = GetSubZoneText() or GetMinimapZoneText() or GetZoneText() or "Unknown"
    local msg = (text == "H") and ("HELP @ " .. loc) or (text == "S") and (loc .. " is SAFE") or ("INC " .. text .. " @ " .. loc)
    local channel = UnitInBattleground("player") and "BATTLEGROUND" or "SAY"
    SendChatMessage(msg, channel)
end

-- 5. LAZY LOAD BUTTONS (Miniaturized)
local buttonsCreated = false
local function CreateButtonsLate()
    if buttonsCreated then return end 
    
    local BtnFrame = CreateFrame("Frame", "IncahootsBtnContainer", MainFrame)
    -- Narrowed the container to match the new map/frame width
    BtnFrame:SetSize(240, 30) 
    BtnFrame:SetPoint("BOTTOM", MainFrame, "BOTTOM", 0, 8)
    BtnFrame:SetFrameLevel(MainFrame:GetFrameLevel() + 15) 

    local labels = {"1", "2", "3", "4", "5", "H", "S"}
    -- Shrunk buttons from 38x30 down to 32x24
    local bWidth = 32 

    for i, label in ipairs(labels) do
        local btn = CreateFrame("Button", "IncBtn"..label, BtnFrame, "UIPanelButtonTemplate")
        btn:SetSize(bWidth, 24) 
        -- Reduced horizontal spacing between the smaller buttons
        btn:SetPoint("LEFT", BtnFrame, "LEFT", (i - 1) * (bWidth + 2.5), 0)
        
        btn:SetText(label)
        local fs = btn:GetFontString()
        if fs then
            -- Shrunk the font from 14 to 12 so it fits cleanly inside the smaller buttons
            fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            fs:SetTextColor(1, 0.82, 0)
        end

        btn:SetScript("OnClick", function() SendIncReport(label) end)
        btn:Show()
    end
    
    buttonsCreated = true
end

-- 6. SLASH COMMANDS
SLASH_INCAHOOTS1 = "/inc"
SlashCmdList["INCAHOOTS"] = function()
    if MainFrame:IsVisible() then
        MainFrame:Hide()
    else
        AttachMap()
        CreateButtonsLate() 
        MainFrame:Show()
    end
end

-- 7. AUTO-LOAD IN BATTLEGROUNDS
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

local lastWasPVP = false

EventFrame:SetScript("OnEvent", function(self, event)
    local _, instanceType = IsInInstance()
    
    if instanceType == "pvp" then
        -- THE FIX: Dynamically read the zone and inject it into the title
        local zoneName = GetRealZoneText() or GetZoneText()
        if zoneName and zoneName ~= "" then
            Title:SetText(zoneName)
        else
            Title:SetText("Incahoots v" .. version)
        end

        if not lastWasPVP then
            AttachMap()
            CreateButtonsLate()
            MainFrame:Show()
            lastWasPVP = true
        end
    else
        -- Reset the title when you leave the Battleground
        Title:SetText("Incahoots v" .. version)
        
        if lastWasPVP then
            MainFrame:Hide()
            lastWasPVP = false
        end
    end
end)

MainFrame:Hide()