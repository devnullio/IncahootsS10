local addonName, ns = ...

-- 1. NUKE THE DEFAULT BLIZZARD FRAMES
for i = 1, 4 do
    local frame = _G["PartyMemberFrame"..i]
    if frame then
        frame:UnregisterAllEvents()
        frame:Hide()
        frame.Show = function() end 
    end
end
if PlayerFrame then
    PlayerFrame:UnregisterAllEvents()
    PlayerFrame:Hide()
    PlayerFrame.Show = function() end
end

-- 2. DYNAMIC CONTAINER FRAME
local PartyContainer = CreateFrame("Frame", "IncahootsPartyContainer", UIParent, "BackdropTemplate")
PartyContainer:SetPoint("LEFT", UIParent, "LEFT", 50, 0)
PartyContainer:SetFrameStrata("LOW")
PartyContainer:EnableMouse(true)
PartyContainer:SetMovable(true)
PartyContainer:SetClampedToScreen(true)
PartyContainer:RegisterForDrag("LeftButton")
PartyContainer:SetScript("OnDragStart", PartyContainer.StartMoving)
PartyContainer:SetScript("OnDragStop", PartyContainer.StopMovingOrSizing)

PartyContainer:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
PartyContainer:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
PartyContainer:SetBackdropBorderColor(0, 0, 0, 1)

local ZoneTitle = PartyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ZoneTitle:SetPoint("BOTTOM", PartyContainer, "TOP", 0, 4)
ZoneTitle:SetText("")
ZoneTitle:SetTextColor(1, 0.82, 0)

local Title = PartyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Title:SetPoint("TOP", PartyContainer, "TOP", 0, -6)
Title:SetText("Incahoots Team")
Title:SetTextColor(1, 1, 1)

-- SORTING LABELS
local HealerLabel = PartyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
HealerLabel:SetText("Friendly Healers")
HealerLabel:SetTextColor(0, 1, 0)
HealerLabel:Hide()

local OtherLabel = PartyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
OtherLabel:SetText("Friendly DPS")
OtherLabel:SetTextColor(0.8, 0.8, 0.8)
OtherLabel:Hide()

-- TOTALS FOOTER
local TeamTotalsText = PartyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TeamTotalsText:SetPoint("BOTTOM", PartyContainer, "BOTTOM", 0, 8)
TeamTotalsText:SetTextColor(1, 1, 1)
TeamTotalsText:Hide()

-- 3. THE ELVUI BYPASS WRAPPERS
local PartyWrapper = CreateFrame("Frame", nil, PartyContainer)
PartyWrapper:SetPoint("TOPLEFT", PartyContainer, "TOPLEFT", 5, -25)
PartyWrapper:SetSize(209, 20)
PartyWrapper.buttons = {}
RegisterStateDriver(PartyWrapper, "visibility", "[group:raid] hide; show")

local RaidWrapper = CreateFrame("Frame", nil, PartyContainer)
RaidWrapper:SetPoint("TOPLEFT", PartyContainer, "TOPLEFT", 5, -25)
RaidWrapper:SetSize(423, 20)
RaidWrapper.buttons = {}
RegisterStateDriver(RaidWrapper, "visibility", "[group:raid] show; hide")

-- NUMBER FORMATTER (e.g., 1500 -> 1.5k)
local function FormatStat(amount)
    local amt = tonumber(amount) or 0
    if amt == 0 then return "" end
    if amt >= 1000000 then return string.format("%.2fm", amt / 1000000) end
    if amt >= 1000 then return string.format("%.1fk", amt / 1000) end
    return tostring(amt)
end

-- 4. BUTTON CREATOR AND SKINNER
local function CreateIncahootsButton(parent, unitID)
    local btn = CreateFrame("Button", nil, parent, "SecureUnitButtonTemplate")
    btn:SetSize(209, 20)
    
    btn:SetAttribute("unit", unitID)
    btn:SetAttribute("type1", "target")
    btn:SetAttribute("type2", "togglemenu")
    RegisterStateDriver(btn, "visibility", "[@" .. unitID .. ",exists] show; hide")

    btn.classIcon = btn:CreateTexture(nil, "OVERLAY")
    btn.classIcon:SetSize(20, 20)
    btn.classIcon:SetPoint("LEFT", btn, "LEFT", 0, 0)
    btn.classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")

    btn.hpBar = CreateFrame("StatusBar", nil, btn)
    btn.hpBar:SetPoint("TOPLEFT", btn, "TOPLEFT", 22, 0)
    btn.hpBar:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    btn.hpBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    btn.hpBar:SetMinMaxValues(0, 100)
    btn.hpBar:SetValue(100)
    
    btn.hpBg = btn.hpBar:CreateTexture(nil, "BACKGROUND")
    btn.hpBg:SetAllPoints(btn.hpBar)
    btn.hpBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    btn.hpBg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    btn.levelText = btn.hpBar:CreateFontString(nil, "OVERLAY")
    btn.levelText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    btn.levelText:SetPoint("LEFT", btn.hpBar, "LEFT", 3, 0)

    btn.nameText = btn.hpBar:CreateFontString(nil, "OVERLAY")
    btn.nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    btn.nameText:SetPoint("LEFT", btn.hpBar, "LEFT", 22, 0)
    btn.nameText:SetTextColor(1, 1, 1)

    btn.flagIcon = btn.hpBar:CreateTexture(nil, "OVERLAY")
    btn.flagIcon:SetSize(18, 18)
    btn.flagIcon:SetPoint("LEFT", btn.nameText, "RIGHT", 4, 0)
    btn.flagIcon:Hide()

    btn.killText = btn.hpBar:CreateFontString(nil, "OVERLAY")
    btn.killText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    btn.killText:SetPoint("RIGHT", btn.hpBar, "RIGHT", -20, 0)
    btn.killText:SetJustifyH("RIGHT")

    btn.statText = btn.hpBar:CreateFontString(nil, "OVERLAY")
    btn.statText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    btn.statText:SetPoint("RIGHT", btn.hpBar, "RIGHT", -45, 0)
    btn.statText:SetJustifyH("RIGHT")

    btn.targetIcon = btn.hpBar:CreateTexture(nil, "OVERLAY")
    btn.targetIcon:SetSize(16, 16)
    btn.targetIcon:SetPoint("RIGHT", btn.hpBar, "RIGHT", -2, 0)
    btn.targetIcon:SetTexture("Interface\\Minimap\\Tracking\\Target") 
    btn.targetIcon:Hide()

    return btn
end

-- 5. GENERATE THE ROSTERS
local partyUnits = {"player", "party1", "party2", "party3", "party4"}
for i, unit in ipairs(partyUnits) do
    local btn = CreateIncahootsButton(PartyWrapper, unit)
    table.insert(PartyWrapper.buttons, btn)
end

for i = 1, 40 do
    local btn = CreateIncahootsButton(RaidWrapper, "raid"..i)
    table.insert(RaidWrapper.buttons, btn)
end

-- 6. DATA UPDATE LOOP & SORTING
local updateFrame = CreateFrame("Frame")
local updateTimer = 0
local bgScoreTimer = 0
local friendlyStats = {}

-- Clears data seamlessly when zoning into a new Battleground
updateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
updateFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        wipe(friendlyStats)
        ns.FriendlyKills, ns.FriendlyHeals, ns.FriendlyDmg = 0, 0, 0
        TeamTotalsText:SetText("")
    end
end)

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

local function GetUnitSortOrder(unit)
    if not unit then return 999 end
    if unit == "player" then return 0 end
    local num = string.match(unit, "%d+")
    if string.find(unit, "party") then return tonumber(num) or 99 end
    if string.find(unit, "raid") then return 100 + (tonumber(num) or 99) end
    return 999
end

local function GetButtonStats(btn)
    local unit = btn:GetAttribute("unit")
    local name = UnitName(unit)
    local shortName = name and string.match(name, "([^%-]+)") or name
    local stats = friendlyStats[shortName]
    if stats then return stats end
    return { category = "Other", healing = 0, damage = 0, kills = 0, name = shortName or "" }
end

updateFrame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed
    bgScoreTimer = bgScoreTimer + elapsed
    
    -- Ping the BG Scoreboard every 3 seconds to cache performance
    if bgScoreTimer >= 3.0 then
        bgScoreTimer = 0
        if UnitInBattleground("player") then
            RequestBattlefieldScoreData()
            wipe(friendlyStats)
            
            local tKills, tHeals, tDmg = 0, 0, 0
            local myTeamCheck = {}
            local myName = UnitName("player")
            myTeamCheck[myName] = true
            
            if GetNumRaidMembers() > 0 then
                for i = 1, GetNumRaidMembers() do
                    local rName = UnitName("raid"..i)
                    if rName then myTeamCheck[string.match(rName, "([^%-]+)") or rName] = true end
                end
            elseif GetNumPartyMembers() > 0 then
                for i = 1, GetNumPartyMembers() do
                    local pName = UnitName("party"..i)
                    if pName then myTeamCheck[string.match(pName, "([^%-]+)") or pName] = true end
                end
            end

            for i = 1, GetNumBattlefieldScores() do
                local name, kills, _, _, _, _, _, _, _, classToken, damageDone, healingDone = GetBattlefieldScore(i)
                if name then
                    local shortName = string.match(name, "([^%-]+)") or name
                    
                    if myTeamCheck[shortName] then
                        local healVal = healingDone or 0
                        local dmgVal = damageDone or 0
                        
                        tKills = tKills + (kills or 0)
                        tHeals = tHeals + healVal
                        tDmg = tDmg + dmgVal
                        
                        -- Pure classless check: is healing greater than damage, with at least a minor threshold to filter accidental heals?
                        local category = "Other"
                        if healVal > 5000 and healVal > dmgVal then
                            category = "Healer"
                        end
                        
                        friendlyStats[shortName] = {
                            category = category,
                            healing = healVal,
                            damage = dmgVal,
                            kills = kills or 0,
                            name = shortName
                        }
                    end
                end
            end
            
            -- Save team totals to the shared 'ns' table so the Enemy frame can read them
            ns.FriendlyKills = tKills
            ns.FriendlyHeals = tHeals
            ns.FriendlyDmg = tDmg
            
            if tKills > 0 or tHeals > 0 or tDmg > 0 then
                TeamTotalsText:SetText(string.format("Kills: %d   Heals: |cff00ff00%s|r   Dmg: |cffffb200%s|r", tKills, FormatStat(tHeals), FormatStat(tDmg)))
            else
                TeamTotalsText:SetText("")
            end
        end
    end
    
    -- Engine (0.2s refresh)
    if updateTimer >= 0.2 then
        updateTimer = 0
        
        local isBG = UnitInBattleground("player")
        local isRaid = GetNumRaidMembers() > 0
        local activeWrapper = isRaid and RaidWrapper or PartyWrapper
        local currentTarget = UnitName("target")
        
        if isBG then TeamTotalsText:Show() else TeamTotalsText:Hide() end
        
        local visibleButtons = {}
        for _, btn in ipairs(activeWrapper.buttons) do
            if UnitExists(btn:GetAttribute("unit")) then
                table.insert(visibleButtons, btn)
            end
        end
        
        local activeCount = #visibleButtons

        if activeCount > 0 then
            -- LAYOUT PIPELINE (Frozen while in combat to prevent taint/crashes)
            if not InCombatLockdown() then
                -- Tactical Sorting
                if isBG then
                    table.sort(visibleButtons, function(a, b)
                        local statA = GetButtonStats(a)
                        local statB = GetButtonStats(b)
                        
                        local catA = (statA.category == "Healer") and 1 or 2
                        local catB = (statB.category == "Healer") and 1 or 2
                        
                        if catA ~= catB then return catA < catB end
                        
                        if statA.category == "Healer" then
                            if statA.healing == statB.healing then return statA.name < statB.name end
                            return statA.healing > statB.healing
                        else
                            if statA.damage == statB.damage then return statA.name < statB.name end
                            return statA.damage > statB.damage
                        end
                    end)
                else
                    table.sort(visibleButtons, function(a, b)
                        return GetUnitSortOrder(a:GetAttribute("unit")) < GetUnitSortOrder(b:GetAttribute("unit"))
                    end)
                end

                HealerLabel:Hide()
                OtherLabel:Hide()

                -- Layout Variables
                local totalElements = activeCount + (isBG and 2 or 0)
                local maxPerCol = (isRaid and activeCount > 20) and math.ceil(totalElements / 2) or 100
                
                local xOff = 0
                local yOff = 0
                local currentCategory = nil
                local itemsInCurrentColumn = 0
                local totalHeight = 0
                local colsUsed = 1
                local shownLabels = {}

                -- Draw the Interface
                for i, btn in ipairs(visibleButtons) do
                    local stat = isBG and GetButtonStats(btn) or {category = "None"}
                    
                    if itemsInCurrentColumn >= maxPerCol then
                        xOff = xOff + 214 -- 209 width + 5 padding
                        yOff = 0
                        itemsInCurrentColumn = 0
                        colsUsed = colsUsed + 1
                    end
                    
                    if isBG and stat.category ~= currentCategory then
                        if currentCategory and itemsInCurrentColumn > 0 then yOff = yOff - 5 end
                        
                        local label = (stat.category == "Healer") and HealerLabel or OtherLabel
                        if not shownLabels[stat.category] then
                            label:ClearAllPoints()
                            label:SetPoint("TOPLEFT", activeWrapper, "TOPLEFT", xOff + 5, yOff)
                            label:Show()
                            shownLabels[stat.category] = true
                            yOff = yOff - 16
                            itemsInCurrentColumn = itemsInCurrentColumn + 1
                        end
                        currentCategory = stat.category
                    end

                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", activeWrapper, "TOPLEFT", xOff, yOff)
                    yOff = yOff - 21
                    itemsInCurrentColumn = itemsInCurrentColumn + 1
                    
                    if math.abs(yOff) > totalHeight then totalHeight = math.abs(yOff) end
                end
                
                local totalWidth = (colsUsed * 209) + ((colsUsed - 1) * 5) + 10
                
                -- Expanded height to make room for the Totals footer if in a BG
                local extraHeight = isBG and 50 or 35
                PartyContainer:SetSize(totalWidth, totalHeight + extraHeight)
                PartyContainer:Show()
            end

            -- VISUALS PIPELINE (Always runs instantly, even in combat)
            for i, btn in ipairs(visibleButtons) do
                local stat = isBG and GetButtonStats(btn) or {category = "None"}
                local unit = btn:GetAttribute("unit")
                local name = UnitName(unit)
                local shortName = name and string.match(name, "([^%-]+)") or name
                
                btn.nameText:SetText(name or "Unknown")
                
                if ns.FlagCarriers and ns.FlagCarriers[shortName] then
                    btn.flagIcon:SetTexture(ns.FlagCarriers[shortName])
                    btn.flagIcon:Show()
                else
                    btn.flagIcon:Hide()
                end
                
                local lvl = UnitLevel(unit)
                if lvl and lvl > 0 then
                    btn.levelText:SetText(lvl)
                    local r, g, b = GetLevelColor(lvl)
                    btn.levelText:SetTextColor(r, g, b)
                else
                    btn.levelText:SetText("??")
                    btn.levelText:SetTextColor(0.8, 0.8, 0.8)
                end
                
                local _, classToken = UnitClass(unit)
                if classToken and RAID_CLASS_COLORS[classToken] then
                    local c = RAID_CLASS_COLORS[classToken]
                    btn.hpBar:SetStatusBarColor(c.r, c.g, c.b)
                    if CLASS_ICON_TCOORDS[classToken] then
                        btn.classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classToken]))
                        btn.classIcon:Show()
                    end
                else
                    btn.hpBar:SetStatusBarColor(0.5, 0.5, 0.5)
                    btn.classIcon:Hide()
                end
                
                local curHp = UnitHealth(unit)
                local maxHp = UnitHealthMax(unit)
                if maxHp > 0 then
                    btn.hpBar:SetMinMaxValues(0, maxHp)
                    btn.hpBar:SetValue(curHp)
                    
                    if isBG then
                        btn.killText:SetText(stat.kills or 0)
                        if stat.category == "Healer" then
                            btn.statText:SetText(FormatStat(stat.healing))
                            btn.statText:SetTextColor(0, 1, 0)
                            btn.killText:SetTextColor(0, 1, 0)
                        else
                            btn.statText:SetText(FormatStat(stat.damage))
                            btn.statText:SetTextColor(1, 0.7, 0) 
                            btn.killText:SetTextColor(1, 0.7, 0)
                        end
                    else
                        btn.killText:SetText("")
                        local deficit = maxHp - curHp
                        if deficit > 0 then
                            if deficit >= 1000 then btn.statText:SetText(string.format("-%.1fk", deficit / 1000))
                            else btn.statText:SetText("-" .. deficit) end
                            btn.statText:SetTextColor(1, 0.5, 0.5) 
                        else 
                            btn.statText:SetText("") 
                        end
                    end
                end

                if currentTarget and name == currentTarget then btn.targetIcon:Show() else btn.targetIcon:Hide() end
                if UnitIsUnit(unit, "player") or UnitInRange(unit) then btn:SetAlpha(1.0) else btn:SetAlpha(0.4) end
            end
        else
            if not InCombatLockdown() then
                PartyContainer:Hide()
                HealerLabel:Hide()
                OtherLabel:Hide()
            end
        end
        
        -- Frame Title Updates (Safe in combat)
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

        local titlePrefix = "Incahoots Team"
        if ns.MyBGFaction then
            titlePrefix = titlePrefix .. " - " .. ns.MyBGFaction
        end

        Title:SetText(titlePrefix .. " (" .. activeCount .. ")")
    end
end)

local function ApplyElvUISkin()
    if IsAddOnLoaded("ElvUI") then
        local E = unpack(ElvUI)
        if E then
            PartyContainer:SetBackdrop(nil)
            PartyContainer:SetTemplate("Transparent")
            local normTex = E.media.normTex
            for _, btn in ipairs(PartyWrapper.buttons) do
                btn.hpBar:SetStatusBarTexture(normTex)
            end
            for _, btn in ipairs(RaidWrapper.buttons) do
                btn.hpBar:SetStatusBarTexture(normTex)
            end
        end
    end
end
local skinFrame = CreateFrame("Frame")
skinFrame:RegisterEvent("PLAYER_LOGIN")
skinFrame:SetScript("OnEvent", ApplyElvUISkin)