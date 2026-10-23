local AL = AltLedger
local L = AL.L
local Util = AL.Util

AL.Scope = {}
local Scope = AL.Scope

-- Which of your characters count as "yours to move items between" depends on
-- the client, because what links characters differs:
--
--   region   Retail. The Warband bank moves warbound and unbound items (and
--            gold) between every character on the Battle.net account in the
--            same region, whatever their realm or faction. NA and EU warbands
--            are separate.
--   ruleset  WoW Forever. There are no realms, only rulesets (Normal, PvP,
--            Roleplay...), and characters can't change ruleset. Items move by
--            mail or trade within a ruleset and faction.
--   realm    Every other classic client. Mail and trade only reach the same
--            realm (and the realms connected to it) and the same faction.
Scope.Modes = {"region", "ruleset", "realm"}

function Scope.DefaultMode()
    if AL.IsRetail then
        return "region"
    elseif AL.IsForever then
        return "ruleset"
    end
    return "realm"
end

--- Forever replaced the realm list with rulesets, so the client's realm is the
-- ruleset the character lives on.
function Scope.Ruleset()
    return Util.PlayerRealm()
end

--- The realms mail and trade reach from here: our own plus anything connected.
local function connectedRealms(realm)
    local set = {[realm] = true}
    if GetAutoCompleteRealms then
        for _, r in ipairs(GetAutoCompleteRealms() or {}) do
            set[r] = true
        end
    end
    return set
end

--- Region id (1 US/NA, 2 KR, 3 EU, 4 TW, 5 CN). The US region includes the
-- Oceanic, Latin American and Brazilian realms, which share one warband.
function Scope.Region()
    return (GetCurrentRegion and GetCurrentRegion()) or 0
end

function Scope.Faction()
    return (UnitFactionGroup("player")) or "Neutral"
end

--- The scope the logged-in character sees. `mode` overrides the client
-- default (the "Characters shown" option).
function Scope.Current(mode)
    local realm = Util.PlayerRealm()
    if not mode or mode == "auto" then
        mode = Scope.DefaultMode()
    end
    return {
        mode = mode,
        region = Scope.Region(),
        realm = realm,
        faction = Scope.Faction(),
        connected = connectedRealms(realm)
    }
end

--- Pure: does character record `char` belong to `scope`?
function Scope.Includes(scope, char)
    if char.region ~= scope.region then
        return false
    end
    if scope.mode == "region" then
        return true
    end
    if char.faction ~= scope.faction then
        return false
    end
    if scope.mode == "ruleset" then
        return char.realm == scope.realm
    end
    return (scope.connected and scope.connected[char.realm]) or char.realm == scope.realm
end

--- One line for /ledger scope, so it's easy to check what a client decided.
function Scope.Describe(scope)
    if scope.mode == "region" then
        return string.format(L["All characters in region %s"], (GetCurrentRegionName and GetCurrentRegionName()) or scope.region)
    elseif scope.mode == "ruleset" then
        return string.format(L["%s characters on the %s ruleset"], scope.faction, scope.realm)
    end
    local realms = {}
    for r in pairs(scope.connected or {}) do
        realms[#realms + 1] = r
    end
    table.sort(realms)
    return string.format(L["%s characters on %s"], scope.faction, table.concat(realms, ", "))
end
