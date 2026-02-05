require("spec.spec_helper")

local of = require("outlook-font")

describe("outlook-font core logic", function()
    before_each(function()
        of._resetForTest()
    end)

    it("returns false when required dependencies are missing", function()
        of._setDeps({})
        local ok = of.adjustTextSize(true)
        assert.is_false(ok)
    end)

    it("returns false when Outlook is not found", function()
        of._setDeps({
            timer = {
                usleep = function() end,
                secondsSinceEpoch = function()
                    return 0
                end,
            },
            eventtap = { keyStroke = function() end },
            application = {
                find = function()
                    return nil
                end,
            },
        })
        local ok = of.adjustTextSize(true)
        assert.is_false(ok)
    end)

    it("retries menu selection attempts when menus are unavailable", function()
        local select_calls = 0
        local axApp = {
            attributeValue = function()
                return {}
            end,
        }
        local app = {
            activate = function() end,
            isFrontmost = function()
                return true
            end,
            pid = function()
                return 123
            end,
            selectMenuItem = function()
                select_calls = select_calls + 1
                return false
            end,
        }

        of._setDeps({
            timer = {
                usleep = function() end,
                secondsSinceEpoch = function()
                    return 0
                end,
            },
            eventtap = { keyStroke = function() end },
            application = {
                find = function()
                    return app
                end,
            },
            axuielement = {
                applicationElement = function()
                    return axApp
                end,
            },
        })

        local ok = of.adjustTextSize(true)
        assert.is_false(ok)
        assert.equals(4, select_calls)
    end)

    it("does not toggle state on failure", function()
        of._setDeps({})
        local ok = of.toggleTextSize()
        assert.is_false(ok)
        assert.is_false(of.toggleState)
    end)
end)
