if GetLocale() ~= "zhTW" then
    return
end

-- English is the fallback: AltLedger.L returns the key for anything missing here.
local L = AltLedger.L

--@localization(locale="zhTW", format="lua_additive_table", handle-unlocalized="ignore")@
