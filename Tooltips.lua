local addonName, ns = ...

-- Helper function to detect if a player is riding a mount by scanning their buffs
local function GetUnitMountName(unit)
    if not unit then return nil end
    for i = 1, 40 do
        local name, _, icon = UnitBuff(unit, i)
        if not name then break end -- No more buffs to scan
        
        if icon then
            local iconLower = string.lower(icon)
            -- Matches almost all standard mounts, custom mounts, and druid flight forms
            if string.find(iconLower, "ability_mount") 
               or string.find(iconLower, "ability_druid_flightform")
               or string.find(iconLower, "ability_druid_swiftflightform")
               or string.find(iconLower, "ability_hunter_pet_swiftalliancesteed")
               or string.find(iconLower, "inv_misc_foot_")
            then
                return name
            end
        end
    end
    return nil
end

-- 1. Helper function to safely estimate distance using native API
local function GetRangeEstimate(unit)
    if CheckInteractDistance(unit, 2) then
        return "0 - 8 yds (Melee)"
    elseif CheckInteractDistance(unit, 3) then
        return "8 - 10 yds (Close)"
    elseif CheckInteractDistance(unit, 4) then
        return "10 - 28 yds (Mid Range)"
    else
        return "> 28 yds (Long Range)"
    end
end

-- 2. Helper to fetch exact BG Stats for a specific player name
local function GetPlayerBGStats(playerName)
    if not UnitInBattleground("player") then return nil end
    for i = 1, GetNumBattlefieldScores() do
        local name, kills, honorableKills, deaths, honorGained, faction, race, class, classToken, damageDone, healingDone = GetBattlefieldScore(i)
        if name then
            local shortName = string.match(name, "([^%-]+)") or name
            if shortName == playerName then
                return {
                    kills = kills or 0,
                    deaths = deaths or 0,
                    damage = damageDone or 0,
                    healing = healingDone or 0,
                    className = class
                }
            end
        end
    end
    return nil
end

-- 3. Hook into the default GameTooltip rendering process
GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    -- Grab the unit currently being moused over
    local _, unit = self:GetUnit()
    
    -- Only modify the tooltip if the unit exists and is an actual player
    if unit and UnitIsPlayer(unit) then
        
        -- Faction / Combat State
        if UnitIsEnemy("player", unit) then
            self:AddLine("|cffff0000< Hostile >|r")
        elseif UnitIsFriend("player", unit) then
            self:AddLine("|cff00ff00< Friendly >|r")
        end
        
        -- Range Estimate
        local rangeText = GetRangeEstimate(unit)
        self:AddLine("Range: |cffffffff" .. rangeText .. "|r")
        
        -- Mount Detection
        local mountName = GetUnitMountName(unit)
        if mountName then
            self:AddLine("Mount: |cff00ffff" .. mountName .. "|r")
        end
        
        -- Target of Target
        local targetUnit = unit .. "target"
        if UnitExists(targetUnit) then
            local targetName = UnitName(targetUnit)
            local displayColor = "|cffffffff" -- Default white
            
            -- Color-code the target based on their relationship to YOU
            if UnitIsUnit("player", targetUnit) then
                targetName = ">> YOU <<"
                displayColor = "|cffff0000" -- Bright Red if they are looking at you
            elseif UnitIsFriend("player", targetUnit) then
                displayColor = "|cff00ff00" -- Green if targeting your teammate
            elseif UnitIsEnemy("player", targetUnit) then
                displayColor = "|cffffaa00" -- Orange if targeting another enemy
            end
            
            self:AddLine("Targeting: " .. displayColor .. targetName .. "|r")
        end

        -- NEW: Inject BG Stats if active in a Battleground
        local name = UnitName(unit)
        local shortName = string.match(name, "([^%-]+)") or name
        local stats = GetPlayerBGStats(shortName)
        
        if stats then
            self:AddLine(" ")
            self:AddLine("Battleground Stats:", 1, 0.82, 0)
            self:AddDoubleLine("Kills / Deaths:", stats.kills .. " / " .. stats.deaths, 1, 1, 1, 1, 1, 1)
            self:AddDoubleLine("Damage Done:", stats.damage, 1, 1, 1, 1, 0.7, 0)
            self:AddDoubleLine("Healing Done:", stats.healing, 1, 1, 1, 0, 1, 0)
            
            if ns.CarryDB and ns.CarryDB[shortName] then
                self:AddLine(" ")
                self:AddLine(">> HIGH THREAT TARGET <<", 1, 0.2, 0.2)
            end
        end
        
        -- Force the tooltip to resize and accommodate the new lines
        self:Show()
    end
end)

-- 4. Hook Tooltips directly onto our custom Incahoots Enemy Rows
local function ApplyEnemyRowTooltips()
    for i = 1, 20 do
        local row = _G["IncahootsBGTRow"..i]
        if row then
            row:HookScript("OnEnter", function(self)
                local name = self.nameText and self.nameText:GetText()
                if name and name ~= "" then
                    -- ANCHOR_RIGHT attaches it cleanly to the right side of the Incahoots UI
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(name, 1, 0.82, 0)
                    
                    local stats = GetPlayerBGStats(name)
                    if stats then
                        GameTooltip:AddLine(stats.className or "Enemy Player", 1, 1, 1)
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddDoubleLine("Kills / Deaths:", stats.kills .. " / " .. stats.deaths, 1, 1, 1, 1, 1, 1)
                        
                        -- Calculate K/D Ratio safely
                        if stats.deaths > 0 then
                            local kd = stats.kills / stats.deaths
                            GameTooltip:AddDoubleLine("K/D Ratio:", string.format("%.2f", kd), 1, 1, 1, 1, 1, 1)
                        elseif stats.kills > 0 then
                            GameTooltip:AddDoubleLine("K/D Ratio:", "Perfect", 1, 1, 1, 1, 0.82, 0)
                        end
                        
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddDoubleLine("Damage Done:", stats.damage, 1, 1, 1, 1, 0.7, 0)
                        GameTooltip:AddDoubleLine("Healing Done:", stats.healing, 1, 1, 1, 0, 1, 0)
                        
                        if ns.CarryDB and ns.CarryDB[name] then
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddLine(">> HIGH THREAT TARGET <<", 1, 0.2, 0.2)
                        end
                    else
                        GameTooltip:AddLine("No scoreboard data available.", 0.5, 0.5, 0.5)
                    end
                    GameTooltip:Show()
                end
            end)
            
            row:HookScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end
    end
end

-- 5. Run the hook setup when the addon loads
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    ApplyEnemyRowTooltips()
end)