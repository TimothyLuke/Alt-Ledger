if GetLocale() ~= "ruRU" then
    return
end

-- English is the fallback: AltLedger.L returns the key for anything missing here.
local L = AltLedger.L

--@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized="ignore")@
