-- Every phrase the code uses has to be in the enUS master list, or it never
-- reaches CurseForge and can't be translated.
local function phrases(path)
    local f = assert(io.open(path))
    local src = f:read("*a")
    f:close()
    local found = {}
    for key in src:gmatch('[^%w_.]L%[%s*"(.-[^\\])"%s*%]') do
        found[key] = true
    end
    return found
end

describe("enUS locale", function()
    it("lists every phrase the code uses", function()
        local master = phrases("Localization/enUS.lua")
        local missing = {}
        local p = io.popen("ls Core/*.lua")
        for file in p:lines() do
            for key in pairs(phrases(file)) do
                if not master[key] then
                    missing[#missing + 1] = file .. ": " .. key
                end
            end
        end
        p:close()
        table.sort(missing)
        assert.are.same({}, missing)
    end)
end)
