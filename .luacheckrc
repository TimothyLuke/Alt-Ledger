std = "lua51"
max_line_length = false
exclude_files = {
    "Lib/**",
    "spec/**",
    ".luacheckrc"
}
ignore = {
    "212" -- unused argument (event handlers take what they're given)
}
globals = {
    "AltLedger",
    "AltLedgerDB",
    "SLASH_ALTLEDGER1",
    "SLASH_ALTLEDGER2",
    "SlashCmdList"
}
read_globals = {
    -- Lua / WoW Lua extensions
    "wipe", "issecretvalue",
    -- Libraries
    "LibStub",
    -- Namespaces
    "C_AddOns", "C_Bank", "C_Container", "C_EventUtils", "C_Item", "C_Timer", "Enum", "ItemLocation", "Settings",
    "TooltipDataProcessor",
    -- Functions
    "CreateFrame", "GetAddOnMetadata", "GetAutoCompleteRealms", "GetBuildInfo", "GetContainerItemInfo",
    "GetContainerNumSlots", "GetCurrentRegion", "GetCurrentRegionName", "GetInboxItem", "GetInboxNumItems",
    "GetInventoryItemID", "GetItemInfo", "GetLocale", "GetMoney", "GetMoneyString", "GetNormalizedRealmName", "GetRealmName",
    "GetServerTime", "InCombatLockdown", "IsReagentBankUnlocked", "UnitClass", "UnitFactionGroup", "UnitName",
    -- Frames and constants
    "ATTACHMENTS_MAX_RECEIVE", "BANK_CONTAINER", "GameTooltip", "INVSLOT_FIRST_EQUIPPED", "INVSLOT_LAST_EQUIPPED",
    "ItemRefTooltip", "NUM_BAG_SLOTS", "NUM_BANKBAGSLOTS", "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "RAID_CLASS_COLORS",
    "REAGENTBANK_CONTAINER", "ShoppingTooltip1", "ShoppingTooltip2"
}
-- The packager fills these in; in the repo `L` is unused.
files["Localization/*.lua"] = {ignore = {"211"}}
