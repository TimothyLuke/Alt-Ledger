local AL = AltLedger

AL.Util = {}
local Util = AL.Util

local PREFIX = "|cff33ff99Alt Ledger:|r "

function Util.IsEmpty(s)
    return s == nil or s == ""
end

function Util.Now()
    return GetServerTime()
end

function Util.PlayerRealm()
    return (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName() or ""):gsub("[%s%-]", "")
end

function Util.ItemIDFromLink(link)
    if not link then
        return nil
    end
    return tonumber(link:match("|Hitem:(%d+)") or link:match("^item:(%d+)"))
end

function Util.CopyTable(t)
    if type(t) ~= "table" then
        return t
    end
    local out = {}
    for k, v in pairs(t) do
        out[k] = Util.CopyTable(v)
    end
    return out
end

--- "|cffc69b6dName|r" in the character's class colour, or the plain name.
function Util.ClassColored(name, class)
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color and color.colorStr then
        return "|c" .. color.colorStr .. name .. "|r"
    end
    return name
end

--- Copper as "12g 34s 56c" with the stock coin icons where the client has them.
function Util.FormatMoney(copper)
    copper = copper or 0
    if GetMoneyString then
        return GetMoneyString(copper, true)
    end
    return string.format("%dg %ds %dc", math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100)
end

function Util.Print(message)
    print(PREFIX .. tostring(message))
end

function Util.Debug(message)
    if AltLedgerDB and AltLedgerDB.options and AltLedgerDB.options.debug then
        print(PREFIX .. "|cff888888" .. tostring(message) .. "|r")
    end
end
