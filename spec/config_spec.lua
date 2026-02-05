require("spec.spec_helper")

local of = require("outlook-font")

describe("outlook-font config validation", function()
    it("resets invalid types to defaults and keeps unknown keys", function()
        local cfg = {
            appNames = "Outlook",
            generalLabels = "General",
            labelTexts = { "Text display size", 123 },
            delays = "fast",
            retry = { attempts = "nope" },
            overlayText = { larger = 1 },
            extraKey = "keep",
        }

        local sanitized = of._sanitizeConfig(cfg)
        assert.same({ "Outlook", "Microsoft Outlook" }, sanitized.appNames)
        assert.same({ "General", "Allgemein", "Général", "General" }, sanitized.generalLabels)
        assert.same({
            "Text display size",
            "Größe der Textanzeige",
            "Taille d'affichage du texte",
            "Tamaño de visualización de texto",
        }, sanitized.labelTexts)
        assert.equals(0.1, sanitized.delays.activate)
        assert.equals(0.05, sanitized.delays.waitInterval)
        assert.equals(3, sanitized.delays.timeout)
        assert.equals(2, sanitized.retry.attempts)
        assert.equals(0.2, sanitized.retry.interval)
        assert.equals("Larger", sanitized.overlayText.larger)
        assert.equals("Smaller", sanitized.overlayText.smaller)
        assert.equals("keep", sanitized.extraKey)
    end)

    it("keeps valid overrides", function()
        local cfg = {
            appNames = { "Outlook" },
            delays = { timeout = 9 },
            retry = { attempts = 4 },
            overlayText = { larger = "Bigger", smaller = "Smaller" },
        }

        local sanitized = of._sanitizeConfig(cfg)
        assert.same({ "Outlook" }, sanitized.appNames)
        assert.equals(9, sanitized.delays.timeout)
        assert.equals(4, sanitized.retry.attempts)
        assert.equals("Bigger", sanitized.overlayText.larger)
        assert.equals("Smaller", sanitized.overlayText.smaller)
    end)
end)
