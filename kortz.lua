local SCRIPT_TITLE = "Kortz Heist"

local J = Utils.Joaat
local F = string.format

local function Log(msg)
    Logger.Log(eLogColor.LIGHTGREEN, SCRIPT_TITLE, msg)
end

local function Toast(msg)
    GUI.AddToast(SCRIPT_TITLE, msg, 4000, eToastPos.TOP_RIGHT)
end

local function CharStatHash(name)
    if name:sub(1, 4) == "MPX_" then
        local ok, slot = Stats.GetInt(J("MPPLY_LAST_MP_CHAR"))
        name = F("MP%d_%s", (ok and slot) or 0, name:sub(5))
    end
    return J(name)
end

local function SetInt(name, value)
    Stats.SetInt(CharStatHash(name), value)
end

local function GetInt(name)
    local ok, value = Stats.GetInt(CharStatHash(name))
    return ok and value or 0
end

local function SetBool(name, value)
    Stats.SetBool(CharStatHash(name), value)
end

local function OrInt(name, mask)
    SetInt(name, GetInt(name) | mask)
end

local function AddFeature(def)
    def.hash = J("KHT_" .. def.id)

    FeatureMgr.AddFeature(def.hash, def.name, def.type, def.desc or "", function(f)
        if def.func then
            def.func(f)
        end
    end)

    local feature = FeatureMgr.GetFeature(def.hash)

    if def.list then
        feature:SetList(def.list)
    end

    if def.defv then
        feature:SetDefaultValue(def.defv)
    end

    if def.lims then
        feature:SetLimitValues(def.lims[1], def.lims[2])
    end

    if def.step then
        feature:SetStepSize(def.step)
    end

    if def.defv or def.lims or def.step then
        feature:Reset()
    end

    return def
end

local function GetComboIndex(def)
    return FeatureMgr.GetFeatureListIndex(def.hash)
end

local function GetComboName(def)
    local index = GetComboIndex(def)
    return def.list[index + 1] or "?", index
end

local function SetComboIndex(def, index)
    FeatureMgr.GetFeature(def.hash):SetListIndex(index)
end

local STAT_GENERAL_BS    = "MPX_K26_GENERAL_BS"
local STAT_GENERAL_BS2   = "MPX_K26_GENERAL_BS2"
local STAT_ROBBERY_PROG  = "MPX_K26_ROBBERY_PROG"
local STAT_SCOPING_BS    = "MPX_K26_SCOPING_BS"
local STAT_POI_BS        = "MPX_K26_POI_BS"
local STAT_BUYREQ_BS     = "MPX_K26_BUYREQ_BS"
local STAT_STOLENLAST_BS = "MPX_K26_STOLENLAST_BS"
local STAT_TARGETS_OWNED = "MPX_K26_TARGETS_OWNED_BS"
local STAT_HEIST_TARGET  = "MPX_K26_HEIST_TARGET"
local STAT_HEIST_SEED    = "MPX_K26_HEIST_SEED"
local STAT_COOLDOWN      = "MPX_K26_HEIST_COOLDOWN"
local STAT_COOLDOWN_HARD = "MPX_K26_HEIST_COOLDOWN_HARD"
local STAT_WEEKLY_BOOST  = "MPX_WEEKLY_BOOST_BS"

local MASK_EQUIPMENT_PREPS = 32 | 64 | 128 | 256
local MASK_WEAPON_LOADOUTS = 512 | 1024 | 2048
local MASK_COMPLETE_ALL    = MASK_EQUIPMENT_PREPS | MASK_WEAPON_LOADOUTS

local FINALE_SCRIPT           = "fm_mission_controller_v3"
local LOCAL_FINGERPRINT_STATE = 26866
local LOCAL_VAULT_HACK_STATE  = 27914
local HACK_STATE_SUCCESS      = 5

local GLOBAL_LASER_STATE = 1935711
local LASER_SCRIPT_HASH  = -1624844502 -- joaat("fmmc_lasers")

local NATIVE_THREADS_RUNNING = 0x2C83A9DA6BFFC4F9

local function BypassHack(offset, label)
    if Natives.InvokeInt(NATIVE_THREADS_RUNNING, J(FINALE_SCRIPT)) == 0 then
        Log(F("[Bypass] %s not running — start the finale first", FINALE_SCRIPT))
        Toast("Not in the heist finale.")
        return
    end

    ScriptLocal.SetInt(J(FINALE_SCRIPT), offset, HACK_STATE_SUCCESS)
    Log(F("[Bypass] %s should've been skipped", label))
    Toast(F("%s bypassed.", label))
end

local function DisableLasers()
    if Natives.InvokeInt(NATIVE_THREADS_RUNNING, LASER_SCRIPT_HASH) == 0 then
        Log("[Lasers] Laser room not active — press this inside the vault laser room")
        Toast("Not in the laser room.")
        return
    end

    local state = ScriptGlobal.GetInt(GLOBAL_LASER_STATE) or 0
    ScriptGlobal.SetInt(GLOBAL_LASER_STATE, state | 1 | (1 << 4))

    Log("[Lasers] Vault laser grid deactivated (Global_1935711 bits 0,4) ")
    Toast("Vault lasers disabled.")
end

local function ReloadBoard()
    Log("[Board] Step out of the art room and back in to refresh the board")
    Toast("Step out of the art room and back in to refresh the board.")
end

local LIST_PRIMARY_TARGETS = {
    "La Dernière Débauche ($1.925M)",
    "Hare Oneself Think",
    "The Downfall of Rome",
    "Brother Brother",
    "A Cast of Characters",
    "Gone To Seed",
    "True Love",
    "Breathless",
    "Consumato",
    "I Hear Voices",
    "Winter, Nowhere in Particular",
    "The Girl With the Pearl Necklace",
    "Chat on Fruit",
    "Pumpkin",
    "Twindifference",
    "Stacks Study V",
    "I, Fruit",
    "To Beat About the Bush",
    "In Excess of Success",
    "Juiced",
    "A Winding Road Home",
    "Teckels",
    "Trust",
    "Until Death",
    "What Are Melons?",
    "The Outcome of Endeavour (rotating)",
    "Mi O Melee"
}

local LIST_LOOT_ITEMS = {
    "None",
    "The Great Circle Back ($145K)",
    "Swingset Study No. LXIX ($775K)",
    "With Friends Like These ($850K)",
    "The Hunter Becomes The Hunted ($750K)",
    "La Duchesse ($105K)",
    "Orange Crush ($107.5K)",
    "The Chief ($110K)",
    "Sod Off ($115K)",
    "Cooked ($120K)",
    "Venus d'Algernon (Ivory) ($120K)",
    "Don't Forgo These Blueprints ($150K)",
    "Do You See Me ($105K)",
    "Het Gouden Hondje ($825K)",
    "Coquard Rings ($31K)",
    "Pharaonic Bangles ($31K)",
    "Art Deco Rings ($34K)",
    "Antique Bands ($35K)",
    "Antique Rings ($34K)",
    "Byzantine Hoops ($29K)",
    "Coquard Bracelets ($29K)",
    "Coquard Carcanet (Tanzanite) ($97.5K)",
    "Fertility Statue (Ivory) ($62K)",
    "Fertility Statue (Bronze) ($88K)",
    "Œuf de Coquard décoratif ($54K)",
    "Œuf de Coquard enchanté ($52K)",
    "Memento Non Mori (Emerald) ($77.5K)",
    "Meteorite Fragment ($84K)",
    "Yellow Topaz Gemstone ($107.5K)",
    "Perlino Andalusian ($95K)",
    "Unknown Slot 29",
    "Unknown Slot 30",
    "Unknown Slot 31"
}

local KORTZ_AWARDS = {
    { "MPX_AWD_SCOPING",            "bool", true,    false },
    { "MPX_AWD_PREPPER",            "int",  20,      0     },
    { "MPX_AWD_ADAPTABLE",          "bool", true,    false },
    { "MPX_AWD_KORTZCENTERHEIST",   "bool", true,    false },
    { "MPX_AWD_FINDSAWAY",          "bool", true,    false },
    { "MPX_AWD_WHOSTHERE",          "bool", true,    false },
    { "MPX_AWD_ELITETHIEF",         "bool", true,    false },
    { "MPX_AWD_NOLIFER",            "bool", true,    false },
    { "MPX_AWD_SOLITUDE",           "bool", true,    false },
    { "MPX_AWD_COORDINATION",       "bool", true,    false },
    { "MPX_AWD_FLEXIBLETHIEF",      "bool", true,    false },
    { "MPX_AWD_REPEATOFFENDER",     "int",  10,      0     },
    { "MPX_AWD_FULLBAGS",           "int",  5000000, 0     },
    { "MPX_AWD_HIDDENINPLAINSIGHT", "bool", true,    false },
    { "MPX_AWD_CURATOR",            "int",  5,       0     },
    { "MPX_AWD_LAPIDARY",           "int",  5,       0     },
    { "MPX_AWD_PACIFIST",           "bool", true,    false },
    { "MPX_AWD_PUTRIDPILFERING",    "bool", true,    false },
    { "MPX_AWD_METEORITICS",        "bool", true,    false },
    { "MPX_KORTZMETEOR",            "int",  3,       0     },
    { "MPX_KORTZENTRYPOINTS",       "int",  4,       0     },
    { "MPX_KORTZDIFFPAINTINGS",     "int",  10,      0     },
    { "MPX_LAPIDARY_BS",            "int",  -1,      0     }
}

local Ftr = {}

Ftr.ScopeOut = AddFeature({
    id   = "Scope_Out",
    name = "Complete Scope-Out",
    type = eFeatureType.Button,
    desc = "Marks everything scoped: all paintings, items and POIs.",
    func = function()
        SetInt(STAT_SCOPING_BS, -1)
        SetInt(STAT_POI_BS, -1)
        ReloadBoard()
        Log("[Scoping] Scope-out completed (SCOPING_BS = -1, POI_BS = -1) ")
        Toast("Scope-out completed.")
    end
})

Ftr.PrimaryTarget = AddFeature({
    id   = "Primary_Target",
    name = "",
    type = eFeatureType.Combo,
    desc = "Select the vault painting (primary target).",
    list = LIST_PRIMARY_TARGETS
})

Ftr.GetTarget = AddFeature({
    id   = "Get_Target",
    name = "Get Current",
    type = eFeatureType.Button,
    desc = "Reads the current primary target from the stat.",
    func = function()
        local id = GetInt(STAT_HEIST_TARGET)

        if id >= 0 and id <= 26 then
            SetComboIndex(Ftr.PrimaryTarget, id)
            Log(F("[Target] Current primary target: «%s» (id %d) ", LIST_PRIMARY_TARGETS[id + 1], id))
            Toast(F("Current: %s", LIST_PRIMARY_TARGETS[id + 1]))
        else
            Log(F("[Target] Unknown target id %d ", id))
            Toast(F("Unknown target id %d.", id))
        end
    end
})

Ftr.ApplyTarget = AddFeature({
    id   = "Apply_Target",
    name = "Apply Primary Target",
    type = eFeatureType.Button,
    desc = "Writes the selected primary target. Re-enter the art room to refresh the board.",
    func = function()
        local name, index = GetComboName(Ftr.PrimaryTarget)
        SetInt(STAT_HEIST_TARGET, index)
        ReloadBoard()
        Log(F("[Target] Primary target set to «%s» (id %d)", name, index))
        Toast(F("Target: %s", name))
    end
})

Ftr.CompleteAll = AddFeature({
    id   = "Complete_All",
    name = "Complete ALL Preps",
    type = eFeatureType.Button,
    desc = "Prep skip: scopes everything, completes every prep incl. all 3 unmarked weapon loadouts (Street/Security/Military) and applies the selected target. Re-enter the art room to refresh the board.",
    func = function()
        local name, index = GetComboName(Ftr.PrimaryTarget)

        OrInt(STAT_GENERAL_BS, MASK_COMPLETE_ALL)
        SetInt(STAT_ROBBERY_PROG, 65535)
        SetInt(STAT_SCOPING_BS, -1)
        SetInt(STAT_POI_BS, -1)
        ReloadBoard()

        Log(F("[Preps] ALL preps completed — target «%s» ", name))
        Toast("All preps done.")
    end
})

Ftr.LootSlot1 = AddFeature({
    id   = "Loot_Slot_1",
    name = "Buyer Request 1",
    type = eFeatureType.Combo,
    desc = "First buyer-requested item. Slot order is best-effort — if the wrong item is marked in-game, tell Forlax which one you got.",
    list = LIST_LOOT_ITEMS
})

Ftr.LootSlot2 = AddFeature({
    id   = "Loot_Slot_2",
    name = "Buyer Request 2",
    type = eFeatureType.Combo,
    desc = "Second buyer-requested item.",
    list = LIST_LOOT_ITEMS
})

Ftr.LootSlot3 = AddFeature({
    id   = "Loot_Slot_3",
    name = "Buyer Request 3",
    type = eFeatureType.Combo,
    desc = "Third buyer-requested item.",
    list = LIST_LOOT_ITEMS
})

Ftr.ApplyLoot = AddFeature({
    id   = "Apply_Loot",
    name = "Apply Buyer Requests",
    type = eFeatureType.Button,
    desc = "Writes the selected items to BUYREQ_BS and clears STOLENLAST_BS.",
    func = function()
        local mask  = 0
        local names = {}

        for _, slot in ipairs({ Ftr.LootSlot1, Ftr.LootSlot2, Ftr.LootSlot3 }) do
            local name, index = GetComboName(slot)
            if index > 0 then
                mask = mask | (1 << (index - 1))
                names[#names + 1] = name
            end
        end

        SetInt(STAT_BUYREQ_BS, mask)
        SetInt(STAT_STOLENLAST_BS, 0)
        ReloadBoard()
        Log(F("[Loot] Buyer requests applied: %s (mask 0x%X) ", (#names > 0) and table.concat(names, ", ") or "none", mask))
        Toast("Buyer requests applied.")
    end
})

Ftr.OwnAllPaintings = AddFeature({
    id   = "Own_All_Paintings",
    name = "Own ALL Mansion Paintings",
    type = eFeatureType.Button,
    desc = "Marks every painting as owned/collected (TARGETS_OWNED_BS = -1) so the full mansion gallery is kept. Owned paintings count as already stolen — first-steal bonuses won't apply.",
    func = function()
        SetInt(STAT_TARGETS_OWNED, -1)
        Log("[Paintings] All mansion paintings owned (TARGETS_OWNED_BS = -1) ")
        Toast("All mansion paintings owned.")
    end
})

Ftr.ResetPaintings = AddFeature({
    id   = "Reset_Paintings",
    name = "Reset Owned Paintings",
    type = eFeatureType.Button,
    desc = "Clears the owned-paintings bitset (TARGETS_OWNED_BS = 0) — restores first-steal bonuses and full target rotation.",
    func = function()
        SetInt(STAT_TARGETS_OWNED, 0)
        Log("[Paintings] Owned paintings reset (TARGETS_OWNED_BS = 0) ")
        Toast("Owned paintings reset.")
    end
})

Ftr.ForceSetup = AddFeature({
    id   = "Force_Setup",
    name = "Force Setup Heist (aggressive)",
    type = eFeatureType.Button,
    desc = "Sledgehammer: sets every K26 bitset to -1, rolls a seed and clears cooldowns. Use if the normal prep skip isn't enough.",
    func = function()
        local name, index = GetComboName(Ftr.PrimaryTarget)

        Script.QueueJob(function()
            SetInt(STAT_GENERAL_BS, -1)
            SetInt(STAT_GENERAL_BS2, -1)
            SetInt(STAT_ROBBERY_PROG, -1)
            SetInt(STAT_SCOPING_BS, -1)
            SetInt(STAT_POI_BS, -1)
            SetInt(STAT_BUYREQ_BS, -1)
            SetInt(STAT_TARGETS_OWNED, -1)
            SetInt(STAT_HEIST_SEED, math.random(0, 2147483646))
            SetInt(STAT_COOLDOWN, 0)
            SetInt(STAT_COOLDOWN_HARD, 0)

            Script.Yield(500)

            ReloadBoard()
            Log(F("[Setup] Forced heist setup with target «%s» ", name))
            Toast("Forced setup done.")
        end)
    end
})

Ftr.BypassFingerprint = AddFeature({
    id   = "Bypass_Fingerprint",
    name = "Bypass Fingerprint Hack",
    type = eFeatureType.Button,
    desc = "Instantly completes the fingerprint hack. Press it WHILE the minigame is on screen.",
    func = function()
        BypassHack(LOCAL_FINGERPRINT_STATE, "Fingerprint hack")
    end
})

Ftr.BypassVault = AddFeature({
    id   = "Bypass_Vault",
    name = "Bypass Vault Hack",
    type = eFeatureType.Button,
    desc = "Instantly completes the vault door/keypad hack. Press it WHILE the minigame is on screen.",
    func = function()
        BypassHack(LOCAL_VAULT_HACK_STATE, "Vault hack")
    end
})

Ftr.DisableLasers = AddFeature({
    id   = "Disable_Lasers",
    name = "Disable Vault Lasers",
    type = eFeatureType.Button,
    desc = "Deactivates the entire green-vault laser grid (mirrors a successful laser hack). Press it inside the vault laser room.",
    func = function()
        DisableLasers()
    end
})

Ftr.ClearCooldowns = AddFeature({
    id   = "Clear_Cooldowns",
    name = "Clear Cooldowns",
    type = eFeatureType.Button,
    desc = "Clears the normal and hard-mode heist cooldowns.",
    func = function()
        SetInt(STAT_COOLDOWN, 0)
        SetInt(STAT_COOLDOWN_HARD, 0)
        Log("[Cooldown] Kortz cooldowns cleared ")
        Toast("Cooldowns cleared.")
    end
})

Ftr.WeeklyBoost = AddFeature({
    id   = "Weekly_Boost",
    name = "Enable Weekly Boost",
    type = eFeatureType.Button,
    desc = "Sets MPX_WEEKLY_BOOST_BS to all bits.",
    func = function()
        SetInt(STAT_WEEKLY_BOOST, -1)
        Log("[Boost] Weekly boost enabled (WEEKLY_BOOST_BS = -1) ")
        Toast("Weekly boost enabled.")
    end
})

Ftr.UnlockAwards = AddFeature({
    id   = "Unlock_Awards",
    name = "Unlock Awards",
    type = eFeatureType.Button,
    desc = "Unlocks all Kortz Center heist awards/challenges.",
    func = function()
        for _, award in ipairs(KORTZ_AWARDS) do
            if award[2] == "bool" then
                SetBool(award[1], award[3])
            else
                SetInt(award[1], award[3])
            end
        end

        Log(F("[Awards] %d Kortz awards unlocked ", #KORTZ_AWARDS))
        Toast("Kortz awards unlocked.")
    end
})

Ftr.ResetAwards = AddFeature({
    id   = "Reset_Awards",
    name = "Reset Awards",
    type = eFeatureType.Button,
    desc = "Resets all Kortz Center heist awards/challenges.",
    func = function()
        for _, award in ipairs(KORTZ_AWARDS) do
            if award[2] == "bool" then
                SetBool(award[1], award[4])
            else
                SetInt(award[1], award[4])
            end
        end

        Log(F("[Awards] %d Kortz awards reset ", #KORTZ_AWARDS))
        Toast("Kortz awards reset.")
    end
})

local COL_MUTED = { 0.60, 0.60, 0.60, 1.00 }

local function Muted(text)
    ImGui.TextColored(COL_MUTED[1], COL_MUTED[2], COL_MUTED[3], COL_MUTED[4], text)
end

local function RenderKortzTab()
    Muted("Kortz Heist Helper by Forlax")
    ImGui.Separator()

    if ImGui.BeginTable("KHT_Columns", 2, ImGuiTableFlags.SizingStretchSame) then
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)

        if ClickGUI.BeginCustomChildWindow("Primary Target") then
            ClickGUI.RenderFeature(Ftr.PrimaryTarget.hash)
            ClickGUI.RenderFeature(Ftr.GetTarget.hash)
            ImGui.SameLine()
            ClickGUI.RenderFeature(Ftr.ApplyTarget.hash)
            ClickGUI.EndCustomChildWindow()
        end
        
        if ClickGUI.BeginCustomChildWindow("Scope Out") then
            ClickGUI.RenderFeature(Ftr.ScopeOut.hash)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Preps") then
            ClickGUI.RenderFeature(Ftr.CompleteAll.hash)
            ClickGUI.RenderFeature(Ftr.ForceSetup.hash)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Mansion Paintings") then
            ClickGUI.RenderFeature(Ftr.OwnAllPaintings.hash)
            ClickGUI.RenderFeature(Ftr.ResetPaintings.hash)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Heist Minigames") then
            ClickGUI.RenderFeature(Ftr.BypassFingerprint.hash)
            ClickGUI.RenderFeature(Ftr.BypassVault.hash)
            ClickGUI.RenderFeature(Ftr.DisableLasers.hash)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableNextColumn()

        if ClickGUI.BeginCustomChildWindow("Buyer Requests") then
            ClickGUI.RenderFeature(Ftr.LootSlot1.hash)
            ClickGUI.RenderFeature(Ftr.LootSlot2.hash)
            ClickGUI.RenderFeature(Ftr.LootSlot3.hash)
            ClickGUI.RenderFeature(Ftr.ApplyLoot.hash)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Misc") then
            ClickGUI.RenderFeature(Ftr.ClearCooldowns.hash)
            ClickGUI.RenderFeature(Ftr.WeeklyBoost.hash)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Awards") then
            ClickGUI.RenderFeature(Ftr.UnlockAwards.hash)
            ImGui.SameLine()
            ClickGUI.RenderFeature(Ftr.ResetAwards.hash)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTable()
    end
end

ClickGUI.AddTab(SCRIPT_TITLE, RenderKortzTab)

Log("Kortz Heist Helper by Forlax loaded")
Toast("Kortz Heist Helper by Forlax")
