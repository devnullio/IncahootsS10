local addonName, ns = ...

-- ============================================================================
-- 1. TROPHY ROOM MODULE
-- ============================================================================
local TrophyTracker = CreateFrame("Frame")

-- Storage for the ledger
local killLog = {}
local deathLog = {}
local maxRows = 8

-- CREATE THE TROPHY ROOM FRAME
local TrophyFrame = CreateFrame("Frame", "IncahootsTrophyFrame", UIParent, "BackdropTemplate")
TrophyFrame:SetSize(220, 300)
TrophyFrame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
TrophyFrame:SetFrameStrata("HIGH")
TrophyFrame:EnableMouse(true)
TrophyFrame:SetMovable(true)
TrophyFrame:SetClampedToScreen(true)
TrophyFrame:RegisterForDrag("LeftButton")
TrophyFrame:SetScript("OnDragStart", TrophyFrame.StartMoving)
TrophyFrame:SetScript("OnDragStop", TrophyFrame.StopMovingOrSizing)
TrophyFrame:Hide() -- Hidden by default, toggle with /trophy

TrophyFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
TrophyFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
TrophyFrame:SetBackdropBorderColor(0, 0, 0, 1)

local Title = TrophyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Title:SetPoint("TOP", TrophyFrame, "TOP", 0, -6)
Title:SetText("Incahoots Trophy Room")
Title:SetTextColor(1, 0.82, 0)

local CloseBtn = CreateFrame("Button", nil, TrophyFrame, "UIPanelCloseButton")
CloseBtn:SetPoint("TOPRIGHT", TrophyFrame, "TOPRIGHT", 2, 2)
CloseBtn:SetSize(24, 24)

-- Kills Section
local KillsHeader = TrophyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
KillsHeader:SetPoint("TOPLEFT", TrophyFrame, "TOPLEFT", 10, -25)
KillsHeader:SetText("My Kills")
KillsHeader:SetTextColor(0.2, 1, 0.2)

local killRows = {}
for i = 1, maxRows do
    local row = TrophyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row:SetJustifyH("LEFT")
    row:SetSize(200, 12)
    if i == 1 then
        row:SetPoint("TOPLEFT", KillsHeader, "BOTTOMLEFT", 0, -5)
    else
        row:SetPoint("TOPLEFT", killRows[i-1], "BOTTOMLEFT", 0, -3)
    end
    row:SetText("")
    killRows[i] = row
end

-- Deaths Section
local DeathsHeader = TrophyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
DeathsHeader:SetText("My Deaths")
DeathsHeader:SetTextColor(1, 0.2, 0.2)

local deathRows = {}
for i = 1, maxRows do
    local row = TrophyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row:SetJustifyH("LEFT")
    row:SetSize(200, 12)
    if i == 1 then
        row:SetPoint("TOPLEFT", DeathsHeader, "BOTTOMLEFT", 0, -5)
    else
        row:SetPoint("TOPLEFT", deathRows[i-1], "BOTTOMLEFT", 0, -3)
    end
    row:SetText("")
    deathRows[i] = row
end

local ClearBtn = CreateFrame("Button", nil, TrophyFrame, "UIPanelButtonTemplate")
ClearBtn:SetSize(60, 20)
ClearBtn:SetPoint("BOTTOM", TrophyFrame, "BOTTOM", 0, 5)
ClearBtn:SetText("Clear")

-- DYNAMIC DISPLAY LOGIC
local function UpdateTrophyUI()
    local killCount = math.max(1, math.min(#killLog, maxRows))
    local deathCount = math.max(1, math.min(#deathLog, maxRows))

    -- Hide all rows initially to prevent overlaps
    for i = 1, maxRows do
        killRows[i]:Hide()
        deathRows[i]:Hide()
    end

    -- Populate Kills
    if #killLog == 0 then
        killRows[1]:SetText("No kills yet.")
        killRows[1]:SetTextColor(0.5, 0.5, 0.5)
        killRows[1]:Show()
    else
        for i = 1, killCount do
            killRows[i]:SetText(killLog[i])
            killRows[i]:SetTextColor(1, 1, 1)
            killRows[i]:Show()
        end
    end

    -- Populate Deaths
    if #deathLog == 0 then
        deathRows[1]:SetText("No deaths yet.")
        deathRows[1]:SetTextColor(0.5, 0.5, 0.5)
        deathRows[1]:Show()
    else
        for i = 1, deathCount do
            deathRows[i]:SetText(deathLog[i])
            deathRows[i]:SetTextColor(1, 1, 1)
            deathRows[i]:Show()
        end
    end
    
    -- Dynamically slide the Deaths header up to sit right below the last visible kill
    DeathsHeader:ClearAllPoints()
    DeathsHeader:SetPoint("TOPLEFT", killRows[killCount], "BOTTOMLEFT", 0, -15)
    
    -- Dynamically resize the background frame based on active row count
    local totalHeight = 110 + (killCount * 15) + (deathCount * 15)
    TrophyFrame:SetHeight(totalHeight)
end

ClearBtn:SetScript("OnClick", function()
    wipe(killLog)
    wipe(deathLog)
    UpdateTrophyUI()
end)

-- ELVUI COMPATIBILITY HOOK
local function ApplyElvUISkin()
    if IsAddOnLoaded("ElvUI") then
        local E = unpack(ElvUI)
        if E then
            TrophyFrame:SetBackdrop(nil)
            TrophyFrame:SetTemplate("Transparent")
            ClearBtn:StripTextures()
            ClearBtn:SetTemplate("Default", true)
        end
    end
end

-- SLASH COMMAND
SLASH_INCAHOOTSTROPHY1 = "/trophy"
SlashCmdList["INCAHOOTSTROPHY"] = function()
    if TrophyFrame:IsShown() then
        TrophyFrame:Hide()
    else
        UpdateTrophyUI()
        TrophyFrame:Show()
    end
end

-- COMBAT LOG ENGINE
TrophyTracker:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then 
        ApplyElvUISkin()
        return 
    end

    if event == "PLAYER_ENTERING_WORLD" then
        if UnitInBattleground("player") then
            wipe(killLog)
            wipe(deathLog)
            UpdateTrophyUI()
        end
        return
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, combatEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = select(1, ...)
        
        local myGUID = UnitGUID("player")
        
        -- Uses raw binary bitmasks instead of the UnitIsPlayer() API
        -- 0x00000400 confirms the destination is a real Player Character
        local isDestPlayer = destFlags and bit.band(destFlags, 0x00000400) > 0
        
        -- 0x00000001 confirms the source is YOU, your PET, or your TOTEM
        local isMyDamage = sourceFlags and bit.band(sourceFlags, 0x00000001) > 0
        
        local isMyKill = (isMyDamage and destGUID ~= myGUID and isDestPlayer)
        local isMyDeath = (destGUID == myGUID and sourceGUID ~= myGUID)

        if isMyKill or isMyDeath then
            local overkill = 0
            local spellName = "Melee/Auto"

            -- WotLK API: Swing damage overkill is arg 10. Spell overkill is arg 13.
            if combatEvent == "SWING_DAMAGE" then
                overkill = select(10, ...)
            elseif combatEvent == "SPELL_DAMAGE" or combatEvent == "RANGE_DAMAGE" or combatEvent == "SPELL_PERIODIC_DAMAGE" then
                spellName = select(10, ...)
                overkill = select(13, ...)
            end

            -- If overkill is present and greater than 0, it was a killing blow
            if overkill and type(overkill) == "number" and overkill > 0 then
                local shortTarget = destName and string.match(destName, "([^%-]+)") or "Unknown"
                local shortSource = sourceName and string.match(sourceName, "([^%-]+)") or "Unknown"

                if isMyKill then
                    local record = string.format("|cffffb200[%s]|r -> %s", spellName, shortTarget)
                    table.insert(killLog, 1, record)
                    if #killLog > maxRows then table.remove(killLog) end
                    
                elseif isMyDeath then
                    local record = string.format("%s <- |cffaaaaaa[%s]|r", shortSource, spellName)
                    table.insert(deathLog, 1, record)
                    if #deathLog > maxRows then table.remove(deathLog) end
                end

                if TrophyFrame:IsShown() then
                    UpdateTrophyUI()
                end
            end
        end
    end
end)

TrophyTracker:RegisterEvent("PLAYER_LOGIN")
TrophyTracker:RegisterEvent("PLAYER_ENTERING_WORLD")
TrophyTracker:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")


-- ============================================================================
-- 2. LOGGER TOGGLE MODULE
-- ============================================================================
local LogFrame = CreateFrame("Frame", "IncahootsLogFrame", UIParent, "BackdropTemplate")
LogFrame:SetSize(150, 65)
LogFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 150, 200)
LogFrame:SetFrameStrata("LOW")
LogFrame:EnableMouse(true)
LogFrame:SetMovable(true)
LogFrame:SetClampedToScreen(true)
LogFrame:RegisterForDrag("LeftButton")
LogFrame:SetScript("OnDragStart", LogFrame.StartMoving)
LogFrame:SetScript("OnDragStop", LogFrame.StopMovingOrSizing)
LogFrame:Hide() -- Hidden by default, toggle with /logs

LogFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
LogFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
LogFrame:SetBackdropBorderColor(0, 0, 0, 1)

-- CREATE THE ACTUAL CLICKABLE BUTTONS
local CombatLogBtn = CreateFrame("Button", nil, LogFrame, "UIPanelButtonTemplate")
CombatLogBtn:SetSize(130, 22)
CombatLogBtn:SetPoint("TOP", LogFrame, "TOP", 0, -8)

local ChatLogBtn = CreateFrame("Button", nil, LogFrame, "UIPanelButtonTemplate")
ChatLogBtn:SetSize(130, 22)
ChatLogBtn:SetPoint("TOP", CombatLogBtn, "BOTTOM", 0, -5)

-- STATE UPDATE FUNCTION
local function UpdateLogStatus()
    if LoggingCombat() then
        CombatLogBtn:SetText("Combat Log: |cff00ff00ON|r")
    else
        CombatLogBtn:SetText("Combat Log: |cffff0000OFF|r")
    end

    if LoggingChat() then
        ChatLogBtn:SetText("Chat Log: |cff00ff00ON|r")
    else
        ChatLogBtn:SetText("Chat Log: |cffff0000OFF|r")
    end
end

-- BUTTON CLICK SCRIPTS
CombatLogBtn:SetScript("OnClick", function()
    local newState = LoggingCombat() and 0 or 1
    LoggingCombat(newState)
    UpdateLogStatus()
end)

ChatLogBtn:SetScript("OnClick", function()
    local newState = LoggingChat() and 0 or 1
    LoggingChat(newState)
    UpdateLogStatus()
end)

-- SLASH COMMAND
SLASH_INCAHOOTSLOGS1 = "/logs"
SLASH_INCAHOOTSLOGS2 = "/log"
SlashCmdList["INCAHOOTSLOGS"] = function()
    if LogFrame:IsShown() then
        LogFrame:Hide()
    else
        UpdateLogStatus()
        LogFrame:Show()
    end
end

-- EVENT LISTENERS FOR AUTO-ENABLE
LogFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
LogFrame:RegisterEvent("PLAYER_LOGIN")

LogFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if IsAddOnLoaded("ElvUI") then
            local E = unpack(ElvUI)
            if E then
                LogFrame:SetBackdrop(nil)
                LogFrame:SetTemplate("Transparent")
                CombatLogBtn:StripTextures()
                CombatLogBtn:SetTemplate("Default", true)
                ChatLogBtn:StripTextures()
                ChatLogBtn:SetTemplate("Default", true)
            end
        end
        UpdateLogStatus()
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        if UnitInBattleground("player") then
            LoggingCombat(1)
            LoggingChat(1)
        end
        UpdateLogStatus()
    end
end)