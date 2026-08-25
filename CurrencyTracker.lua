local addonName, ns = ...

-- 1. FRAME SETUP
local CurrFrame = CreateFrame("Frame", "IncahootsCurrencyFrame", UIParent, "BackdropTemplate")
CurrFrame:SetSize(170, 95)
CurrFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 200)
CurrFrame:SetFrameStrata("LOW")
CurrFrame:EnableMouse(true)
CurrFrame:SetMovable(true)
CurrFrame:SetClampedToScreen(true)
CurrFrame:RegisterForDrag("LeftButton")
CurrFrame:SetScript("OnDragStart", CurrFrame.StartMoving)
CurrFrame:SetScript("OnDragStop", CurrFrame.StopMovingOrSizing)

CurrFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
CurrFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
CurrFrame:SetBackdropBorderColor(0, 0, 0, 1)

-- 2. LABELS & TEXT
local Title = CurrFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Title:SetPoint("TOP", CurrFrame, "TOP", 0, -6)
Title:SetText("Incahoots Wealth")
Title:SetTextColor(1, 0.82, 0)

local function CreateRow(parent, yOffset, labelText, r, g, b)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    label:SetText(labelText)
    label:SetTextColor(r, g, b)

    local val = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    val:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, yOffset)
    val:SetText("0")
    
    return val
end

-- Colored labels for visual clarity (Gold, Green, Purple, Blue)
local honorVal = CreateRow(CurrFrame, -25, "Honor Points:", 1, 0.8, 0)
local arenaVal = CreateRow(CurrFrame, -40, "Arena Points:", 0.2, 1, 0.2)
local runeVal = CreateRow(CurrFrame, -55, "Runes of Asc:", 0.6, 0.2, 0.8) 
local tokenVal = CreateRow(CurrFrame, -70, "Tokens of Pres:", 0.2, 0.6, 1) 

-- 3. DATA UPDATE ENGINE
local function UpdateCurrencies()
    -- Native 3.3.5 PvP Currencies
    local honor = GetHonorCurrency and GetHonorCurrency() or 0
    local arena = GetArenaCurrency and GetArenaCurrency() or 0
    
    -- Ascension Items (The 'true' flag ensures it counts items in your bank too)
    local runes = GetItemCount("Rune of Ascension", true) or 0
    local tokens = GetItemCount("Token of Prestige", true) or 0

    honorVal:SetText(honor)
    arenaVal:SetText(arena)
    runeVal:SetText(runes)
    tokenVal:SetText(tokens)
end

-- 4. EVENT HOOKS
CurrFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
CurrFrame:RegisterEvent("BAG_UPDATE")
CurrFrame:RegisterEvent("HONOR_CURRENCY_UPDATE")
CurrFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
CurrFrame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")

CurrFrame:SetScript("OnEvent", function(self, event)
    UpdateCurrencies()
end)

-- Initialize ElvUI skinning if present
local function ApplyElvUISkin()
    if IsAddOnLoaded("ElvUI") then
        local E = unpack(ElvUI)
        if E then
            CurrFrame:SetBackdrop(nil)
            CurrFrame:SetTemplate("Transparent")
        end
    end
end

local LoginFrame = CreateFrame("Frame")
LoginFrame:RegisterEvent("PLAYER_LOGIN")
LoginFrame:SetScript("OnEvent", ApplyElvUISkin)