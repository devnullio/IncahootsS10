local addonName, ns = ...

-- Expose shared memory tables if the Core hasn't already
ns.FlagCarriers = ns.FlagCarriers or {}
ns.CarryDB = ns.CarryDB or {}

-- 1. RED SCREEN FLASH SETUP
local FlashFrame = CreateFrame("Frame", "IncahootsFlashFrame", UIParent)
FlashFrame:SetAllPoints(UIParent)
FlashFrame:SetFrameStrata("FULLSCREEN_DIALOG") 
FlashFrame:Hide()

local flashTex = FlashFrame:CreateTexture(nil, "BACKGROUND")
flashTex:SetAllPoints()
flashTex:SetTexture(1, 0, 0, 1)

ns.TriggerRedFlash = function()
    FlashFrame:Show()
    UIFrameFadeOut(FlashFrame, 0.8, 0.5, 0) 
end

-- 2. CONTAINER FRAME
local BGTFrame = CreateFrame("Frame", "IncahootsBGTFrame", UIParent, "BackdropTemplate")
BGTFrame:SetSize(220, 70) 
BGTFrame:SetPoint("RIGHT", UIParent, "RIGHT", -50, 0)
BGTFrame:SetFrameStrata("LOW")
BGTFrame:EnableMouse(true)
BGTFrame:SetMovable(true)
BGTFrame:SetClampedToScreen(true)
BGTFrame:RegisterForDrag("LeftButton")
BGTFrame:SetScript("OnDragStart", BGTFrame.StartMoving)
BGTFrame:SetScript("OnDragStop", BGTFrame.StopMovingOrSizing)

BGTFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
BGTFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
BGTFrame:SetBackdropBorderColor(0, 0, 0, 1)

local ZoneTitle = BGTFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ZoneTitle:SetPoint("BOTTOM", BGTFrame, "TOP", 0, 4)
ZoneTitle:SetText("")
ZoneTitle:SetTextColor(1, 0.82, 0)

local Title = BGTFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Title:SetPoint("TOP", BGTFrame, "TOP", 0, -6)
Title:SetText("Incahoots Enemies")
Title:SetTextColor(1, 1, 1)

-- 3. LABELS & BUTTONS
local HealerLabel = BGTFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
HealerLabel:SetText("Enemy Healers")
HealerLabel:SetTextColor(0, 1, 0) 

local RogueLabel = BGTFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
RogueLabel:SetText("Enemy Rogues")
RogueLabel:SetTextColor(1, 0.96, 0.41) 

local OtherLabel = BGTFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
OtherLabel:SetText("Other Enemies")
OtherLabel:SetTextColor(0.8, 0.8, 0.8)

-- TOTALS FOOTER
local EnemyTotalsText = BGTFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
EnemyTotalsText:SetPoint("BOTTOM", BGTFrame, "BOTTOM", 0, 8)
EnemyTotalsText:SetTextColor(1, 1, 1)
EnemyTotalsText:SetText("")

local cachedEnemyKills, cachedEnemyHeals, cachedEnemyDmg = 0, 0, 0

-- Buttons anchored inside, just below the Title
local ReportHealsBtn = CreateFrame("Button", nil, BGTFrame, "UIPanelButtonTemplate")
ReportHealsBtn:SetSize(40, 20)
ReportHealsBtn:SetPoint("TOPRIGHT", BGTFrame, "TOPRIGHT", -5, -24)
ReportHealsBtn:SetText("Heals")

local ReportDPSBtn = CreateFrame("Button", nil, BGTFrame, "UIPanelButtonTemplate")
ReportDPSBtn:SetSize(40, 20)
ReportDPSBtn:SetPoint("RIGHT", ReportHealsBtn, "LEFT", -2, 0)
ReportDPSBtn:SetText("DPS")

local ReportCompBtn = CreateFrame("Button", nil, BGTFrame, "UIPanelButtonTemplate")
ReportCompBtn:SetSize(40, 20)
ReportCompBtn:SetPoint("RIGHT", ReportDPSBtn, "LEFT", -2, 0)
ReportCompBtn:SetText("Comp")

local ReportRogueBtn = CreateFrame("Button", nil, BGTFrame, "UIPanelButtonTemplate")
ReportRogueBtn:SetSize(45, 20)
ReportRogueBtn:SetPoint("RIGHT", ReportCompBtn, "LEFT", -2, 0)
ReportRogueBtn:SetText("Rogue")

-- CONSOLIDATED REPORT TOTALS BUTTON
local ReportTotalsBtn = CreateFrame("Button", nil, BGTFrame, "UIPanelButtonTemplate")
ReportTotalsBtn:SetSize(45, 20)
ReportTotalsBtn:SetPoint("RIGHT", ReportRogueBtn, "LEFT", -2, 0)
ReportTotalsBtn:SetText("Totals")

-- NUMBER FORMATTER (For the UI Frames)
local function FormatStat(amount)
    if amount == 0 then return "" end
    if amount >= 1000000 then return string.format("%.2fm", amount / 1000000) end
    if amount >= 1000 then return string.format("%.1fk", amount / 1000) end
    return tostring(amount)
end

-- 4. CREATE UNIT ROWS
local numRows = 20 
local rowHeight = 20
local rowSpacing = 1
BGTFrame.rows = {}

for i = 1, numRows do
    local row = CreateFrame("Button", "IncahootsBGTRow"..i, BGTFrame, "SecureActionButtonTemplate")
    row:SetSize(209, rowHeight)
    
    row:RegisterForClicks("LeftButtonUp")
    row:SetAttribute("type1", "macro") 
    
    local classIcon = row:CreateTexture(nil, "OVERLAY")
    classIcon:SetSize(rowHeight, rowHeight)
    classIcon:SetPoint("LEFT", row, "LEFT", 0, 0)
    classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    classIcon:Hide()

    local hpBar = CreateFrame("StatusBar", nil, row)
    hpBar:SetPoint("TOPLEFT", row, "TOPLEFT", rowHeight + 2, 0)
    hpBar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    hpBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    hpBar:SetStatusBarColor(0.6, 0.1, 0.1, 1) 
    hpBar:SetMinMaxValues(0, 100)
    hpBar:SetValue(100)
    
    local hpBg = hpBar:CreateTexture(nil, "BACKGROUND")
    hpBg:SetAllPoints(hpBar)
    hpBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    hpBg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    local levelText = hpBar:CreateFontString(nil, "OVERLAY")
    levelText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    levelText:SetPoint("LEFT", hpBar, "LEFT", 3, 0)
    levelText:SetTextColor(0.8, 0.8, 0.8)

    local nameText = hpBar:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    nameText:SetPoint("LEFT", hpBar, "LEFT", 22, 0)
    nameText:SetText("")
    nameText:SetTextColor(1, 1, 1)

    local threatIcon = hpBar:CreateTexture(nil, "OVERLAY")
    threatIcon:SetSize(14, 14)
    threatIcon:SetPoint("LEFT", nameText, "RIGHT", 4, 0)
    threatIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    threatIcon:Hide()

    local flagIcon = hpBar:CreateTexture(nil, "OVERLAY")
    flagIcon:SetSize(18, 18)
    flagIcon:SetPoint("LEFT", threatIcon, "RIGHT", 2, 0)
    flagIcon:Hide()

    local killText = hpBar:CreateFontString(nil, "OVERLAY")
    killText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    killText:SetPoint("RIGHT", hpBar, "RIGHT", -20, 0)
    killText:SetJustifyH("RIGHT")

    local statText = hpBar:CreateFontString(nil, "OVERLAY")
    statText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    statText:SetPoint("RIGHT", hpBar, "RIGHT", -45, 0)
    statText:SetJustifyH("RIGHT")
    
    local targetIcon = hpBar:CreateTexture(nil, "OVERLAY")
    targetIcon:SetSize(16, 16)
    targetIcon:SetPoint("RIGHT", hpBar, "RIGHT", -2, 0)
    targetIcon:SetTexture("Interface\\Minimap\\Tracking\\Target") 
    targetIcon:Hide()

    row.classIcon = classIcon
    row.hpBar = hpBar
    row.levelText = levelText
    row.nameText = nameText
    row.threatIcon = threatIcon
    row.flagIcon = flagIcon
    row.killText = killText
    row.statText = statText
    row.targetIcon = targetIcon
    
    row:Hide()
    BGTFrame.rows[i] = row
end

-- 5. ELVUI COMPATIBILITY HOOK
local function ApplyElvUISkin()
    if IsAddOnLoaded("ElvUI") then
        local E = unpack(ElvUI)
        if E then
            BGTFrame:SetBackdrop(nil)
            BGTFrame:SetTemplate("Transparent")
            local normTex = E.media.normTex
            for i = 1, numRows do
                BGTFrame.rows[i].hpBar:SetStatusBarTexture(normTex)
            end
            ReportHealsBtn:StripTextures()
            ReportHealsBtn:SetTemplate("Default", true)
            ReportDPSBtn:StripTextures()
            ReportDPSBtn:SetTemplate("Default", true)
            ReportCompBtn:StripTextures()
            ReportCompBtn:SetTemplate("Default", true)
            ReportRogueBtn:StripTextures()
            ReportRogueBtn:SetTemplate("Default", true)
            ReportTotalsBtn:StripTextures()
            ReportTotalsBtn:SetTemplate("Default", true)
        end
    end
end

-- 6. DATA MANAGEMENT & SORTING
local BGFrame = CreateFrame("Frame")
BGFrame:RegisterEvent("PLAYER_LOGIN")
BGFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
BGFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
BGFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
BGFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT") 
BGFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local currentEnemies = {}
local pendingSort = false

local stealthCache = {}
local stealthAlertCache = {}
local levelCache = {} 
local ccCache = {}
local myTeam = {} 

local stealthSpells = {
    ["Stealth"] = true, ["Prowl"] = true, ["Vanish"] = true, ["Shadowmeld"] = true
}

local hardCCSpells = {
    ["Polymorph"] = true, ["Cyclone"] = true, ["Blind"] = true, ["Fear"] = true,
    ["Hammer of Justice"] = true, ["Sap"] = true, ["Repentance"] = true, ["Howl of Terror"] = true,
    ["Seduction"] = true, ["Psychic Scream"] = true, ["Freezing Trap"] = true, ["Hex"] = true,
    ["Intimidating Shout"] = true, ["Gouge"] = true, ["Kidney Shot"] = true, ["Cheap Shot"] = true,
    ["Strangulate"] = true
}

local function ClearEnemies()
    wipe(currentEnemies)
    wipe(stealthCache)
    wipe(stealthAlertCache)
    wipe(levelCache)
    wipe(ccCache)
    wipe(ns.CarryDB)
    wipe(ns.FlagCarriers)

    ns.EnemyKills = 0
    ns.EnemyHeals = 0
    ns.EnemyDmg = 0

    ns.MyBGFaction = nil
    ns.EnemyBGFaction = nil

    HealerLabel:Hide()
    RogueLabel:Hide()
    OtherLabel:Hide()
    Title:SetText("Incahoots Enemies")
    ZoneTitle:SetText("")
    EnemyTotalsText:SetText("")
    BGTFrame:SetHeight(70)

    for i = 1, numRows do
        local row = BGTFrame.rows[i]
        row.classIcon:Hide()
        row.targetIcon:Hide() 
        row.statText:SetText("")
        row.killText:SetText("")
        row.levelText:SetText("")
        row.flagIcon:Hide()
        row.threatIcon:Hide()
        row.nameText:SetTextColor(1, 1, 1) 
        row.hpBar:SetStatusBarColor(0.6, 0.1, 0.1, 1)
        row:SetAlpha(1.0)
        if not InCombatLockdown() then
            row:Hide()
            row:SetAttribute("macrotext1", "")
        end
    end
end

local function PassiveLevelScan()
    local updated = false
    local unitsToScan = {"target", "mouseover", "focus"}
    
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do table.insert(unitsToScan, "raid"..i.."target") end
    else
        local numParty = GetNumPartyMembers()
        if numParty > 0 then
            for i = 1, numParty do table.insert(unitsToScan, "party"..i.."target") end
        end
    end

    for _, unit in ipairs(unitsToScan) do
        if UnitExists(unit) and UnitIsEnemy("player", unit) and UnitIsPlayer(unit) then
            local name = UnitName(unit)
            local lvl = UnitLevel(unit)
            if name and lvl and (lvl > 0 or lvl == -1) then
                local shortName = string.match(name, "([^%-]+)") or name
                if levelCache[shortName] ~= lvl then
                    levelCache[shortName] = lvl
                    updated = true
                end
            end
        end
    end
    return updated
end

local function GetLevelColor(targetLevel)
    if targetLevel == -1 then return 1, 0.2, 0.2 end 
    local myLevel = UnitLevel("player") or 1
    local diff = targetLevel - myLevel
    if diff >= 5 then return 1, 0.2, 0.2 
    elseif diff >= 3 then return 1, 0.6, 0 
    elseif diff >= -2 then return 1, 1, 0 
    elseif diff >= -9 then return 0.2, 1, 0.2 
    else return 0.6, 0.6, 0.6 end
end

local function RenderUI()
    local inCombat = InCombatLockdown()
    
    if inCombat then
        pendingSort = true
        BGFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end

    local currentTarget = UnitName("target")
    
    if not inCombat then
        HealerLabel:Hide()
        RogueLabel:Hide()
        OtherLabel:Hide()
    end

    local yOffset = -48 
    local currentCategory = nil
    local visibleCount = 0

    for i = 1, numRows do
        local data = currentEnemies[i]
        local row = BGTFrame.rows[i]
        
        if data then
            visibleCount = visibleCount + 1
            
            -- LAYOUT UPDATE (Blocked in combat)
            if not inCombat then
                if data.category ~= currentCategory then
                    if currentCategory then yOffset = yOffset - 5 end 
                    if data.category == "Healer" then
                        HealerLabel:SetPoint("TOPLEFT", BGTFrame, "TOPLEFT", 10, yOffset)
                        HealerLabel:Show()
                        yOffset = yOffset - 16
                    elseif data.category == "Rogue" then
                        RogueLabel:SetPoint("TOPLEFT", BGTFrame, "TOPLEFT", 10, yOffset)
                        RogueLabel:Show()
                        yOffset = yOffset - 16
                    elseif data.category == "Other" then
                        OtherLabel:SetPoint("TOPLEFT", BGTFrame, "TOPLEFT", 10, yOffset)
                        OtherLabel:Show()
                        yOffset = yOffset - 16
                    end
                    currentCategory = data.category
                end

                row:SetPoint("TOP", BGTFrame, "TOP", 0, yOffset)
                yOffset = yOffset - (rowHeight + rowSpacing)
            end

            -- VISUALS UPDATE (Safe in combat)
            if ccCache[data.shortName] then row:SetAlpha(0.4) else row:SetAlpha(1.0) end

            local lvl = levelCache[data.shortName]
            if lvl then
                if lvl == -1 then
                    row.levelText:SetText("??")
                    row.levelText:SetTextColor(1, 0.2, 0.2)
                else
                    row.levelText:SetText(lvl)
                    local r, g, b = GetLevelColor(lvl)
                    row.levelText:SetTextColor(r, g, b)
                end
            else
                row.levelText:SetText("??")
                row.levelText:SetTextColor(0.8, 0.8, 0.8)
            end

            row.nameText:SetText(data.shortName)
            
            if data.classToken == "ROGUE" or data.classToken == "DRUID" then
                local status = stealthCache[data.shortName] or "Unknown"
                if status == "Stealthed" then row.nameText:SetTextColor(1, 0.2, 0.2) 
                elseif status == "Visible" then row.nameText:SetTextColor(0.2, 1, 0.2) 
                else row.nameText:SetTextColor(1, 1, 1) end
            else
                row.nameText:SetTextColor(1, 1, 1) 
            end
            
            if data.isCarry then
                row.threatIcon:Show()
                row.flagIcon:SetPoint("LEFT", row.threatIcon, "RIGHT", 2, 0)
            else
                row.threatIcon:Hide()
                row.flagIcon:SetPoint("LEFT", row.nameText, "RIGHT", 4, 0)
            end

            if ns.FlagCarriers and ns.FlagCarriers[data.shortName] then
                row.flagIcon:SetTexture(ns.FlagCarriers[data.shortName])
                row.flagIcon:Show()
            else
                row.flagIcon:Hide()
            end

            row.killText:SetText(data.kills or 0)
            if data.category == "Healer" then
                row.statText:SetText(FormatStat(data.healing))
                row.statText:SetTextColor(0, 1, 0)
                row.killText:SetTextColor(0, 1, 0)
            else
                row.statText:SetText(FormatStat(data.damage))
                row.statText:SetTextColor(1, 0.7, 0)
                row.killText:SetTextColor(1, 0.7, 0)
            end
            
            if RAID_CLASS_COLORS[data.classToken] then
                local color = RAID_CLASS_COLORS[data.classToken]
                row.hpBar:SetStatusBarColor(color.r, color.g, color.b, 1)
                if CLASS_ICON_TCOORDS[data.classToken] then
                    row.classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[data.classToken]))
                    row.classIcon:Show()
                end
            end

            if currentTarget and data.shortName == currentTarget then row.targetIcon:Show() else row.targetIcon:Hide() end

            if not inCombat then
                row:SetAttribute("macrotext1", "/targetexact " .. data.shortName)
                row:Show()
            end
        else
            if not inCombat then
                row:Hide()
                row:SetAttribute("macrotext1", "")
                row.targetIcon:Hide()
            end
        end
    end
    
    if not inCombat then
        local titleText = "Incahoots Enemies"
        if ns.EnemyBGFaction then
            titleText = titleText .. " - " .. ns.EnemyBGFaction
        end

        if visibleCount > 0 then
            Title:SetText(titleText .. " (" .. visibleCount .. ")")
            BGTFrame:SetHeight(math.abs(yOffset) + 25)
        else
            Title:SetText(titleText)
            BGTFrame:SetHeight(70)
        end
        
        local _, instanceType = IsInInstance()
        if instanceType == "pvp" then
            local zName = GetRealZoneText() or GetZoneText()
            if zName and zName ~= "" then 
                ZoneTitle:SetText(zName) 
            else
                ZoneTitle:SetText("")
            end
        else
            ZoneTitle:SetText("")
        end
    end
end

ns.ForceUIRefresh = RenderUI

local function AlertVisibleStealther(shortName)
    local now = GetTime()
    if not stealthAlertCache[shortName] or (now - stealthAlertCache[shortName] > 15) then
        stealthAlertCache[shortName] = now
        ns.TriggerRedFlash()
        print("|cffff0000[Incahoots ALERT]|r: Stealther " .. shortName .. " is VISIBLE near you!")
    end
end

-- =========================================================================
-- SPAM-FILTER SAFE CHAT QUEUE ENGINE
-- =========================================================================
local chatQueue = {}
local chatTimer = 0

-- 7. REPORTING SCRIPTS
ReportHealsBtn:SetScript("OnClick", function()
    if not UnitInBattleground("player") then return end
    if currentEnemies[1] and currentEnemies[1].healing > 0 then
        table.insert(chatQueue, "--- Incahoots Enemy Healers ---")
        for i = 1, 3 do
            local data = currentEnemies[i]
            if data and data.category == "Healer" and data.healing > 0 then
                local className = data.classToken and (data.classToken:sub(1,1) .. data.classToken:sub(2):lower()) or "Unknown"
                table.insert(chatQueue, i .. ". " .. data.shortName .. " [" .. className .. "] - " .. FormatStat(data.healing) .. " healing")
            end
        end
    end
end)

ReportDPSBtn:SetScript("OnClick", function()
    if not UnitInBattleground("player") then return end
    local dpsCandidates = {}
    for i = 1, GetNumBattlefieldScores() do
        local name, _, _, _, _, _, _, _, _, classToken, damageDone = GetBattlefieldScore(i)
        if name then
            local shortName = string.match(name, "([^%-]+)") or name
            if not myTeam[shortName] then table.insert(dpsCandidates, { shortName = shortName, classToken = classToken, damage = damageDone or 0 }) end
        end
    end
    table.sort(dpsCandidates, function(a, b) return a.damage > b.damage end)
    if dpsCandidates[1] and dpsCandidates[1].damage > 0 then
        table.insert(chatQueue, "--- Incahoots Top 3 Enemy DPS ---")
        for i = 1, 3 do
            if dpsCandidates[i] and dpsCandidates[i].damage > 0 then
                local className = dpsCandidates[i].classToken and (dpsCandidates[i].classToken:sub(1,1) .. dpsCandidates[i].classToken:sub(2):lower()) or "Unknown"
                table.insert(chatQueue, i .. ". " .. dpsCandidates[i].shortName .. " [" .. className .. "] - " .. FormatStat(dpsCandidates[i].damage) .. " dmg")
            end
        end
    end
end)

ReportCompBtn:SetScript("OnClick", function()
    if not UnitInBattleground("player") then return end
    
    local classCounts = {}
    for i = 1, GetNumBattlefieldScores() do
        local name, _, _, _, _, _, _, _, _, classToken = GetBattlefieldScore(i)
        if name then
            local shortName = string.match(name, "([^%-]+)") or name
            if not myTeam[shortName] and classToken then
                classCounts[classToken] = (classCounts[classToken] or 0) + 1
            end
        end
    end
    
    local classNames = {
        ["WARRIOR"] = "Warriors", ["PALADIN"] = "Paladins", ["HUNTER"] = "Hunters",
        ["ROGUE"] = "Rogues", ["PRIEST"] = "Priests", ["DEATHKNIGHT"] = "DKs",
        ["SHAMAN"] = "Shamans", ["MAGE"] = "Mages", ["WARLOCK"] = "Warlocks",
        ["DRUID"] = "Druids"
    }
    
    local sortedClasses = {}
    for token, count in pairs(classCounts) do
        table.insert(sortedClasses, {token = token, count = count})
    end
    
    table.sort(sortedClasses, function(a, b) return a.count > b.count end)
    
    if #sortedClasses > 0 then
        table.insert(chatQueue, "--- Incahoots Enemy Comp ---")
        for i, data in ipairs(sortedClasses) do
            local cName = classNames[data.token] or data.token
            table.insert(chatQueue, data.count .. " " .. cName)
        end
    else
        print("|cff00ffff[Incahoots]|r No enemy data available yet. Please wait for the scoreboard to populate.")
    end
end)

ReportRogueBtn:SetScript("OnClick", function()
    if not UnitInBattleground("player") then return end
    SendChatMessage("ROGUE NEARBY! Keep your eyes open!", "SAY")
end)

-- MULTI-LINE TOTALS BUTTON USING CHAT QUEUE
ReportTotalsBtn:SetScript("OnClick", function()
    if not UnitInBattleground("player") then return end
    
    local function FormatStatChat(val)
        local amount = tonumber(val) or 0
        if amount == 0 then return "0" end
        if amount >= 1000000 then return string.format("%.2fm", amount / 1000000) end
        if amount >= 1000 then return string.format("%.1fk", amount / 1000) end
        return tostring(amount)
    end

    local fk = tostring(tonumber(ns.FriendlyKills) or 0)
    local fh = FormatStatChat(ns.FriendlyHeals)
    local fd = FormatStatChat(ns.FriendlyDmg)
    
    local ek = tostring(tonumber(ns.EnemyKills) or 0)
    local eh = FormatStatChat(ns.EnemyHeals)
    local ed = FormatStatChat(ns.EnemyDmg)

    table.insert(chatQueue, "--- Incahoots BG Totals ---")
    table.insert(chatQueue, "Friendly: " .. fk .. " Kills, " .. fh .. " Heals, " .. fd .. " Dmg")
    table.insert(chatQueue, "Enemy: " .. ek .. " Kills, " .. eh .. " Heals, " .. ed .. " Dmg")
end)

local updateTimer = 0
local scanTimer = 0

BGFrame:SetScript("OnUpdate", function(self, elapsed)
    if UnitInBattleground("player") then
        updateTimer = updateTimer + elapsed
        scanTimer = scanTimer + elapsed
        
        -- Process the Chat Queue
        if #chatQueue > 0 then
            chatTimer = chatTimer + elapsed
            if chatTimer >= 0.75 then
                SendChatMessage(table.remove(chatQueue, 1), "BATTLEGROUND")
                chatTimer = 0
            end
        end

        if scanTimer >= 0.5 then
            if PassiveLevelScan() then RenderUI() end
            scanTimer = 0
        end

        if updateTimer >= 1.0 then
            RequestBattlefieldScoreData()
            updateTimer = 0
        end
    end
end)

BGFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then ApplyElvUISkin(); return end

    if event == "PLAYER_ENTERING_WORLD" then
        if not InCombatLockdown() then ClearEnemies() end
        if UnitInBattleground("player") then RequestBattlefieldScoreData() end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if pendingSort then RenderUI(); pendingSort = false end
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    if event == "UPDATE_BATTLEFIELD_SCORE" then
        local tKills, tHeals, tDmg = 0, 0, 0
    
        wipe(myTeam)
        local myName = UnitName("player")
        myTeam[myName] = true
        
        local numRaid = GetNumRaidMembers()
        if numRaid > 0 then
            for i = 1, GetNumRaidMembers() do
                local rName = UnitName("raid"..i)
                if rName then myTeam[string.match(rName, "([^%-]+)") or rName] = true end
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                local pName = UnitName("party"..i)
                if pName then myTeam[string.match(pName, "([^%-]+)") or pName] = true end
            end
        end

        -- Calculates Team Totals whether you are in combat or not
        for i = 1, GetNumBattlefieldScores() do
            local name, kills, _, _, _, _, _, _, _, classToken, damageDone, healingDone = GetBattlefieldScore(i)
            if name then
                local shortName = string.match(name, "([^%-]+)") or name
                if not myTeam[shortName] then
                    tKills = tKills + (kills or 0)
                    tHeals = tHeals + (healingDone or 0)
                    tDmg = tDmg + (damageDone or 0)
                end
            end
        end
        
        -- Save team totals to the shared 'ns' table so the Button can read them
        ns.EnemyKills = tKills
        ns.EnemyHeals = tHeals
        ns.EnemyDmg = tDmg

        -- Update the footer immediately
        if tKills > 0 or tHeals > 0 or tDmg > 0 then
            EnemyTotalsText:SetText(string.format("Kills: %d   Heals: |cff00ff00%s|r   Dmg: |cffffb200%s|r", tKills, FormatStat(tHeals), FormatStat(tDmg)))
        else
            EnemyTotalsText:SetText("")
        end

        -- IN-COMBAT STAT UPDATE
        if InCombatLockdown() then
            for i = 1, GetNumBattlefieldScores() do
                local name, kills, _, _, _, _, _, _, _, classToken, damageDone, healingDone = GetBattlefieldScore(i)
                if name then
                    local shortName = string.match(name, "([^%-]+)") or name
                    for _, data in ipairs(currentEnemies) do
                        if data.shortName == shortName then
                            data.damage = damageDone or 0
                            data.healing = healingDone or 0
                            data.kills = kills or 0
                            break
                        end
                    end
                end
            end
            RenderUI()
            return
        end
        
        local healerCandidates = {}
        local rogueCandidates = {}
        local others = {}
        wipe(ns.CarryDB)

        ns.MyBGFaction = nil
        ns.EnemyBGFaction = nil

        for i = 1, GetNumBattlefieldScores() do
            local name, kills, _, deaths, _, faction, _, _, _, classToken, damageDone, healingDone = GetBattlefieldScore(i)
            if name then
                local shortName = string.match(name, "([^%-]+)") or name

                if shortName == myName then
                    ns.MyBGFaction = (faction == 0) and "Horde" or "Alliance"
                    ns.EnemyBGFaction = (faction == 0) and "Alliance" or "Horde"
                end

                if not myTeam[shortName] then
                    local carryFlag = false
                    if kills and deaths and kills >= 6 then
                        if (kills / math.max(1, deaths)) >= 3.0 then
                            carryFlag = true
                            ns.CarryDB[shortName] = true
                        end
                    end

                    local healVal = healingDone or 0
                    local dmgVal = damageDone or 0
                    local data = { fullName = name, shortName = shortName, classToken = classToken, healing = healVal, damage = dmgVal, kills = kills or 0, faction = faction, isCarry = carryFlag }
                    if classToken == "ROGUE" or classToken == "DRUID" then if not stealthCache[shortName] then stealthCache[shortName] = "Unknown" end end
                    
                    -- Pure classless check: is healing greater than damage, with at least a minor threshold to filter accidental heals?
                    if healVal > 5000 and healVal > dmgVal then 
                        table.insert(healerCandidates, data)
                    elseif classToken == "ROGUE" then 
                        table.insert(rogueCandidates, data)
                    else 
                        table.insert(others, data) 
                    end
                end
            end
        end

        table.sort(healerCandidates, function(a, b) if a.healing == b.healing then return a.shortName < b.shortName end return a.healing > b.healing end)
        table.sort(rogueCandidates, function(a, b) if a.damage == b.damage then return a.shortName < b.shortName end return a.damage > b.damage end)
        table.sort(others, function(a, b) if a.damage == b.damage then return a.shortName < b.shortName end return a.damage > b.damage end)

        wipe(currentEnemies)
        local index = 1

        for i = 1, #healerCandidates do
            if index > numRows then break end
            local d = healerCandidates[i]; d.category = "Healer"; currentEnemies[index] = d; index = index + 1
        end

        for i = 1, #rogueCandidates do
            if index > numRows then break end
            local d = rogueCandidates[i]; d.category = "Rogue"; currentEnemies[index] = d; index = index + 1
        end
        
        table.sort(others, function(a, b) if a.damage == b.damage then return a.shortName < b.shortName end return a.damage > b.damage end)

        for _, d in ipairs(others) do
            if index > numRows then break end
            d.category = "Other"; currentEnemies[index] = d; index = index + 1
        end

        RenderUI()
        return
    end

    if event == "UPDATE_MOUSEOVER_UNIT" then
        local targetName = UnitName("mouseover")
        if targetName and UnitIsEnemy("player", "mouseover") then
            local shortTarget = string.match(targetName, "([^%-]+)") or targetName
            local lvl = UnitLevel("mouseover")
            if lvl and (lvl > 0 or lvl == -1) then
                if levelCache[shortTarget] ~= lvl then levelCache[shortTarget] = lvl; RenderUI() end
            end
        end
        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        local targetName = UnitName("target")
        if targetName and UnitIsEnemy("player", "target") then
            local shortTarget = string.match(targetName, "([^%-]+)") or targetName
            local lvl = UnitLevel("target")
            if lvl and (lvl > 0 or lvl == -1) then levelCache[shortTarget] = lvl end
            if stealthCache[shortTarget] then stealthCache[shortTarget] = "Visible"; AlertVisibleStealther(shortTarget) end
        end
        RenderUI(); return
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, combatEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = select(1, ...)

        if hardCCSpells[spellName] and destName then
            local shortDest = string.match(destName, "([^%-]+)") or destName
            if not myTeam[shortDest] then
                if combatEvent == "SPELL_AURA_APPLIED" or combatEvent == "SPELL_AURA_REFRESH" then ccCache[shortDest] = true; RenderUI()
                elseif combatEvent == "SPELL_AURA_REMOVED" then ccCache[shortDest] = nil; RenderUI() end
            end
        end

        if combatEvent == "SPELL_AURA_APPLIED" and spellName == "Sap" and destName then
            local myName = UnitName("player")
            local shortDest = string.match(destName, "([^%-]+)") or destName
            local shortSource = sourceName and (string.match(sourceName, "([^%-]+)") or sourceName) or "A Rogue"
            
            if shortDest == myName then
                ns.TriggerRedFlash()
                SendChatMessage(myName .. " has been sapped by " .. shortSource .. "!", "SAY")
                if stealthCache[shortSource] then stealthCache[shortSource] = "Stealthed"; RenderUI() end
            elseif myTeam[shortDest] then
                local targetUnitID = nil
                if GetNumRaidMembers() > 0 then
                    for i = 1, GetNumRaidMembers() do
                        local rName = UnitName("raid"..i)
                        if rName and (string.match(rName, "([^%-]+)") or rName) == shortDest then targetUnitID = "raid"..i; break end
                    end
                elseif GetNumPartyMembers() > 0 then
                    for i = 1, GetNumPartyMembers() do
                        local pName = UnitName("party"..i)
                        if pName and (string.match(pName, "([^%-]+)") or pName) == shortDest then targetUnitID = "party"..i; break end
                    end
                end

                if targetUnitID and CheckInteractDistance(targetUnitID, 4) then
                    SendChatMessage(shortDest .. " has been sapped nearby by " .. shortSource .. "!", "SAY")
                    if stealthCache[shortSource] then stealthCache[shortSource] = "Stealthed"; RenderUI() end
                end
            end
        end

        if sourceName then
            local shortSource = string.match(sourceName, "([^%-]+)") or sourceName
            if stealthCache[shortSource] then
                local isStealthSpell = spellName and stealthSpells[spellName]
                if combatEvent == "SPELL_AURA_APPLIED" and isStealthSpell then stealthCache[shortSource] = "Stealthed"; RenderUI()
                elseif combatEvent == "SPELL_AURA_REMOVED" and isStealthSpell then stealthCache[shortSource] = "Visible"; RenderUI(); AlertVisibleStealther(shortSource)
                elseif combatEvent ~= "SPELL_AURA_APPLIED" and combatEvent ~= "SPELL_AURA_REMOVED" then
                    if spellName ~= "Sap" then
                        if stealthCache[shortSource] ~= "Visible" then stealthCache[shortSource] = "Visible"; RenderUI() end
                        AlertVisibleStealther(shortSource)
                    end
                end
            end
        end
        
        if combatEvent == "UNIT_DIED" and destName then
            local shortDest = string.match(destName, "([^%-]+)") or destName
            if stealthCache[shortDest] then stealthCache[shortDest] = "Unknown" end
            if ns.FlagCarriers and ns.FlagCarriers[shortDest] then ns.FlagCarriers[shortDest] = nil end
            if ccCache[shortDest] then ccCache[shortDest] = nil end
            RenderUI()
        end
    end
end)