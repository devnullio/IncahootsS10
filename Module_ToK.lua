local addonName, ns = ...

local ToKFrame = CreateFrame("Frame")

-- Map the exact Ascension spell names to the WoW orb icons
local orbTextures = {
    ["Orb of Power: Red"] = "Interface\\Icons\\INV_Misc_Orb_01",
    ["Orb of Power: Orange"] = "Interface\\Icons\\INV_Misc_Orb_02",
    ["Orb of Power: Green"] = "Interface\\Icons\\INV_Misc_Orb_03",
    ["Orb of Power: Blue"] = "Interface\\Icons\\INV_Misc_Orb_04",
    ["Orb of Power: Purple"] = "Interface\\Icons\\INV_Misc_Orb_05"
}

-- Helper function to ensure we don't announce when a teammate picks up an orb
local function IsFriendly(name)
    local myName = UnitName("player")
    if name == myName then return true end
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local rName = UnitName("raid"..i)
            if rName and (string.match(rName, "([^%-]+)") or rName) == name then return true end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local pName = UnitName("party"..i)
            if pName and (string.match(pName, "([^%-]+)") or pName) == name then return true end
        end
    end
    return false
end

ToKFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, combatEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = select(1, ...)
        
        if not spellName or not orbTextures[spellName] then return end
        
        -- 1. INITIAL ORB PICKUP (Silent UI update only - Chat Announcements Removed)
        if combatEvent == "SPELL_AURA_APPLIED" then
            if destName then
                local cleanName = string.match(destName, "([^%-]+)") or destName
                ns.FlagCarriers[cleanName] = orbTextures[spellName]
                
                if ns.ForceUIRefresh then ns.ForceUIRefresh() end
            end
            return
        end

        -- 2. ORB DOSES (Silent UI Refresh Only)
        if combatEvent == "SPELL_AURA_APPLIED_DOSE" then
            if destName then
                local cleanName = string.match(destName, "([^%-]+)") or destName
                ns.FlagCarriers[cleanName] = orbTextures[spellName]
                if ns.ForceUIRefresh then ns.ForceUIRefresh() end
            end
            return
        end
        
        -- 3. ORB DROP OR DEATH
        if combatEvent == "SPELL_AURA_REMOVED" then
            if destName then
                local cleanName = string.match(destName, "([^%-]+)") or destName
                ns.FlagCarriers[cleanName] = nil
                if ns.ForceUIRefresh then ns.ForceUIRefresh() end
            end
            return
        end
    end
    
    if event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        local msg = string.lower(select(1, ...))
        if string.find(msg, "reset") or string.find(msg, "returned") then
            wipe(ns.FlagCarriers)
            if ns.ForceUIRefresh then ns.ForceUIRefresh() end
        end
    end
end)

local function OnEnable()
    ToKFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    ToKFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
    ns.FlagCarriers = ns.FlagCarriers or {}
    wipe(ns.FlagCarriers) 
end

local function OnDisable()
    ToKFrame:UnregisterAllEvents()
    wipe(ns.FlagCarriers)
end

if ns.RegisterModule then
    ns.RegisterModule("The Temple of Kotmogu", OnEnable, OnDisable)
end