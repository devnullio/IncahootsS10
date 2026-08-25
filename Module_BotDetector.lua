local addonName, ns = ...

local BotDetector = CreateFrame("Frame")
ns.BotDB = ns.BotDB or {}

local castCache = {}
local ccCache = {}

-- List of Hard CCs to monitor for Insta-Trinketing
local hardCCSpells = {
    ["Polymorph"] = true, ["Cyclone"] = true, ["Blind"] = true, ["Fear"] = true,
    ["Hammer of Justice"] = true, ["Sap"] = true, ["Repentance"] = true, ["Howl of Terror"] = true,
    ["Seduction"] = true, ["Psychic Scream"] = true, ["Freezing Trap"] = true, ["Hex"] = true,
    ["Intimidating Shout"] = true, ["Gouge"] = true, ["Kidney Shot"] = true, ["Cheap Shot"] = true,
    ["Strangulate"] = true, ["Bash"] = true, ["Intercept"] = true, ["Maim"] = true
}

-- 1. CREATE THE BOT WATCHLIST FRAME
local BotFrame = CreateFrame("Frame", "IncahootsBotFrame", UIParent, "BackdropTemplate")
BotFrame:SetSize(200, 100)
BotFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
BotFrame:SetFrameStrata("HIGH")
BotFrame:EnableMouse(true)
BotFrame:SetMovable(true)
BotFrame:SetClampedToScreen(true)
BotFrame:RegisterForDrag("LeftButton")
BotFrame:SetScript("OnDragStart", BotFrame.StartMoving)
BotFrame:SetScript("OnDragStop", BotFrame.StopMovingOrSizing)

BotFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
BotFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
BotFrame:SetBackdropBorderColor(0, 0, 0, 1)

local Title = BotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Title:SetPoint("TOP", BotFrame, "TOP", 0, -6)
Title:SetText("Suspected Bots")
Title:SetTextColor(1, 0.2, 0.2)

local CloseBtn = CreateFrame("Button", nil, BotFrame, "UIPanelCloseButton")
CloseBtn:SetPoint("TOPRIGHT", BotFrame, "TOPRIGHT", 2, 2)
CloseBtn:SetSize(24, 24)

local ClearBtn = CreateFrame("Button", nil, BotFrame, "UIPanelButtonTemplate")
ClearBtn:SetSize(60, 20)
ClearBtn:SetPoint("BOTTOM", BotFrame, "BOTTOM", 0, 5)
ClearBtn:SetText("Clear")

-- Generate Rows for the List
local botRows = {}
local numRows = 20

for i = 1, numRows do
    local row = BotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row:SetJustifyH("LEFT")
    row:SetSize(180, 12)
    if i == 1 then
        row:SetPoint("TOPLEFT", BotFrame, "TOPLEFT", 10, -25)
    else
        row:SetPoint("TOPLEFT", botRows[i-1], "BOTTOMLEFT", 0, -3)
    end
    row:SetText("")
    botRows[i] = row
end

local function UpdateBotFrame()
    for i = 1, numRows do botRows[i]:SetText("") end
    
    local index = 1
    for name, data in pairs(ns.BotDB) do
        if index > numRows then break end
        
        local msText = "??"
        local offenseText = "kick" -- Default to kick for older saved data
        
        if type(data) == "table" then
            if data.ms then msText = tostring(data.ms) end
            if data.offense then offenseText = data.offense end
        end
        
        botRows[index]:SetText(name .. " |cffaaaaaa(" .. msText .. "ms " .. offenseText .. ")|r")
        botRows[index]:SetTextColor(1, 1, 1)
        index = index + 1
    end
    
    if index == 1 then
        botRows[1]:SetText("No bots detected yet.")
        botRows[1]:SetTextColor(0.5, 0.5, 0.5)
        BotFrame:SetHeight(70)
    else
        BotFrame:SetHeight(30 + (index * 15) + 25) 
    end
end

ClearBtn:SetScript("OnClick", function()
    wipe(ns.BotDB)
    UpdateBotFrame()
    print("|cff00ffff[Incahoots]|r: Bot watchlist cleared.")
end)

-- 2. ELVUI COMPATIBILITY HOOK
local function ApplyElvUISkin()
    if IsAddOnLoaded("ElvUI") then
        local E = unpack(ElvUI)
        if E then
            BotFrame:SetBackdrop(nil)
            BotFrame:SetTemplate("Transparent")
            ClearBtn:StripTextures()
            ClearBtn:SetTemplate("Default", true)
        end
    end
end

-- 3. SLASH COMMAND TO TOGGLE FRAME
SLASH_INCAHOOTSBOTS1 = "/bots"
SlashCmdList["INCAHOOTSBOTS"] = function()
    if BotFrame:IsShown() then
        BotFrame:Hide()
    else
        UpdateBotFrame()
        BotFrame:Show()
    end
end

-- 4. THE SCANNER ENGINE
BotDetector:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then 
        ApplyElvUISkin()
        UpdateBotFrame()
        BotFrame:Show() 
        return 
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, combatEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = select(1, ...)

        ---------------------------------------------------
        -- TRAP 1: THE AUTO-KICK SCANNER
        ---------------------------------------------------
        if combatEvent == "SPELL_CAST_START" then
            castCache[sourceGUID] = timestamp

        elseif combatEvent == "SPELL_CAST_SUCCESS" or combatEvent == "SPELL_CAST_FAILED" then
            castCache[sourceGUID] = nil

        elseif combatEvent == "SPELL_INTERRUPT" then
            if castCache[destGUID] then
                local reactionTime = timestamp - castCache[destGUID]
                
                if reactionTime > 0 and reactionTime <= 0.05 then
                    local shortSource = sourceName and string.match(sourceName, "([^%-]+)") or "Unknown"
                    local shortDest = destName and string.match(destName, "([^%-]+)") or "Unknown"
                    local interruptedSpell = select(13, ...) or "a spell"
                    local ms = math.floor(reactionTime * 1000)

                    if not ns.BotDB[shortSource] then
                        ns.BotDB[shortSource] = { ms = ms, offense = "kick" }
                        
                        print(string.format("|cffff0000[Incahoots Anti-Cheat]|r: %s interrupted %s's %s in %dms! (Automated kick suspected)", shortSource, shortDest, interruptedSpell, ms))
                        
                        if ns.TriggerRedFlash then ns.TriggerRedFlash() end
                        if ns.ForceUIRefresh then ns.ForceUIRefresh() end
                        
                        BotFrame:Show()
                        UpdateBotFrame()
                    end
                end
                castCache[destGUID] = nil
            end
        end

        ---------------------------------------------------
        -- TRAP 2: THE AUTO-TRINKET SCANNER
        ---------------------------------------------------
        if combatEvent == "SPELL_AURA_APPLIED" then
            if hardCCSpells[spellName] then
                ccCache[destGUID] = { ts = timestamp, spell = spellName }
            end

        elseif combatEvent == "SPELL_AURA_REMOVED" then
            if hardCCSpells[spellName] and ccCache[destGUID] then
                ccCache[destGUID] = nil
            end

        elseif combatEvent == "SPELL_CAST_SUCCESS" then
            if ccCache[sourceGUID] then
                local reactionTime = timestamp - ccCache[sourceGUID].ts
                
                -- If they cast a spell within 50ms of a hard CC landing, it's a script breaking them out
                if reactionTime > 0 and reactionTime <= 0.05 then
                    local shortSource = sourceName and string.match(sourceName, "([^%-]+)") or "Unknown"
                    local ccSpell = ccCache[sourceGUID].spell or "CC"
                    local ms = math.floor(reactionTime * 1000)

                    if not ns.BotDB[shortSource] then
                        ns.BotDB[shortSource] = { ms = ms, offense = "trinket" }
                        
                        print(string.format("|cffff0000[Incahoots Anti-Cheat]|r: %s instantly broke %s in %dms! (Auto-trinket suspected)", shortSource, ccSpell, ms))
                        
                        if ns.TriggerRedFlash then ns.TriggerRedFlash() end
                        if ns.ForceUIRefresh then ns.ForceUIRefresh() end
                        
                        BotFrame:Show()
                        UpdateBotFrame()
                    end
                end
                -- Clear the cache so it doesn't trigger repeatedly for the same stun
                ccCache[sourceGUID] = nil
            end
        end
    end
end)

BotDetector:RegisterEvent("PLAYER_LOGIN")
BotDetector:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")