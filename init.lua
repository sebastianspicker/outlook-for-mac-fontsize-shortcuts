-- ~/.hammerspoon/init.lua
-- Load the outlook-font module, bind hotkeys with notifications, and create a menubar dropdown

--------------------------------------------------------------------------------
-- 1) Allow hs.application.find() to use Spotlight
--------------------------------------------------------------------------------
hs.application.enableSpotlightForNameSearches(true)

--------------------------------------------------------------------------------
-- 2) Import our Outlook-Font module
--------------------------------------------------------------------------------
local of = require("outlook-font")

--------------------------------------------------------------------------------
-- 3) Notification helper
--------------------------------------------------------------------------------
local function notify(text)
    hs.notify.new({
        title           = "Outlook Font",
        informativeText = text,
        autoWithdraw    = true,
        withdrawAfter   = 2
    }):send()
end

--------------------------------------------------------------------------------
-- 4) Bind hotkeys with notifications
--------------------------------------------------------------------------------
hs.hotkey.bind({"ctrl","alt","cmd"}, "G", function()
    of.adjustTextSize(true)
    notify("Text size increased")
end)

hs.hotkey.bind({"ctrl","alt","cmd"}, "K", function()
    of.adjustTextSize(false)
    notify("Text size decreased")
end)

hs.hotkey.bind({"ctrl","alt","cmd"}, "T", function()
    of.toggleTextSize()
    local state = of.toggleState and "Text size increased" or "Text size decreased"
    notify("Toggle: " .. state)
end)

--------------------------------------------------------------------------------
-- 5) Define menubar menu items (no state persistence)
--------------------------------------------------------------------------------
local menuItems = {
    {
        title = "Smaller Text Size",
        fn    = function()
            of.adjustTextSize(false)
            notify("Text size decreased")
        end
    },
    {
        title = "Larger Text Size",
        fn    = function()
            of.adjustTextSize(true)
            notify("Text size increased")
        end
    },
    {
        title = "Toggle Text Size",
        fn    = function()
            of.toggleTextSize()
            local state = of.toggleState and "Text size increased" or "Text size decreased"
            notify("Toggle: " .. state)
        end
    },
    { title = "-" },
    {
        title = "Reload Hammerspoon Config",
        fn    = function() hs.reload() end
    }
}
--------------------------------------------------------------------------------
-- 6) Create a global menubar so it isn’t garbage-collected
--------------------------------------------------------------------------------
menu = hs.menubar.new()
if menu then
    menu:setTitle("🔤")
    menu:setTooltip("Outlook Text Size")
    menu:setMenu(menuItems)
else
    notify("Error", "Could not create menubar item")
end
