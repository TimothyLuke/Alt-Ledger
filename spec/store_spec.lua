local helper = require("helper")

describe("Store", function()
    local AL, Store
    before_each(function()
        AL = helper.load()
        Store = AL.Store
    end)

    local function info(name, realm, faction, region)
        return {name = name, realm = realm, faction = faction or "Horde", region = region or 1, class = "MAGE"}
    end

    it("counts only free copies, per location, and skips the current character", function()
        local me = helper.char(info("Me", "Frostmourne"), {[2589] = 20})
        local alt = helper.char(info("Alt", "Frostmourne"), {[2589] = 5})
        Store.SetLocation(alt, "bank", {[2589] = 7}, {[2589] = 100})
        local _, myKey = Store.Character(info("Me", "Frostmourne"))
        assert.is_not_nil(me)

        local rows, total = Store.Holders(2589, helper.scope("realm", 1, "Frostmourne", "Horde"), myKey)
        assert.are.equal(1, #rows)
        assert.are.equal("Alt-Frostmourne", rows[1].label)
        assert.are.same({bags = 5, bank = 7}, rows[1].locations)
        assert.are.equal(12, total)
    end)

    it("leaves out characters outside the scope", function()
        helper.char(info("Ally", "Frostmourne", "Alliance"), {[2589] = 5})
        helper.char(info("Euro", "Frostmourne", "Horde", 3), {[2589] = 5})
        local rows = Store.Holders(2589, helper.scope("realm", 1, "Frostmourne", "Horde"))
        assert.are.equal(0, #rows)
    end)

    it("adds the Warband bank in region scope only", function()
        helper.char(info("Alt", "Area52"), {[2589] = 3})
        Store.Warband(1).items = {[2589] = 40}
        local rows, total = Store.Holders(2589, helper.scope("region", 1, "Frostmourne", "Horde"), nil, true)
        assert.are.equal(2, #rows)
        assert.is_true(rows[1].warband)
        assert.are.equal(43, total)

        local realmRows = Store.Holders(2589, helper.scope("realm", 1, "Area52", "Horde"), nil, true)
        assert.are.equal(1, #realmRows)
    end)

    it("totals gold across the scope plus the warband", function()
        helper.char(info("Rich", "Frostmourne"), {}, 5000000)
        helper.char(info("Poor", "Barthilas"), {}, 100)
        Store.Warband(1).money = 900
        local rows, total = Store.Gold(helper.scope("region", 1, "Frostmourne", "Horde"), true)
        assert.are.equal(3, #rows)
        assert.are.equal("Rich-Frostmourne", rows[1].label)
        assert.are.equal(5001000, total)
    end)

    it("forgets a character by Name-Realm", function()
        helper.char(info("Alt", "Frostmourne"), {[1] = 1})
        assert.are.equal(1, Store.Forget("alt-frostmourne"))
        assert.are.equal(0, #Store.Holders(1, helper.scope("region", 1, "Frostmourne", "Horde")))
    end)
end)
