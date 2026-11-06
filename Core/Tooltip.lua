local AL = AltLedger
local L = AL.L
local Util = AL.Util
local Scope = AL.Scope
local Store = AL.Store

AL.Tooltip = {}
local Tooltip = AL.Tooltip

local LOCATION_LABELS = {
    bags = L["Bags"],
    bank = L["Bank"],
    mail = L["Mail"],
    equipped = L["Equipped"]
}

local WARBAND_COLOR = "|cff00ccff"
local COUNT_COLOR = "|cffffffff"

local function breakdown(row)
    local parts = {}
    for _, location in ipairs(Store.Locations) do
        local n = row.locations[location]
        if n then
            parts[#parts + 1] = LOCATION_LABELS[location] .. " " .. n
        end
    end
    return table.concat(parts, ", ")
end

--- Characters on our own realm are shown by name; the rest as Name-Realm.
local function rowName(row, scope)
    if row.warband then
        return WARBAND_COLOR .. L["Warband bank"] .. "|r"
    end
    local name = row.char.realm == scope.realm and row.char.name or row.label
    return Util.ClassColored(name, row.char.class)
end

--- Appends our lines for `itemID` to `tooltip`. Does nothing when no other
-- character in scope has a transferable copy.
function Tooltip.AddItemLines(tooltip, itemID)
    if not itemID or not AltLedgerDB then
        return
    end
    local options = Store.Options()
    local scope = Scope.Current(options.scope)
    local ownKey = not options.includeCurrent and Store.Key(scope.region, scope.realm, UnitName("player")) or nil
    local rows, total = Store.Holders(itemID, scope, ownKey, options.showWarband)
    if #rows == 0 then
        return
    end
    tooltip:AddLine(" ")
    for _, row in ipairs(rows) do
        local right = COUNT_COLOR .. row.count .. "|r"
        if options.showLocations and not row.warband then
            right = right .. " |cffaaaaaa(" .. breakdown(row) .. ")|r"
        end
        tooltip:AddDoubleLine(rowName(row, scope), right)
    end
    if options.showTotal and #rows > 1 then
        tooltip:AddDoubleLine(L["Total"], COUNT_COLOR .. total .. "|r")
    end
end

-- Hooks -----------------------------------------------------------------------

--- Retail and Forever: one post-call for every item tooltip in the UI.
local function hookTooltipData()
    TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Item,
        function(tooltip, data)
            if not data or AL.Compat.IsSecret(data.id) or not tooltip.AddDoubleLine then
                return
            end
            Tooltip.AddItemLines(tooltip, data.id)
        end
    )
end

--- Classic clients: OnTooltipSetItem, which can fire more than once for the
-- same item, so each tooltip remembers it has been done until it's cleared.
local function hookTooltipScripts()
    local tooltips = {GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2}
    for _, tooltip in ipairs(tooltips) do
        if tooltip and tooltip.HookScript then
            tooltip:HookScript(
                "OnTooltipSetItem",
                function(self)
                    if self.altLedgerDone then
                        return
                    end
                    self.altLedgerDone = true
                    local _, link = self:GetItem()
                    Tooltip.AddItemLines(self, Util.ItemIDFromLink(link))
                end
            )
            tooltip:HookScript(
                "OnTooltipCleared",
                function(self)
                    self.altLedgerDone = nil
                end
            )
        end
    end
end

function Tooltip.Init()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        hookTooltipData()
    else
        hookTooltipScripts()
    end
end
