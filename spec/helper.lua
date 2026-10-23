-- Minimal WoW environment for the pure layers (no frames, no UI).
local helper = {}

function helper.load()
    _G.AltLedger = {
        Compat = {
            GetItemInfo = function()
                return nil
            end,
            IsSecret = function()
                return false
            end
        },
        L = setmetatable({}, {__index = function(_, k)
                    return k
                end}),
        RegisterEvent = function()
        end
    }
    helper.now = 1700000000
    _G.GetServerTime = function()
        return helper.now
    end
    _G.GetNormalizedRealmName = function()
        return "Frostmourne"
    end
    _G.GetAutoCompleteRealms = nil
    _G.AltLedgerDB = nil
    for _, f in ipairs({"Util", "Scope", "Store"}) do
        dofile("Core/" .. f .. ".lua")
    end
    AltLedger.Store.Init()
    return AltLedger
end

--- Adds a character with `free` items in its bags.
function helper.char(info, free, money)
    local Store = AltLedger.Store
    local char = Store.Character(info)
    Store.SetLocation(char, "bags", free or {}, {})
    Store.SetMoney(char, money or 0)
    return char
end

function helper.scope(mode, region, realm, faction, connected)
    local set = {[realm] = true}
    for _, r in ipairs(connected or {}) do
        set[r] = true
    end
    return {mode = mode, region = region, realm = realm, faction = faction, connected = set}
end

return helper
