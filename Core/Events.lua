local AL = AltLedger
local L = AL.L
local Util = AL.Util
local Scope = AL.Scope
local Store = AL.Store
local Scan = AL.Scan

local bankOpen = false

function AL:OnInitialize()
    Store.Init()
    SLASH_ALTLEDGER1 = "/ledger"
    SLASH_ALTLEDGER2 = "/altledger"
    SlashCmdList.ALTLEDGER = function(input)
        AL:SlashCommand(input)
    end
end

function AL:OnEnable()
    AL.Options.Register()
    AL.Tooltip.Init()

    Scan.Bags()
    Scan.Equipped()
    Scan.Money()

    self:RegisterEvent(
        "BAG_UPDATE_DELAYED",
        function()
            Scan.Queue("Bags")
            -- On Retail the bank tabs report through the same event.
            if bankOpen then
                Scan.Queue("Bank")
            end
        end
    )
    self:RegisterEvent(
        "PLAYER_EQUIPMENT_CHANGED",
        function()
            Scan.Queue("Equipped")
        end
    )
    self:RegisterEvent("PLAYER_MONEY", Scan.Money)
    self:RegisterEventIfExists("ACCOUNT_MONEY", Scan.Money)

    self:RegisterEvent(
        "BANKFRAME_OPENED",
        function()
            bankOpen = true
            Scan.Bank()
            Scan.Money()
        end
    )
    self:RegisterEvent(
        "BANKFRAME_CLOSED",
        function()
            bankOpen = false
        end
    )
    -- The classic bank's own slots and the old reagent bank aren't bags, so
    -- they don't raise BAG_UPDATE_DELAYED.
    local function bankSlotsChanged()
        if bankOpen then
            Scan.Queue("Bank")
        end
    end
    self:RegisterEventIfExists("PLAYERBANKSLOTS_CHANGED", bankSlotsChanged)
    self:RegisterEventIfExists("PLAYERREAGENTBANKSLOTS_CHANGED", bankSlotsChanged)

    self:RegisterEvent(
        "MAIL_INBOX_UPDATE",
        function()
            Scan.Queue("Mail")
        end
    )
end

local function printGold()
    local scope = Scope.Current(Store.Options().scope)
    local rows, total = Store.Gold(scope, Store.Options().showWarband)
    Util.Print(Scope.Describe(scope))
    for _, row in ipairs(rows) do
        local name = row.warband and L["Warband bank"] or Util.ClassColored(row.label, row.char.class)
        print("  " .. name .. ": " .. Util.FormatMoney(row.count))
    end
    print("  " .. L["Total"] .. ": " .. Util.FormatMoney(total))
end

function AL:SlashCommand(input)
    local cmd, rest = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "" or cmd == "gold" then
        printGold()
    elseif cmd == "options" or cmd == "config" then
        AL.Options.Open()
    elseif cmd == "scope" then
        Util.Print(Scope.Describe(Scope.Current(Store.Options().scope)))
    elseif cmd == "forget" and rest ~= "" then
        Util.Print(string.format(L["Forgot %d character(s) matching %s."], Store.Forget(rest), rest))
    elseif cmd == "debug" then
        Store.Options().debug = not Store.Options().debug
        Util.Print("Debug " .. (Store.Options().debug and "on" or "off"))
    else
        Util.Print("/ledger [gold | options | scope | forget Name-Realm | debug]")
    end
end
