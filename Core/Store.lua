local AL = AltLedger
local Util = AL.Util
local Scope = AL.Scope

AL.Store = {}
local Store = AL.Store

local DB_VERSION = 1

-- Where a character keeps things. The order is the order tooltips list them.
Store.Locations = {"bags", "bank", "mail", "equipped"}

Store.DefaultOptions = {
    -- "auto" follows the client (region on Retail, ruleset on Forever, realm
    -- elsewhere); the others are Scope.Modes.
    scope = "auto",
    includeCurrent = false,
    showLocations = true,
    showTotal = true,
    showWarband = true,
    debug = false
}

-- AltLedgerDB layout:
--   chars[key] = {name, realm, region, faction, class, money, updated,
--                 free = {[location] = {[itemID] = count}},
--                 bound = {[location] = {[itemID] = count}}}
--   warband[region] = {money, updated, items = {[itemID] = count}}
-- `free` is what could reach another character (unbound, or warbound on
-- Retail); `bound` is everything else, kept so nothing a character owns is lost.
function Store.Init()
    if type(AltLedgerDB) ~= "table" or AltLedgerDB.version ~= DB_VERSION then
        AltLedgerDB = {version = DB_VERSION}
    end
    AltLedgerDB.chars = AltLedgerDB.chars or {}
    AltLedgerDB.warband = AltLedgerDB.warband or {}
    AltLedgerDB.options = AltLedgerDB.options or {}
    for k, v in pairs(Store.DefaultOptions) do
        if AltLedgerDB.options[k] == nil then
            AltLedgerDB.options[k] = Util.CopyTable(v)
        end
    end
    return AltLedgerDB
end

function Store.Options()
    return AltLedgerDB.options
end

--- Characters with the same name and realm can exist in different regions.
function Store.Key(region, realm, name)
    return region .. "/" .. realm .. "/" .. name
end

--- The record for a character, created on first sight. `info` is
-- {region, realm, name, faction, class}; it refreshes what can change (faction
-- for Pandaren, everything after a paid transfer lands under the new key).
function Store.Character(info)
    local key = Store.Key(info.region, info.realm, info.name)
    local char = AltLedgerDB.chars[key]
    if not char then
        char = {free = {}, bound = {}, money = 0}
        AltLedgerDB.chars[key] = char
    end
    char.name, char.realm, char.region = info.name, info.realm, info.region
    char.faction, char.class = info.faction, info.class
    return char, key
end

function Store.SetLocation(char, location, free, bound)
    char.free[location] = free
    char.bound[location] = bound
    char.updated = Util.Now()
end

function Store.SetMoney(char, copper)
    char.money = copper or 0
    char.updated = Util.Now()
end

function Store.Warband(region)
    local wb = AltLedgerDB.warband[region]
    if not wb then
        wb = {money = 0, items = {}}
        AltLedgerDB.warband[region] = wb
    end
    return wb
end

--- Removes a character by key or by "Name-Realm". Returns how many went.
function Store.Forget(nameOrKey)
    local removed = 0
    for key, char in pairs(AltLedgerDB.chars) do
        if key == nameOrKey or (char.name .. "-" .. char.realm):lower() == nameOrKey:lower() then
            AltLedgerDB.chars[key] = nil
            removed = removed + 1
        end
    end
    return removed
end

local function byCountThenName(a, b)
    if a.count ~= b.count then
        return a.count > b.count
    end
    return a.label < b.label
end

--- Who in `scope` holds transferable copies of `itemID`. Pure over
-- AltLedgerDB. Returns rows sorted by count, and the total.
--   row = {key, char, label, count, locations = {[location] = count}}
-- The Warband bank is a row of its own (row.warband = true) in region scope.
function Store.Holders(itemID, scope, excludeKey, includeWarband)
    local rows, total = {}, 0
    for key, char in pairs(AltLedgerDB.chars) do
        if key ~= excludeKey and Scope.Includes(scope, char) then
            local locations, count = {}, 0
            for location, items in pairs(char.free) do
                local n = items[itemID]
                if n and n > 0 then
                    locations[location] = n
                    count = count + n
                end
            end
            if count > 0 then
                rows[#rows + 1] = {key = key, char = char, label = char.name .. "-" .. char.realm, count = count, locations = locations}
                total = total + count
            end
        end
    end
    if includeWarband and scope.mode == "region" then
        local wb = AltLedgerDB.warband[scope.region]
        local n = wb and wb.items[itemID]
        if n and n > 0 then
            rows[#rows + 1] = {warband = true, label = "", count = n, locations = {}}
            total = total + n
        end
    end
    table.sort(rows, byCountThenName)
    return rows, total
end

--- Gold held by every character in `scope`, richest first, plus the Warband
-- bank in region scope. Returns rows, total.
function Store.Gold(scope, includeWarband)
    local rows, total = {}, 0
    for key, char in pairs(AltLedgerDB.chars) do
        if Scope.Includes(scope, char) then
            rows[#rows + 1] = {key = key, char = char, label = char.name .. "-" .. char.realm, count = char.money or 0}
            total = total + (char.money or 0)
        end
    end
    if includeWarband and scope.mode == "region" then
        local wb = AltLedgerDB.warband[scope.region]
        if wb and wb.money > 0 then
            rows[#rows + 1] = {warband = true, label = "", count = wb.money}
            total = total + wb.money
        end
    end
    table.sort(rows, byCountThenName)
    return rows, total
end
