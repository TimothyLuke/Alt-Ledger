local AL = AltLedger
local Util = AL.Util
local Scope = AL.Scope
local Store = AL.Store
local Compat = AL.Compat

AL.Scan = {}
local Scan = AL.Scan

-- Bind types that stay movable once bound, from Enum.ItemBind. Numbers are the
-- fallback for clients without the enum.
local ItemBind = (Enum and Enum.ItemBind) or {}
local BIND_TO_WOW_ACCOUNT = ItemBind.ToWoWAccount or 7
local BIND_TO_BNET_ACCOUNT = ItemBind.ToBnetAccount or 8
local BIND_TO_BNET_UNTIL_EQUIPPED = ItemBind.ToBnetAccountUntilEquipped or 9

function Scan.PlayerInfo()
    local _, class = UnitClass("player")
    return {
        region = Scope.Region(),
        realm = Util.PlayerRealm(),
        name = UnitName("player"),
        faction = Scope.Faction(),
        class = class
    }
end

function Scan.Player()
    return Store.Character(Scan.PlayerInfo())
end

--- Can the item at this location reach another of our characters? Unbound
-- items always can. On Retail a bound item still can if it's warbound, which
-- is exactly "the Warband bank will take it".
function Scan.IsTransferable(itemID, isBound, location)
    if not isBound then
        return true
    end
    if not AL.HasWarband or not location then
        return false
    end
    if C_Bank.IsItemAllowedInBankType then
        local ok, allowed = pcall(C_Bank.IsItemAllowedInBankType, Enum.BankType.Account, location)
        if ok and allowed ~= nil then
            return allowed
        end
    end
    local bindType = select(14, Compat.GetItemInfo(itemID))
    if bindType == BIND_TO_WOW_ACCOUNT or bindType == BIND_TO_BNET_ACCOUNT then
        return true
    end
    if bindType == BIND_TO_BNET_UNTIL_EQUIPPED and C_Item.IsBoundToAccountUntilEquip then
        return C_Item.IsBoundToAccountUntilEquip(location) and true or false
    end
    return false
end

local function add(map, itemID, count)
    map[itemID] = (map[itemID] or 0) + (count or 1)
end

local function slotLocation(bag, slot)
    if AL.HasWarband and ItemLocation then
        return ItemLocation:CreateFromBagAndSlot(bag, slot)
    end
end

--- Counts every slot of `bags` into free/bound maps.
local function scanBags(bags, free, bound)
    for _, bag in ipairs(bags) do
        for slot = 1, Compat.GetContainerNumSlots(bag) or 0 do
            local itemID, count, isBound = Compat.GetContainerItem(bag, slot)
            if itemID then
                if Scan.IsTransferable(itemID, isBound, slotLocation(bag, slot)) then
                    add(free, itemID, count)
                else
                    add(bound, itemID, count)
                end
            end
        end
    end
end

-- Container ids ---------------------------------------------------------------

local function range(first, last)
    local out = {}
    for i = first, last do
        out[#out + 1] = i
    end
    return out
end

function Scan.BagIDs()
    -- NUM_TOTAL_EQUIPPED_BAG_SLOTS includes the Retail reagent bag.
    return range(0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4)
end

local function bankTabs(bankType)
    if not (C_Bank and C_Bank.FetchPurchasedBankTabIDs and bankType) then
        return nil
    end
    local ok, tabs = pcall(C_Bank.FetchPurchasedBankTabIDs, bankType)
    return ok and tabs or nil
end

--- The character bank: purchasable tabs on Retail 11.2+, the classic bank
-- slots plus bank bags (and the old reagent bank) everywhere else.
function Scan.BankIDs()
    if Enum and Enum.BagIndex and Enum.BagIndex.CharacterBankTab_1 and Enum.BankType then
        local tabs = bankTabs(Enum.BankType.Character)
        if tabs then
            return tabs
        end
    end
    local bags = {BANK_CONTAINER or -1}
    local first = (NUM_BAG_SLOTS or 4) + 1
    for i = first, first + (NUM_BANKBAGSLOTS or 6) - 1 do
        bags[#bags + 1] = i
    end
    if REAGENTBANK_CONTAINER and IsReagentBankUnlocked and IsReagentBankUnlocked() then
        bags[#bags + 1] = REAGENTBANK_CONTAINER
    end
    return bags
end

function Scan.WarbandIDs()
    if not AL.HasWarband then
        return {}
    end
    return bankTabs(Enum.BankType.Account) or {}
end

-- Scanners --------------------------------------------------------------------

function Scan.Bags()
    local char = Scan.Player()
    local free, bound = {}, {}
    scanBags(Scan.BagIDs(), free, bound)
    Store.SetLocation(char, "bags", free, bound)
end

--- Only valid while the bank is open: closed, the game reports it empty.
function Scan.Bank()
    local char = Scan.Player()
    local free, bound = {}, {}
    scanBags(Scan.BankIDs(), free, bound)
    Store.SetLocation(char, "bank", free, bound)
    Scan.Warband()
end

--- Everything in the Warband bank can go to any character, so it's all free.
function Scan.Warband()
    if not AL.HasWarband then
        return
    end
    local tabs = Scan.WarbandIDs()
    if #tabs == 0 then
        return
    end
    local items = {}
    scanBags(tabs, items, items)
    local wb = Store.Warband(Scope.Region())
    wb.items = items
    wb.updated = Util.Now()
end

function Scan.Equipped()
    local char = Scan.Player()
    local free, bound = {}, {}
    for slot = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
        local itemID = GetInventoryItemID("player", slot)
        if itemID then
            -- Equipping binds BoE and warbound-until-equipped gear, so only
            -- account-bound pieces (heirlooms and the like) stay movable.
            local location = AL.HasWarband and ItemLocation and ItemLocation:CreateFromEquipmentSlot(slot)
            if Scan.IsTransferable(itemID, true, location) then
                add(free, itemID, 1)
            else
                add(bound, itemID, 1)
            end
        end
    end
    Store.SetLocation(char, "equipped", free, bound)
end

--- The mailbox. Only items another character could send arrive by mail, so
-- every attachment counts as free.
function Scan.Mail()
    local char = Scan.Player()
    local free = {}
    for i = 1, GetInboxNumItems() do
        for j = 1, ATTACHMENTS_MAX_RECEIVE or 16 do
            local _, itemID, _, count = GetInboxItem(i, j)
            if itemID then
                add(free, itemID, count)
            end
        end
    end
    Store.SetLocation(char, "mail", free, {})
end

function Scan.Money()
    local char = Scan.Player()
    Store.SetMoney(char, GetMoney())
    if AL.HasWarband and C_Bank.FetchDepositedMoney then
        local ok, copper = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
        if ok and copper then
            Store.Warband(Scope.Region()).money = copper
        end
    end
end

--- Bag updates come in bursts (looting, sorting, the bank opening). Coalesce
-- them into one scan per kind a moment after the last one.
local pending = {}
function Scan.Queue(kind)
    if pending[kind] then
        return
    end
    pending[kind] = true
    C_Timer.After(
        0.5,
        function()
            pending[kind] = nil
            Scan[kind]()
        end
    )
end
