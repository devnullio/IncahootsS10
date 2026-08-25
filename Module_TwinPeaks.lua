local addonName, ns = ...

local TPFrame = CreateFrame("Frame")

-- THE FIX: An aggressive filter that strips all invisible cross-faction formatting, 
-- server names, spaces, and punctuation so the memory bank ALWAYS gets a perfect match.
local function ExtractCleanName(rawText)
    if not rawText then return nil end
    
    -- 1. Strip any custom UI color codes injected by Ascension
    local clean = string.gsub(rawText, "|c%x%x%x%x%x%x%x%x", "")
    clean = string.gsub(clean, "|r", "")
    
    -- 2. Strip server names (drops anything after a hyphen)
    clean = string.match(clean, "([^%-]+)") or clean
    
    -- 3. Strip any stray spaces, exclamation points, or periods
    clean = string.gsub(clean, "[%s!%.]", "")
    
    return clean
end

TPFrame:SetScript("OnEvent", function(self, event, msg)
    local lowerMsg = string.lower(msg)
    
    if ns.DebugMode then
        print("|cff00ffff[Twin Peaks Module Raw]|r: " .. msg)
    end
    
    -- 1. FLAG PICKUPS
    -- Safely captures everything between "by" and "!" and runs it through the buzzsaw
    if string.find(lowerMsg, "picked up by") or string.find(lowerMsg, "taken the") then
        local rawName = string.match(msg, "picked up by (.-)!") or string.match(msg, "^(.-) has taken")
        
        if rawName then
            local cleanName = ExtractCleanName(rawName)
            if cleanName then
                if string.find(lowerMsg, "horde") then
                    ns.FlagCarriers[cleanName] = "Interface\\WorldStateFrame\\HordeFlag"
                else
                    ns.FlagCarriers[cleanName] = "Interface\\WorldStateFrame\\AllianceFlag"
                end
                if ns.ForceUIRefresh then ns.ForceUIRefresh() end
            end
        end
        return
    end
    
    -- 2. FLAG DROPS
    if string.find(lowerMsg, "dropped by") then
        local rawName = string.match(msg, "dropped by (.-)!")
        
        if rawName then
            local cleanName = ExtractCleanName(rawName)
            if cleanName then
                ns.FlagCarriers[cleanName] = nil
                if ns.ForceUIRefresh then ns.ForceUIRefresh() end
            end
        end
        return
    end
    
    -- 3. CAPTURES, RETURNS & RESETS
    if string.find(lowerMsg, "captured") or string.find(lowerMsg, "returned") or string.find(lowerMsg, "reset") or string.find(lowerMsg, "placed") then
        if string.find(lowerMsg, "horde flag") then
            for k, v in pairs(ns.FlagCarriers) do
                if v == "Interface\\WorldStateFrame\\HordeFlag" then ns.FlagCarriers[k] = nil end
            end
        elseif string.find(lowerMsg, "alliance flag") then
            for k, v in pairs(ns.FlagCarriers) do
                if v == "Interface\\WorldStateFrame\\AllianceFlag" then ns.FlagCarriers[k] = nil end
            end
        else
            wipe(ns.FlagCarriers) 
        end
        
        if ns.ForceUIRefresh then ns.ForceUIRefresh() end
        return
    end
end)

local function OnEnable()
    TPFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
    TPFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
    TPFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
    TPFrame:RegisterEvent("CHAT_MSG_SYSTEM") -- Safety net for custom servers
    
    ns.FlagCarriers = ns.FlagCarriers or {}
    wipe(ns.FlagCarriers) 
end

local function OnDisable()
    TPFrame:UnregisterAllEvents()
    wipe(ns.FlagCarriers)
end

if ns.RegisterModule then
    ns.RegisterModule("Twin Peaks", OnEnable, OnDisable)
end