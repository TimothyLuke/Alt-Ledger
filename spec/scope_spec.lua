local helper = require("helper")

describe("Scope.Includes", function()
    local Scope
    before_each(function()
        Scope = helper.load().Scope
    end)

    local function char(region, realm, faction)
        return {region = region, realm = realm, faction = faction}
    end

    it("takes the whole region on Retail, any realm or faction", function()
        local s = helper.scope("region", 1, "Frostmourne", "Horde")
        assert.is_true(Scope.Includes(s, char(1, "Area52", "Alliance")))
        assert.is_true(Scope.Includes(s, char(1, "Frostmourne", "Horde")))
    end)

    it("keeps NA and EU warbands apart", function()
        local s = helper.scope("region", 1, "Frostmourne", "Horde")
        assert.is_false(Scope.Includes(s, char(3, "Frostmourne", "Horde")))
    end)

    it("takes one ruleset and faction on Forever", function()
        local s = helper.scope("ruleset", 1, "Normal", "Alliance")
        assert.is_true(Scope.Includes(s, char(1, "Normal", "Alliance")))
        assert.is_false(Scope.Includes(s, char(1, "Normal", "Horde")))
        assert.is_false(Scope.Includes(s, char(1, "PvP", "Alliance")))
    end)

    it("takes the realm, its connected realms and the faction on classic", function()
        local s = helper.scope("realm", 1, "Whitemane", "Horde", {"Mankrik"})
        assert.is_true(Scope.Includes(s, char(1, "Whitemane", "Horde")))
        assert.is_true(Scope.Includes(s, char(1, "Mankrik", "Horde")))
        assert.is_false(Scope.Includes(s, char(1, "Whitemane", "Alliance")))
        assert.is_false(Scope.Includes(s, char(1, "Pagle", "Horde")))
    end)
end)
