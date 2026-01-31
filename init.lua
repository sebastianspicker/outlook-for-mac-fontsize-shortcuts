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
    hs.notify
        .new({
            title = "Outlook Font",
            informativeText = text,
            autoWithdraw = true,
            withdrawAfter = 2,
        })
        :send()
end

--------------------------------------------------------------------------------
-- 4) Bind hotkeys with notifications
--------------------------------------------------------------------------------
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "G", function()
    if of.adjustTextSize(true) then
        notify("Text size increased")
    end
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "K", function()
    if of.adjustTextSize(false) then
        notify("Text size decreased")
    end
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "T", function()
    if of.toggleTextSize() then
        local state = of.toggleState and "Text size increased" or "Text size decreased"
        notify("Toggle: " .. state)
    end
end)

--------------------------------------------------------------------------------
-- 5) Define menubar menu items (no state persistence)
--------------------------------------------------------------------------------
local menuItems = {
    {
        title = "Smaller Text Size",
        fn = function()
            if of.adjustTextSize(false) then
                notify("Text size decreased")
            end
        end,
    },
    {
        title = "Larger Text Size",
        fn = function()
            if of.adjustTextSize(true) then
                notify("Text size increased")
            end
        end,
    },
    {
        title = "Toggle Text Size",
        fn = function()
            if of.toggleTextSize() then
                local state = of.toggleState and "Text size increased" or "Text size decreased"
                notify("Toggle: " .. state)
            end
        end,
    },
    { title = "-" },
    {
        title = "Reload Hammerspoon Config",
        fn = function()
            hs.reload()
        end,
    },
}
--------------------------------------------------------------------------------
-- 6) Create a global menubar so it isn’t garbage-collected
--------------------------------------------------------------------------------
local menu = hs.menubar.new()
if menu then
    menu:setTitle("🔤")
    menu:setTooltip("Outlook Text Size")
    menu:setMenu(menuItems)
else
    notify("Could not create menubar item")
end
