local AL = AltLedger
local L = AL.L
local Util = AL.Util
local Store = AL.Store

AL.Options = {}
local Options = AL.Options

-- Built on Blizzard's Settings panel, as GLT is: a vertical layout category,
-- proxy settings over AltLedgerDB.options and the stock controls. Proxy
-- settings keep AltLedgerDB the single source of truth.

local function proxy(category, key, varType, label, default)
    local function get()
        local v = Store.Options()[key]
        if v == nil then
            return default
        end
        return v
    end
    local function set(v)
        Store.Options()[key] = v
    end
    return Settings.RegisterProxySetting(category, "ALTLEDGER_" .. key, varType, label, default, get, set)
end

local function checkbox(category, key, label, tooltip)
    local setting = proxy(category, key, Settings.VarType.Boolean, label, Store.DefaultOptions[key])
    return Settings.CreateCheckbox(category, setting, tooltip), setting
end

local function dropdown(category, key, label, getOptions, tooltip)
    local setting = proxy(category, key, Settings.VarType.String, label, Store.DefaultOptions[key])
    return Settings.CreateDropdown(category, setting, getOptions, tooltip), setting
end

local function header(layout, name)
    layout:AddInitializer(Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", {name = name, tooltip = name}))
end

local function scopeOptions()
    local container = Settings.CreateControlTextContainer()
    container:Add("auto", L["Automatic"])
    container:Add("region", L["Whole region"])
    container:Add("ruleset", L["Same ruleset and faction"])
    container:Add("realm", L["Same realm and faction"])
    return container:GetData()
end

function Options.Register()
    if not (Settings and Settings.RegisterVerticalLayoutCategory) then
        return
    end
    local category, layout = Settings.RegisterVerticalLayoutCategory(L["Alt Ledger"])
    Options.category = category

    header(layout, L["Item tooltips"])
    dropdown(
        category,
        "scope",
        L["Characters shown"],
        scopeOptions,
        L["Automatic: every character in your region on Retail (the Warband bank reaches them all), your ruleset and faction on WoW Forever, and your realm and faction on the other classic clients."]
    )
    checkbox(category, "includeCurrent", L["Include this character"])
    checkbox(category, "showLocations", L["Show where items are"], L["Bags, bank, mail or equipped, after each count."])
    if AL.HasWarband then
        checkbox(category, "showWarband", L["Include the Warband bank"])
    end
    checkbox(category, "showTotal", L["Show a total"])

    header(layout, L["Interface"])
    checkbox(category, "debug", L["Debug messages"])

    Settings.RegisterAddOnCategory(category)
end

function Options.Open()
    if not Options.category then
        return
    end
    -- Opening the Settings panel in combat touches protected frames.
    if InCombatLockdown() then
        Util.Print(L["Settings can't be opened in combat."])
        return
    end
    pcall(Settings.OpenToCategory, Options.category:GetID())
end
