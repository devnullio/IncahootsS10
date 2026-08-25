local addonName, ns = ...

-- 1. THE EotS MICRO-FRAME
local EotSFrame = CreateFrame("Frame")

-- EotS uses a neutral Netherstorm flag. We will use a generic PvP banner icon for it.
local eotsFlagIcon = "Interface\\Icons\\INV_BannerPVP_03" 

-- 2. THE CHAT PARSER
EotSFrame:SetScript("OnEvent", function(self, event, msg)
    local lowerMsg = string.lower(msg)
    
    if ns.DebugMode then
        print("|cff00ffff[EotS Module]|r: " .. msg)
    end
    
    -- RULE 1: Flag Pickups
    -- EotS chat usually says: "Dana has taken the flag!"
    local picker = string.match(msg, "^([^%s]+) has taken the flag!")
    
    if picker then
        local shortName = string.match(picker, "([^%-]+)") or picker
        ns.FlagCarriers[shortName] = eotsFlagIcon
        if ns.ForceUIRefresh then ns.ForceUIRefresh() end
        return
    end
    
    -- RULE 2: Flag Drops
    -- EotS chat usually says: "The flag has been dropped!"
    if string.find(lowerMsg, "dropped") then
        -- Since there is only one flag, we can safely wipe the entire table
        wipe(ns.FlagCarriers)
        if ns.ForceUIRefresh then ns.ForceUIRefresh() end
        return
    end
    
    -- RULE 3: Flag Captures / Resets
    if string.find(lowerMsg, "captured the") or string.find(lowerMsg, "reset") then
        wipe(ns.FlagCarriers)
        if ns.ForceUIRefresh then ns.ForceUIRefresh() end
        return
    end
end)

-- 3. THE POWER SWITCHES
local function OnEnable()
    EotSFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
    EotSFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
    EotSFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
    
    ns.FlagCarriers = ns.FlagCarriers or {}
    wipe(ns.FlagCarriers)
end

local function OnDisable()
    EotSFrame:UnregisterAllEvents()
    wipe(ns.FlagCarriers)
end

-- 4. REGISTER WITH THE CORE
if ns.RegisterModule then
    ns.RegisterModule("Eye of the Storm", OnEnable, OnDisable)
end