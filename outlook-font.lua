-- ~/.hammerspoon/outlook-font.lua
--[[
    outlook-font.lua

    A Hammerspoon module to control the “Text display size” in both
    Legacy and New Outlook for Mac, with:
      • External JSON override
      • Canvas-based visual feedback
      • i18n support (multiple languages)
      • Accessibility health-check
      • Dynamic timeouts & retry logic
      • Version detection (Settings vs. Preferences)
      • Toggle-cycle state
--]]

local M = {}

--------------------------------------------------------------------------------
-- 1) Default configuration
--------------------------------------------------------------------------------
local defaultCfg = {
    appNames        = {"Outlook", "Microsoft Outlook"},
    settingsMenu    = {"Outlook", "Settings…"},
    preferencesMenu = {"Outlook", "Preferences…"},
    headerLabels    = {
        "Personal Settings", "Persönliche Einstellungen",
        "Paramètres personnels", "Configuración personal"
    },
    labelTexts      = {
        "Text display size", "Taille d'affichage du texte",
        "Tamaño de visualización de texto"
    },
    delays = {
        activate     = 0.1,   -- seconds after app:activate()
        waitInterval = 0.05,  -- polling interval for waitUntil()
        timeout      = 3      -- overall timeout for waitUntil()
    },
    retry = {
        attempts = 2,         -- number of retries
        interval = 0.2        -- seconds between retries
    }
}

--------------------------------------------------------------------------------
-- 2) Load external override from ~/.hammerspoon/outlook-font.json
--------------------------------------------------------------------------------
M.cfg = defaultCfg
local json = require("hs.json")
local home = os.getenv("HOME") or ""
local cfgPath = home .. "/.hammerspoon/outlook-font.json"
local f = io.open(cfgPath, "r")
if f then
    local raw = f:read("*a")
    f:close()
    local ext = json.decode(raw)
    if type(ext)=="table" then
        for k,v in pairs(ext) do
            M.cfg[k] = v
        end
    end
end

--------------------------------------------------------------------------------
-- 3) Notification helper for errors
--------------------------------------------------------------------------------
local function notify(title, message)
    require("hs.notify").new({
        title           = "Outlook Font",
        informativeText = message,
        autoWithdraw    = true,
        withdrawAfter   = 3
    }):send()
end

--------------------------------------------------------------------------------
-- 4) Canvas-based visual feedback
--------------------------------------------------------------------------------
local canvasLib = require("hs.canvas")
local function showOverlay(text)
    local screen = require("hs.screen").mainScreen():fullFrame()
    local w, h   = math.min(300, screen.w*0.5), 60
    local x = screen.x + (screen.w - w)/2
    local y = screen.y + (screen.h - h)/2

    local c = canvasLib.new{x=x,y=y,w=w,h=h}
    c[1] = {
        type = "rectangle", action = "fill",
        frame = {x=0,y=0,w=1,h=1},
        fillColor = {white=0.1,alpha=0.8},
        roundedRectRadii = {xRadius=12,yRadius=12},
        strokeColor = {white=1,alpha=0.9},
        strokeWidth = 2
    }
    c[2] = {
        type = "text", text = text,
        frame = {x=0,y=0,w=1,h=1},
        textColor = {white=1}, textSize = 28,
        textFont = "Helvetica Bold", alignment = "center"
    }
    c:show()
    require("hs.timer").doAfter(1.2, function() c:delete() end)
end

--------------------------------------------------------------------------------
-- 5) Recursive find of AXStaticText by substring
--------------------------------------------------------------------------------
local function findStaticText(root, substr)
    if not root then return nil end
    if root:attributeValue("AXRole")=="AXStaticText" then
        local val = root:attributeValue("AXValue")
                 or root:attributeValue("AXTitle")
                 or ""
        if string.find(val, substr, 1, true) then return root end
    end
    for _,child in ipairs(root:attributeValue("AXChildren") or {}) do
        local found = findStaticText(child, substr)
        if found then return found end
    end
    return nil
end

--------------------------------------------------------------------------------
-- 6) Find group of AXButton elements next to a found label
--------------------------------------------------------------------------------
local function findButtonGroup(root)
    for _,label in ipairs(M.cfg.labelTexts) do
        local elem = findStaticText(root, label)
        if elem then
            local grp = elem
            while grp do
                local children = grp:attributeValue("AXChildren") or {}
                local btns = {}
                for _,c in ipairs(children) do
                    if c:attributeValue("AXRole")=="AXButton" then
                        table.insert(btns, c)
                    end
                end
                if #btns>=2 then return btns end
                grp = grp:attributeValue("AXParent")
            end
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- 7) Locate the Outlook application instance
--------------------------------------------------------------------------------
local function getOutlookApp()
    for _,name in ipairs(M.cfg.appNames) do
        local app = require("hs.application").find(name)
        if app then return app end
    end
    return nil
end

--------------------------------------------------------------------------------
-- 8) Accessibility health-check
--------------------------------------------------------------------------------
local function healthCheck(app)
    if not app:isFrontmost() then app:activate() end
    local axApp = require("hs.axuielement").applicationElement(app:name())
    if not axApp then
        notify("Accessibility Required",
               "Enable Hammerspoon in System Preferences → Security & Privacy → Accessibility")
        return false
    end
    return true
end

--------------------------------------------------------------------------------
-- 9) Wait for a window whose title matches a pattern
--------------------------------------------------------------------------------
local function waitForWindow(app, pattern)
    return require("hs.timer").waitUntil(
        function()
            local ax = require("hs.axuielement").applicationElement(app:name())
            for _,w in ipairs((ax and ax:attributeValue("AXWindows")) or {}) do
                local t = w:attributeValue("AXTitle") or ""
                if t:match(pattern) then return true end
            end
            return false
        end,
        function() end,
        M.cfg.delays.timeout,
        M.cfg.delays.waitInterval
    )
end

--------------------------------------------------------------------------------
-- 10) Core function: adjust text size, detect version, retry logic
--------------------------------------------------------------------------------
M.toggleState = false

function M.adjustTextSize(isPlus)
    local app = getOutlookApp()
    if not app then
        notify("Outlook Not Found", "Make sure Outlook is running.")
        return
    end
    if not healthCheck(app) then return end

    for attempt=1,M.cfg.retry.attempts do
        app:activate()
        require("hs.timer").usleep(M.cfg.delays.activate*1e6)

        -- Choose menu path
        local modeLegacy = false
        if pcall(function() app:selectMenuItem(M.cfg.settingsMenu) end) then
            modeLegacy = false
        elseif pcall(function() app:selectMenuItem(M.cfg.preferencesMenu) end) then
            modeLegacy = true
        else
            notify("Menu Not Found", "Neither Settings nor Preferences was available.")
            return
        end

        -- Wait for window
        local pattern = modeLegacy and "Preferences" or "Settings"
        if not waitForWindow(app, pattern) then
            if attempt<M.cfg.retry.attempts then
                require("hs.timer").usleep(M.cfg.retry.interval*1e6)
            else
                notify("Timeout","No "..pattern.." window appeared.")
            end
            return
        end

        -- Grab that window
        local ax  = require("hs.axuielement").applicationElement(app:name())
        local win
        for _,w in ipairs(ax:attributeValue("AXWindows") or {}) do
            local t = w:attributeValue("AXTitle") or ""
            if t:match(pattern) then win=w; break end
        end
        if not win then
            notify("Window Not Found", pattern.." window was not identifiable.")
            return
        end

        -- Do the UI work
        local ok, err = pcall(function()
            if modeLegacy then
                -- Legacy: slider-based
                local function findSlider(r)
                    if not r then return nil end
                    if r:attributeValue("AXRole")=="AXSlider" then return r end
                    for _,c in ipairs(r:attributeValue("AXChildren") or {}) do
                        local s = findSlider(c)
                        if s then return s end
                    end
                end
                local slider = findSlider(win)
                if not slider then error("Slider not found") end
                local val  = slider:attributeValue("AXValue")
                local minv = slider:attributeValue("AXMinValue")
                local maxv = slider:attributeValue("AXMaxValue")
                local newv = isPlus and math.min(val+1,maxv) or math.max(val-1,minv)
                slider:setAttributeValue("AXValue", newv)
            else
                -- New UI: tile + buttons
                local header
                for _,hl in ipairs(M.cfg.headerLabels) do
                    header = findStaticText(win, hl)
                    if header then break end
                end
                if not header then error("Header not found") end
                local parent = header:attributeValue("AXParent")
                local sibs   = parent and parent:attributeValue("AXChildren") or {}
                local idx
                for i,v in ipairs(sibs) do if v==header then idx=i; break end end
                local general = idx and idx>1 and sibs[idx-1]
                if not general then error("General tile not found") end
                general:performAction("AXPress")
                waitForWindow(app, M.cfg.labelTexts[1])
                local buttons = findButtonGroup(win)
                if not buttons then error("±-Buttons not found") end
                local btn = isPlus and buttons[#buttons] or buttons[1]
                btn:performAction("AXPress")
            end
        end)

        -- Close window
        if modeLegacy then
            require("hs.eventtap").keyStroke({"cmd"}   , ",")
        else
            require("hs.eventtap").keyStroke({"cmd"}   , "w")
        end

        if ok then
            M.toggleState = isPlus
            showOverlay(isPlus and "Larger" or "Smaller")
            return
        else
            notify("Error", err)
            return
        end
    end
end

--------------------------------------------------------------------------------
-- 11) Toggle helper
--------------------------------------------------------------------------------
function M.toggleTextSize()
    M.toggleState = not M.toggleState
    M.adjustTextSize(M.toggleState)
end

--------------------------------------------------------------------------------
-- 12) Hotkey binding including toggle
--------------------------------------------------------------------------------
function M.bindHotkeys(mapping)
    local hotkey = require("hs.hotkey")
    hotkey.bind(mapping.increase.mods, mapping.increase.key, function()
        M.adjustTextSize(true)
    end)
    hotkey.bind(mapping.decrease.mods, mapping.decrease.key, function()
        M.adjustTextSize(false)
    end)
    if mapping.toggle then
        hotkey.bind(mapping.toggle.mods, mapping.toggle.key, function()
            M.toggleTextSize()
        end)
    end
end

return M
