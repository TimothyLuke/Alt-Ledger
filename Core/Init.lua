local addonName = ...

-- AceEvent is the only Ace library Alt Ledger uses; everything else is native.
AltLedger = {}
local AL = AltLedger
LibStub("AceEvent-3.0"):Embed(AL)

AL.addonName = addonName or "alt-ledger"

-- Locale: Localization/enUS.lua is the master phrase list (uploaded to
-- CurseForge at build) and the other locales override it. Same conventions as
-- AceLocale without the library: `L[phrase] = true` means the value is the
-- key, and a missing key shows the key rather than erroring.
AL.L =
    setmetatable(
    {},
    {
        __index = function(t, k)
            rawset(t, k, k)
            return k
        end,
        __newindex = function(t, k, v)
            rawset(t, k, v == true and k or v)
        end
    }
)

local GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
AL.VersionString = GetAddOnMetadata(AL.addonName, "Version") or "dev"
--@debug@
if AL.VersionString:find("@project", 1, true) then
    AL.VersionString = "dev"
end
--@end-debug@

-- GameMode answers "which API generation is this client", not "which content".
-- It matches GSE and GLT: the expansion major, except WoW Forever. Forever runs
-- vanilla content (1.60.x) on the Retail API surface, so it reports 12, the
-- generation whose APIs it has. Anything asking "am I on Forever?" uses
-- AL.IsForever, and "am I on Retail?" uses AL.IsRetail.
local FOREVER_MAJOR, FOREVER_MIN_MINOR = 1, 60
local FOREVER_API_GENERATION = 12
local RETAIL_MIN_MAJOR = 11

local gameVersion, _, _, tocVersion = GetBuildInfo()
local major, minor = gameVersion:match("^(%d+)%.(%d+)")
major, minor = tonumber(major), tonumber(minor)

AL.TOC = tocVersion
AL.IsForever = major == FOREVER_MAJOR and minor ~= nil and minor >= FOREVER_MIN_MINOR
AL.GameMode = AL.IsForever and FOREVER_API_GENERATION or major
AL.IsRetail = not AL.IsForever and major ~= nil and major >= RETAIL_MIN_MAJOR

-- The Warband bank is what makes warbound items and gold movable between
-- characters, so it's the switch for every warband path.
AL.HasWarband =
    AL.IsRetail and C_Bank ~= nil and Enum ~= nil and Enum.BankType ~= nil and Enum.BankType.Account ~= nil

-- API shims. Retail moved these into C_ namespaces and the globals are gone or
-- going; the classic clients still only have some of the namespaced versions.
AL.Compat = {
    GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo,
    GetContainerNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots,
    -- Midnight hands addons "secret" values in some restricted contexts. Any
    -- operation on one errors, so tooltip data is checked before it's used.
    IsSecret = issecretvalue or function()
            return false
        end
}

--- itemID, stack count, isBound for one container slot, on either API.
function AL.Compat.GetContainerItem(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then
            return info.itemID, info.stackCount, info.isBound
        end
        return nil
    end
    local _, count, _, _, _, _, _, _, _, itemID, isBound = GetContainerItemInfo(bag, slot)
    return itemID, count, isBound
end

--- Registers an event only if this client knows it. A frame errors on an
-- unknown event, and the event set differs between retail and the classics
-- (ACCOUNT_MONEY, for one, is retail only).
local probe = CreateFrame("Frame")
function AL:RegisterEventIfExists(event, handler)
    if C_EventUtils and C_EventUtils.IsEventValid then
        if not C_EventUtils.IsEventValid(event) then
            return false
        end
    else
        local ok = pcall(probe.RegisterEvent, probe, event)
        if not ok then
            return false
        end
        probe:UnregisterEvent(event)
    end
    self:RegisterEvent(event, handler)
    return true
end

-- Lifecycle: OnInitialize once our saved variables are loaded, OnEnable at
-- login when the rest of the UI is up.
AL:RegisterEvent(
    "ADDON_LOADED",
    function(_, name)
        if name == AL.addonName then
            AL:UnregisterEvent("ADDON_LOADED")
            AL:OnInitialize()
        end
    end
)
AL:RegisterEvent(
    "PLAYER_LOGIN",
    function()
        AL:UnregisterEvent("PLAYER_LOGIN")
        AL:OnEnable()
    end
)
