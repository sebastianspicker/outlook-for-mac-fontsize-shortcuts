-- ~/.hammerspoon/outlook-font.lua
--[[
outlook-font.lua

A Hammerspoon module to control the “Text display size” in both Legacy and New
Outlook for Mac, with:
  • External JSON override (supports JSONC-style comments)
  • Canvas-based visual feedback
  • i18n support (multiple languages)
  • Accessibility health-check
  • Dynamic timeouts & retry logic
  • Toggle-cycle state
--]]

local ax = require("outlook_font.ax")
local util = require("outlook_font.util")

local M = {}

local function safe_require(name)
    local ok, mod = pcall(require, name)
    if ok then
        return mod
    end
    return nil
end

--------------------------------------------------------------------------------
-- 1) Default configuration
--------------------------------------------------------------------------------
local defaultCfg = {
    appNames = { "Outlook", "Microsoft Outlook" },
    settingsMenu = { "Outlook", "Settings…" },
    preferencesMenu = { "Outlook", "Preferences…" },
    headerLabels = {
        "Personal Settings",
        "Persönliche Einstellungen",
        "Paramètres personnels",
        "Configuración personal",
    },
    generalLabels = {
        "General",
        "Allgemein",
        "Général",
        "General",
    },
    labelTexts = {
        "Text display size",
        "Größe der Textanzeige",
        "Taille d'affichage du texte",
        "Tamaño de visualización de texto",
    },
    overlayText = {
        larger = "Larger",
        smaller = "Smaller",
    },
    delays = {
        activate = 0.1, -- seconds after app:activate()
        waitInterval = 0.05, -- polling interval
        timeout = 3, -- seconds overall timeout for waits
    },
    retry = {
        attempts = 2, -- number of retries
        interval = 0.2, -- seconds between retries
    },
}

M.cfg = util.deep_copy(defaultCfg)
M.toggleState = false

--------------------------------------------------------------------------------
-- 2) Dependency and notification helpers
--------------------------------------------------------------------------------
M._deps = nil

function M._setDeps(deps)
    M._deps = deps
end

local function get_deps()
    if M._deps then
        return M._deps
    end

    M._deps = {
        application = safe_require("hs.application"),
        axuielement = safe_require("hs.axuielement"),
        canvas = safe_require("hs.canvas"),
        eventtap = safe_require("hs.eventtap"),
        hotkey = safe_require("hs.hotkey"),
        notify = safe_require("hs.notify"),
        screen = safe_require("hs.screen"),
        timer = safe_require("hs.timer"),
    }

    return M._deps
end

local function notify(title, message)
    local deps = get_deps()
    if deps.notify and deps.notify.new then
        deps.notify
            .new({
                title = title,
                informativeText = message,
                autoWithdraw = true,
                withdrawAfter = 3,
            })
            :send()
        return
    end

    if io and io.stderr then
        io.stderr:write(string.format("%s: %s\n", tostring(title), tostring(message)))
    end
end

--------------------------------------------------------------------------------
-- 2.5) Config validation (defensive against invalid override types)
--------------------------------------------------------------------------------
local function is_string_array(value)
    if type(value) ~= "table" then
        return false
    end
    for i = 1, #value do
        if type(value[i]) ~= "string" then
            return false
        end
    end
    for k in pairs(value) do
        if type(k) ~= "number" or k < 1 or k > #value then
            return false
        end
    end
    return true
end

local function sanitize_config(ext)
    if type(ext) ~= "table" then
        return util.deep_copy(defaultCfg)
    end

    local merged = util.deep_merge(util.deep_copy(defaultCfg), ext)
    local warnings = {}

    local function warn(key, expected)
        table.insert(warnings, key .. " (" .. expected .. ")")
    end

    local function reset_top(key)
        merged[key] = util.deep_copy(defaultCfg[key])
    end

    local function ensure_string_array(key)
        if merged[key] ~= nil and not is_string_array(merged[key]) then
            warn(key, "string[]")
            reset_top(key)
        end
    end

    local function ensure_table_with_fields(key, fields)
        if merged[key] == nil then
            return
        end
        if type(merged[key]) ~= "table" then
            warn(key, "table")
            reset_top(key)
            return
        end
        for subkey, expected in pairs(fields) do
            local value = merged[key][subkey]
            if value ~= nil and type(value) ~= expected then
                warn(key .. "." .. subkey, expected)
                merged[key][subkey] = defaultCfg[key][subkey]
            end
        end
    end

    ensure_string_array("appNames")
    ensure_string_array("settingsMenu")
    ensure_string_array("preferencesMenu")
    ensure_string_array("headerLabels")
    ensure_string_array("generalLabels")
    ensure_string_array("labelTexts")

    ensure_table_with_fields("overlayText", { larger = "string", smaller = "string" })
    ensure_table_with_fields("delays", { activate = "number", waitInterval = "number", timeout = "number" })
    ensure_table_with_fields("retry", { attempts = "number", interval = "number" })

    if #warnings > 0 then
        notify("Config Warning", "Invalid config keys reset to defaults: " .. table.concat(warnings, ", "))
    end

    return merged
end

function M._sanitizeConfig(ext)
    return sanitize_config(ext)
end

local function showOverlay(text)
    local deps = get_deps()
    if not (deps.canvas and deps.screen and deps.timer) then
        return
    end

    local main = deps.screen.mainScreen()
    if not main then
        return
    end
    local screen = main:fullFrame()
    local width, height = math.min(300, screen.w * 0.5), 60
    local x = screen.x + (screen.w - width) / 2
    local y = screen.y + (screen.h - height) / 2

    local c = deps.canvas.new({ x = x, y = y, w = width, h = height })
    c[1] = {
        type = "rectangle",
        action = "fill",
        frame = { x = 0, y = 0, w = 1, h = 1 },
        fillColor = { white = 0.1, alpha = 0.8 },
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
        strokeColor = { white = 1, alpha = 0.9 },
        strokeWidth = 2,
    }
    c[2] = {
        type = "text",
        text = text,
        frame = { x = 0, y = 0, w = 1, h = 1 },
        textColor = { white = 1 },
        textSize = 28,
        textFont = "Helvetica Bold",
        alignment = "center",
    }
    c:show()
    deps.timer.doAfter(1.2, function()
        pcall(function()
            c:delete()
        end)
    end)
end

--------------------------------------------------------------------------------
-- 3) Config loading (supports JSONC comments)
--------------------------------------------------------------------------------
local config_loaded = false

function M._resetForTest()
    M.cfg = util.deep_copy(defaultCfg)
    M.toggleState = false
    M._deps = nil
    config_loaded = false
end

local function decode_json(raw)
    local hs_json = safe_require("hs.json")
    if hs_json and hs_json.decode then
        local ok, value = pcall(function()
            return hs_json.decode(raw)
        end)
        if ok then
            return value, nil
        end
        return nil, "hs.json.decode failed"
    end

    local dkjson = safe_require("dkjson")
    if dkjson and dkjson.decode then
        local value, _, err = dkjson.decode(raw)
        if err then
            return nil, err
        end
        return value, nil
    end

    return nil, "no JSON decoder available"
end

local function ensure_config_loaded()
    if config_loaded then
        return
    end
    config_loaded = true

    local home = os.getenv("HOME") or ""
    local cfgPath = M.cfgPath or (home .. "/.hammerspoon/outlook-font.json")
    local f = io.open(cfgPath, "r")
    if not f then
        return
    end
    local raw = f:read("*a")
    f:close()

    local ext, decode_err = decode_json(util.strip_jsonc(raw))
    if type(ext) == "table" then
        M.cfg = sanitize_config(ext)
    elseif ext ~= nil then
        notify("Config Error", string.format("Expected object in %s", cfgPath))
    elseif decode_err then
        notify("Config Error", string.format("Failed to parse %s (%s)", cfgPath, decode_err))
    end
end

--------------------------------------------------------------------------------
-- 4) Outlook discovery and accessibility health-check
--------------------------------------------------------------------------------
local function getOutlookApp()
    local deps = get_deps()
    if not deps.application then
        return nil
    end

    for _, name in ipairs(M.cfg.appNames) do
        local app = deps.application.find(name)
        if app then
            return app
        end
    end
    return nil
end

local function get_ax_app(app)
    local deps = get_deps()
    if not deps.axuielement then
        return nil
    end

    local pid = app and app.pid and app:pid() or nil
    if not pid then
        return nil
    end
    return deps.axuielement.applicationElement(pid)
end

local function healthCheck(app)
    if not app then
        return false
    end

    if not app:isFrontmost() then
        app:activate()
    end

    local axApp = get_ax_app(app)
    if not axApp then
        notify(
            "Accessibility Required",
            "Enable Hammerspoon in System Settings → Privacy & Security → Accessibility"
        )
        return false
    end

    return true
end

--------------------------------------------------------------------------------
-- 5) Wait helpers
--------------------------------------------------------------------------------
local function get_windows(axApp)
    if not axApp then
        return {}
    end
    return axApp:attributeValue("AXWindows") or {}
end

-- Uses a single snapshot (current_windows) to avoid race; prev/current keyed by object identity.
local function find_new_window_from_lists(prev_windows, current_windows)
    local prev = {}
    for _, w in ipairs(prev_windows or {}) do
        prev[w] = true
    end
    for _, w in ipairs(current_windows or {}) do
        if not prev[w] then
            return w
        end
    end
    return nil
end

-- True if window looks like Settings/Preferences (has slider or personal-settings header).
local function is_likely_settings_window(win)
    if not win then
        return false
    end
    if ax.find_first_by_role(win, "AXSlider") then
        return true
    end
    for _, hl in ipairs(M.cfg.headerLabels) do
        if ax.find_static_text(win, hl) then
            return true
        end
    end
    return false
end

local function wait_until(predicate)
    local deps = get_deps()
    local timer = deps.timer
    if not (timer and timer.secondsSinceEpoch and timer.usleep) then
        return predicate()
    end

    local timeout = M.cfg.delays.timeout or 3
    local interval = M.cfg.delays.waitInterval or 0.05

    local start = timer.secondsSinceEpoch()
    while (timer.secondsSinceEpoch() - start) < timeout do
        if predicate() then
            return true
        end
        timer.usleep(interval * 1e6)
    end
    return predicate()
end

local function wait_for_any_label(win)
    return wait_until(function()
        for _, label in ipairs(M.cfg.labelTexts) do
            if ax.find_static_text(win, label) then
                return true
            end
        end
        return false
    end)
end

--------------------------------------------------------------------------------
-- 6) Core function: adjust text size with retry logic
--------------------------------------------------------------------------------
function M.adjustTextSize(isPlus)
    ensure_config_loaded()

    local deps = get_deps()
    if not (deps.timer and deps.eventtap) then
        notify("Missing Dependency", "This module is intended to run inside Hammerspoon.")
        return false
    end

    local app = getOutlookApp()
    if not app then
        notify("Outlook Not Found", "Make sure Outlook is running.")
        return false
    end
    if not healthCheck(app) then
        return false
    end

    local attempts = M.cfg.retry.attempts or 1
    local retry_interval = M.cfg.retry.interval or 0

    for attempt = 1, attempts do
        local opened_window = false
        local ok, err = pcall(function()
            app:activate()
            deps.timer.usleep((M.cfg.delays.activate or 0) * 1e6)

            local axApp = get_ax_app(app)
            if not axApp then
                error("AX application element not available")
            end

            local before = get_windows(axApp)

            local function try_select_menu(menu_path)
                local ok_select, selected = pcall(function()
                    return app:selectMenuItem(menu_path)
                end)
                return ok_select and selected == true
            end

            local modeLegacy
            if try_select_menu(M.cfg.settingsMenu) then
                modeLegacy = false
            elseif try_select_menu(M.cfg.preferencesMenu) then
                modeLegacy = true
            else
                error("Neither Settings nor Preferences was available")
            end

            local win
            wait_until(function()
                local current = get_windows(axApp)
                win = find_new_window_from_lists(before, current)
                if win and not is_likely_settings_window(win) then
                    win = nil
                end
                return win ~= nil
            end)

            if not win then
                error("Settings/Preferences window not found")
            end
            opened_window = true

            if modeLegacy then
                local slider = ax.find_first_by_role(win, "AXSlider")
                if not slider then
                    error("Slider not found")
                end
                local val = slider:attributeValue("AXValue")
                local minv = slider:attributeValue("AXMinValue")
                local maxv = slider:attributeValue("AXMaxValue")
                if val == nil or minv == nil or maxv == nil then
                    error("Slider value range not available")
                end
                local newv = isPlus and math.min(val + 1, maxv) or math.max(val - 1, minv)
                if not slider:setAttributeValue("AXValue", newv) then
                    error("Failed to set slider value")
                end
            else
                local header
                for _, hl in ipairs(M.cfg.headerLabels) do
                    header = ax.find_static_text(win, hl)
                    if header then
                        break
                    end
                end
                if not header then
                    error("Header not found")
                end

                local parent = header:attributeValue("AXParent")
                local siblings = parent and parent:attributeValue("AXChildren") or {}
                local header_idx
                for i, v in ipairs(siblings) do
                    if v == header then
                        header_idx = i
                        break
                    end
                end
                local function press(elem)
                    if not elem then
                        return false
                    end
                    local ok, result = pcall(function()
                        return elem:performAction("AXPress")
                    end)
                    return ok and result == true
                end

                local general = header_idx and header_idx > 1 and siblings[header_idx - 1] or nil
                local pressed = press(general)

                if not pressed then
                    for _, label in ipairs(M.cfg.generalLabels) do
                        local label_node = ax.find_static_text(win, label)
                        if label_node then
                            local btn = ax.find_ancestor_by_role(label_node, "AXButton") or label_node
                            if press(btn) then
                                pressed = true
                                break
                            end
                        end
                    end
                end

                if not pressed then
                    error("General tile not found")
                end

                if not wait_for_any_label(win) then
                    error("Text display size label not found")
                end

                local buttons = ax.find_button_group_near_labels(win, M.cfg.labelTexts)
                if not buttons then
                    error("±-Buttons not found")
                end
                local larger_text, smaller_text = M.cfg.overlayText.larger, M.cfg.overlayText.smaller
                local btn = ax.button_by_size_label(buttons, larger_text, smaller_text, isPlus)
                if not btn then
                    btn = isPlus and buttons[#buttons] or buttons[1]
                end
                if not btn:performAction("AXPress") then
                    error("Failed to press size button")
                end
            end

            deps.eventtap.keyStroke({ "cmd" }, "w")

            M.toggleState = isPlus
            showOverlay(isPlus and M.cfg.overlayText.larger or M.cfg.overlayText.smaller)
        end)

        if ok then
            return true
        end

        if opened_window then
            pcall(function()
                deps.eventtap.keyStroke({ "cmd" }, "w")
            end)
        end

        if attempt < attempts then
            deps.timer.usleep(retry_interval * 1e6)
        else
            notify("Error", tostring(err))
            return false
        end
    end

    return false
end

--------------------------------------------------------------------------------
-- 7) Toggle helper (only updates state on success)
--------------------------------------------------------------------------------
function M.toggleTextSize()
    local next_state = not M.toggleState
    return M.adjustTextSize(next_state)
end

--------------------------------------------------------------------------------
-- 8) Hotkey binding including toggle
--------------------------------------------------------------------------------
function M.bindHotkeys(mapping)
    local deps = get_deps()
    if not deps.hotkey then
        notify("Missing Dependency", "Hotkeys require Hammerspoon.")
        return
    end

    if type(mapping) ~= "table" then
        notify("Config Error", "bindHotkeys: mapping must be a table.")
        return
    end
    local function has_binding(b)
        return type(b) == "table" and type(b.mods) == "table" and b.key ~= nil
    end
    if not has_binding(mapping.increase) or not has_binding(mapping.decrease) then
        notify("Config Error", "bindHotkeys: mapping.increase and mapping.decrease must have .mods (table) and .key.")
        return
    end

    deps.hotkey.bind(mapping.increase.mods, mapping.increase.key, function()
        M.adjustTextSize(true)
    end)
    deps.hotkey.bind(mapping.decrease.mods, mapping.decrease.key, function()
        M.adjustTextSize(false)
    end)
    if mapping.toggle then
        if has_binding(mapping.toggle) then
            deps.hotkey.bind(mapping.toggle.mods, mapping.toggle.key, function()
                M.toggleTextSize()
            end)
        end
    end
end

return M
