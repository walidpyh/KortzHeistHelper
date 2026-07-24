-- ============================================================================
-- Kortz Heist Helper by Forlax for Cherax.menu
-- ============================================================================

local SCRIPT_TITLE = "Kortz Heist"

local J = Utils.Joaat
local F = string.format

local FORCE_EDITION = nil
local EDITION = FORCE_EDITION or string.sub(Cherax.GetEdition(), 1, 2)
local IS_EE   = (EDITION == "EE")

local EE = {
    FINALE_SCRIPT     = "fm_mission_controller_v3",
    FINGERPRINT_STATE = 26866,
    VAULT_HACK_STATE  = 27914,
    LASER_STATE       = 1935711,   -- Global_1935711
    PAINT_STATE       = 29366,     -- primary: 10 then 17 + accept; secondary: 3 + tap
    LASER_LOCAL       = 70416,     -- alt laser method: local mask (+ LASER_STATE global = 1)
    L2_LOOT_BASE      = 4980736 + 1 + 29174, -- Global_4980736.f_29174 cases, stride 333
    BAG_CAPACITY      = 262145 + 38037,      -- Global_262145.f_38037 bag capacity (default 100)
    BOARD_STATE       = 1981302,   -- Global_1980570.f_732
    BOARD_PREV_STATE  = 1981303,   -- .f_1
    BOARD_DONE_FLAGS  = 1981305,   -- .f_3
    BOARD_DIRTY_FLAGS = 1981306,   -- .f_4
    BOARD_ACTIVE      = 1981307,   -- .f_5
    BOARD_INIT_FLAGS  = 1981663    -- Global_1980570.f_1093
}

local LE = {
    FINALE_SCRIPT     = "fm_mission_controller_v3",
    FINGERPRINT_STATE = 26464,
    VAULT_HACK_STATE  = 27512,
    LASER_STATE       = 1935234,   -- Global_1935234
    PAINT_STATE       = 28964,     -- iLocal_28953 + 11
    L2_LOOT_BASE      = 4980736 + 1 + 29174, -- Global_4980736.f_29174 cases, stride 333 (SAME as EE, verified)
    BAG_CAPACITY      = 262145 + 37438,      -- Global_262145.f_37438 bag capacity (default 100)
    BOARD_STATE       = 1980023,   -- Global_1979291.f_732
    BOARD_PREV_STATE  = 1980024,
    BOARD_DONE_FLAGS  = 1980026,
    BOARD_DIRTY_FLAGS = 1980027,
    BOARD_ACTIVE      = 1980028,
    BOARD_INIT_FLAGS  = 1980384    -- Global_1979291.f_1093
}

local CFG = IS_EE and EE or LE

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local STAT_GENERAL_BS    = "MPX_K26_GENERAL_BS"
local STAT_GENERAL_BS2   = "MPX_K26_GENERAL_BS2"
local STAT_ROBBERY_PROG  = "MPX_K26_ROBBERY_PROG"
local STAT_SCOPING_BS    = "MPX_K26_SCOPING_BS"
local STAT_POI_BS        = "MPX_K26_POI_BS"
local STAT_BUYREQ_BS     = "MPX_K26_BUYREQ_BS"
local STAT_STOLENLAST_BS = "MPX_K26_STOLENLAST_BS"
local STAT_TARGETS_OWNED = "MPX_K26_TARGETS_OWNED_BS"
local STAT_HEIST_TARGET  = "MPX_K26_HEIST_TARGET"
local STAT_COOLDOWN      = "MPX_K26_HEIST_COOLDOWN"
local STAT_COOLDOWN_HARD = "MPX_K26_HEIST_COOLDOWN_HARD"
local STAT_WEEKLY_BOOST  = "MPX_WEEKLY_BOOST_BS"

local HACK_STATE_SUCCESS   = 5
local LASER_SCRIPT_HASH    = -1624844502 -- joaat("fmmc_lasers"), same on both builds
local PLANNING_SCRIPT_HASH = J("kortz_planning")

local BOARD_REFRESH_BLOCKED_BIT   = 17
local BOARD_REBUILD_STATE         = 1
local BOARD_ACTIVE_STATE_FALLBACK = 4

local NATIVE_THREADS_RUNNING = 0x2C83A9DA6BFFC4F9

local NATIVE_PLAYER_PED_ID   = 0xD80958FC74E988A6
local NATIVE_GET_ENT_COORDS  = 0x3FEF770D40960D5A -- GET_ENTITY_COORDS
local NATIVE_GET_ENT_HEADING = 0xE83D4F9BA2A38914 -- GET_ENTITY_HEADING
local NATIVE_SET_ENT_COORDS  = 0x239A3351AC1DA385 -- SET_ENTITY_COORDS_NO_OFFSET
local NATIVE_SET_ENT_HEADING = 0x8E2530AA8ADA980E -- SET_ENTITY_HEADING
local NATIVE_GET_INTERIOR    = 0x2107BA504071A6BB -- GET_INTERIOR_FROM_ENTITY
local NATIVE_GET_INTERIOR_AT_COORDS = 0xB0F7F8663821D9C3 -- GET_INTERIOR_AT_COORDS
local NATIVE_SET_CONTROL_VALUE = 0xE8A25867FBA3B05E -- SET_CONTROL_VALUE_NEXT_FRAME
local NATIVE_ENABLE_CONTROL    = 0x351220255D64C155 -- ENABLE_CONTROL_ACTION

local CONTROL_ACCEPT    = 237  -- INPUT_CURSOR_ACCEPT
local CONTROL_SECONDARY = 219

local LASER_LOCAL_VALUE = 4294784 -- alt laser method mask

local BAG_CAPACITY_MAX     = 2000
local BAG_CAPACITY_DEFAULT = 100

local L2_CASE_STRIDE    = 333
local L2_FLAG_A         = 68
local L2_FLAG_B         = 143
local L2_TARGET_INDICES = { 0, 1, 5, 6, 7, 20, 21 } -- horizontal glass (5-7), artwork (20,21)

local TP_POINTS = {
    { "CCTV Server Room", 2625.7615, 5907.5127, -61.0001, 77.6  },
    { "Green Powerbox",   2636.9795, 5862.7124, -61.0001, 270.5 },
    { "Staff Room",       2591.5691, 5927.6030, -48.9999, 89.1  },
    { "Sale Spot",        734.5290, -1934.7460, 29.2877,  23.2, true }
}

local LIST_PRIMARY_TARGETS = {
    "La Dernière Débauche",
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
    "Statue A",          -- slot 0
    "Jewellery A",       -- slot 1
    "Horse Figurine A",  -- slot 2
    "Necklace A",        -- slot 3
    "Skull B",           -- slot 4
    "Bracelet B",        -- slot 5
    "Meteorite",         -- slot 6
    "Idol B",            -- slot 7
    "Bracelet A",        -- slot 8
    "Egg B",             -- slot 9
    "Idol E",            -- slot 10
    "Ring A",            -- slot 11
    "Bracelet C",        -- slot 12
    "Ring B",            -- slot 13
    "Bracelet E",        -- slot 14
    "Ring C",            -- slot 15
    "Egg D",             -- slot 16
    "Bracelet D",        -- slot 17
    "Sod Off (105k)",                     -- slot 18 / Painting A
    "Cooked (115k)",                      -- slot 19 / Painting B
    "The Great Circle Back (142k)",       -- slot 20 / Painting C
    "Dont Forgo These Blueprints (152k)", -- slot 21 / Painting D
    "Do You See Me (117k)",               -- slot 22 / Painting E
    "La Duchesse (105k)",                 -- slot 23 / Painting F
    "Explain Yourself (102k)",            -- slot 24 / Painting G
    "The Chief (105k)",                   -- slot 25 / Painting H
    "Canis Hominem Edit (117k)",          -- slot 26 / Painting I
    "Orange Rush (110k)",                 -- slot 27 / Painting J
    "Painting K",                         -- slot 28
    "Painting L",                         -- slot 29
    "Painting M",                         -- slot 30
    "Painting N"                          -- slot 31
}

-- { stat, type, unlock value, reset value }
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

-- ============================================================================
-- HELPERS funcs
-- ============================================================================

local function Log(msg)
    Logger.Log(eLogColor.LIGHTGREEN, SCRIPT_TITLE, msg)
end

local function Toast(msg)
    GUI.AddToast(SCRIPT_TITLE, msg, 5000, eToastPos.TOP_RIGHT)
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

local function GetComboName(def)
    local index = FeatureMgr.GetFeatureListIndex(def.hash)
    return def.list[index + 1] or "?", index
end

local function SetComboIndex(def, index)
    FeatureMgr.GetFeature(def.hash):SetListIndex(index)
end

local function AddFeature(def)
    def.hash = J("KHT_" .. def.id)

    FeatureMgr.AddFeature(def.hash, def.name, def.type, def.desc or "", function(f)
        if def.func then
            local ok, err = pcall(def.func, f)
            if not ok then
                Log(F("[Error] %s: %s", def.name or "?", tostring(err)))
            end
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

-- ============================================================================
-- ACTIONS
-- ============================================================================

local function NotMapped()
    Log("[Build] This feature isn't mapped for the Legacy build yet")
    Toast("Not supported on the Legacy build yet.")
end

local function SetGlobalBit(global, bit, enabled)
    local value = ScriptGlobal.GetInt(global) or 0

    if enabled then
        value = value | (1 << bit)
    else
        value = value & (~(1 << bit))
    end

    ScriptGlobal.SetInt(global, value)
end

local function BypassHack(offset, label)
    if CFG.FINALE_SCRIPT == nil or offset == nil then
        NotMapped()
        return
    end

    if Natives.InvokeInt(NATIVE_THREADS_RUNNING, J(CFG.FINALE_SCRIPT)) == 0 then
        Log(F("[Bypass] %s not running — start the finale first", CFG.FINALE_SCRIPT))
        return
    end

    ScriptLocal.SetInt(J(CFG.FINALE_SCRIPT), offset, HACK_STATE_SUCCESS)
    Log(F("[Bypass] %s should've been skipped", label))
end

-- My original laser method (used on LE): fmmc_lasers global bits 0|4.
local function CompleteLaserHack()
    if CFG.LASER_STATE == nil then
        NotMapped()
        return
    end

    if Natives.InvokeInt(NATIVE_THREADS_RUNNING, LASER_SCRIPT_HASH) == 0 then
        Log("[Lasers] Laser room not active — press this inside the vault laser room")
        return
    end

    local state = ScriptGlobal.GetInt(CFG.LASER_STATE) or 0
    ScriptGlobal.SetInt(CFG.LASER_STATE, state | 1 | (1 << 4))

    Log("[Lasers] Vault laser grid deactivated (bits 0,4)")
end

local function FinaleActive(offset)
    if offset == nil then
        NotMapped()
        return false
    end
    if Natives.InvokeInt(NATIVE_THREADS_RUNNING, J(CFG.FINALE_SCRIPT)) == 0 then
        Log("[Heist] Finale not running — start the heist finale first")
        Toast("Not in the heist finale.")
        return false
    end
    return true
end

local function TapControl(control)
    Natives.InvokeVoid(NATIVE_ENABLE_CONTROL, 0, control, true)
    Natives.InvokeBool(NATIVE_SET_CONTROL_VALUE, 0, control, 1.0)
end

local function SetFinaleLocal(offset, value)
    ScriptLocal.SetInt(J(CFG.FINALE_SCRIPT), offset, value)
end

local function CompleteLaserHackAlt()
    if not FinaleActive(CFG.LASER_LOCAL) then return end
    if CFG.LASER_STATE == nil then NotMapped() return end

    SetFinaleLocal(CFG.LASER_LOCAL, LASER_LOCAL_VALUE)
    local state = ScriptGlobal.GetInt(CFG.LASER_STATE) or 0
    ScriptGlobal.SetInt(CFG.LASER_STATE, state | 1)

    Log("[Lasers] Alt method applied (local mask + global bit 0)")
    Toast("Lasers disabled (alt).")
end

local function RemoveLasers()
    if IS_EE then
        CompleteLaserHackAlt()
    else
        CompleteLaserHack()
    end
end

local function TakePrimaryTarget()
    if not FinaleActive(CFG.PAINT_STATE) then return end

    Script.QueueJob(function()
        SetFinaleLocal(CFG.PAINT_STATE, 10)
        SetFinaleLocal(CFG.PAINT_STATE, 17)
        Script.Yield(1000)
        TapControl(CONTROL_ACCEPT)
        Log("[Theft] Primary target taken")
        Toast("Primary target taken.")
    end)
end

local function TakeSecondaryTarget()
    if not FinaleActive(CFG.PAINT_STATE) then return end

    SetFinaleLocal(CFG.PAINT_STATE, 3)
    TapControl(CONTROL_SECONDARY)
    Log("[Theft] Secondary target taken")
    Toast("Secondary target taken.")
end

-- EE: set the heist bag capacity global (default 100). big=true -> 999.
local function SetBagCapacity(big)
    if CFG.BAG_CAPACITY == nil then
        NotMapped()
        return
    end

    local value = big and BAG_CAPACITY_MAX or BAG_CAPACITY_DEFAULT
    ScriptGlobal.SetInt(CFG.BAG_CAPACITY, value)
    Log(F("[Bag] Capacity set to %d", value))
end

local bagCapacityEnabled = false
local bagCapacityJobRunning = false

local function StartBagCapacityLoop()
    if bagCapacityJobRunning then return end
    bagCapacityJobRunning = true

    Script.QueueJob(function()
        while bagCapacityEnabled do
            Script.Yield(5000) -- check every 5s (first apply already happened instantly on toggle)

            if bagCapacityEnabled and CFG.BAG_CAPACITY ~= nil then
                local current = ScriptGlobal.GetInt(CFG.BAG_CAPACITY) or 0
                if current ~= BAG_CAPACITY_MAX then
                    ScriptGlobal.SetInt(CFG.BAG_CAPACITY, BAG_CAPACITY_MAX)
                    Log(F("[Bag] Re-applied capacity (%d -> %d) after reset", current, BAG_CAPACITY_MAX))
                end
            end
        end
        bagCapacityJobRunning = false
    end)
end

-- Unlock the restricted Exhibit L2 cases for solo (zero f_68 + f_143).
local function EnableSoloLoot()
    if not FinaleActive(CFG.L2_LOOT_BASE) then return end

    for _, i in ipairs(L2_TARGET_INDICES) do
        local base = CFG.L2_LOOT_BASE + i * L2_CASE_STRIDE
        ScriptGlobal.SetInt(base + L2_FLAG_A, 0)
        ScriptGlobal.SetInt(base + L2_FLAG_B, 0)
    end

    Log("[Loot] Solo secondary targets enabled (L2 cases 5,6,7,20,21)")
end

local function ReloadBoard()
    if CFG.BOARD_STATE == nil then
        Log("[Board] Auto-reload not mapped for Legacy — step out of the art room and back in")
        return
    end

    if Natives.InvokeInt(NATIVE_THREADS_RUNNING, PLANNING_SCRIPT_HASH) == 0 then
        Log("[Board] Planning board is not open or nearby")
        return
    end

    local currentState = ScriptGlobal.GetInt(CFG.BOARD_STATE) or 0
    local previousState = currentState

    if previousState < 1 or previousState > 5 then
        previousState = BOARD_ACTIVE_STATE_FALLBACK
    end

    ScriptGlobal.SetInt(CFG.BOARD_PREV_STATE, previousState)
    SetGlobalBit(CFG.BOARD_DIRTY_FLAGS, previousState, true)
    SetGlobalBit(CFG.BOARD_DONE_FLAGS, previousState, false)
    SetGlobalBit(CFG.BOARD_INIT_FLAGS, BOARD_REFRESH_BLOCKED_BIT, false)
    ScriptGlobal.SetInt(CFG.BOARD_STATE, BOARD_REBUILD_STATE)
    ScriptGlobal.SetInt(CFG.BOARD_ACTIVE, 1)

    Log(F("[Board] Planning board refresh requested from state %d", currentState))
end

local function MyPed()
    return Natives.InvokeInt(NATIVE_PLAYER_PED_ID)
end

local function LogCoords()
    local ped = MyPed()
    local x, y, z = Natives.InvokeV3(NATIVE_GET_ENT_COORDS, ped, false)
    local heading = Natives.InvokeFloat(NATIVE_GET_ENT_HEADING, ped)
    local interior = Natives.InvokeInt(NATIVE_GET_INTERIOR, ped)

    Log(F("[Coords] x=%.3f y=%.3f z=%.3f heading=%.1f interior=%d", x, y, z, heading, interior))
    Log(F("[Coords] paste-ready: { \"Name\", %.4f, %.4f, %.4f, %.1f },", x, y, z, heading))
    Toast(F("Coords logged (interior %d).", interior))
end

local function TeleportTo(x, y, z, heading, openWorld)
    if not openWorld and Natives.InvokeInt(NATIVE_GET_INTERIOR_AT_COORDS, x, y, z) == 0 then
        Log("[TP] Destination interior isn't loaded — go inside the heist first (would drop you in the void)")
        Toast("Not inside the heist — TP skipped.")
        return
    end

    local ped = MyPed()
    Natives.InvokeVoid(NATIVE_SET_ENT_COORDS, ped, x, y, z, false, false, false)
    if heading then
        Natives.InvokeVoid(NATIVE_SET_ENT_HEADING, ped, heading)
    end
end

-- ============================================================================
-- FEATURES
-- ============================================================================

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
        Log("[Scoping] Scope-out completed (SCOPING_BS = -1, POI_BS = -1)")
    end
})

Ftr.CompleteAll = AddFeature({
    id   = "Complete_All",
    name = "Complete Preps",
    type = eFeatureType.Button,
    desc = "Prep skip: scopes everything, completes every prep incl. all 3 unmarked weapon loadouts (Street/Security/Military) and applies the selected target.",
    func = function()
        local name = GetComboName(Ftr.PrimaryTarget)

        SetInt(STAT_GENERAL_BS, -1)
        SetInt(STAT_GENERAL_BS2, -1)
        SetInt(STAT_ROBBERY_PROG, -1)
        SetInt(STAT_SCOPING_BS, -1)
        SetInt(STAT_POI_BS, -1)

        SetInt(STAT_COOLDOWN, 0)
        SetInt(STAT_COOLDOWN_HARD, 0)
        ReloadBoard()

        Log(F("[Preps] ALL preps completed — target «%s»", name))
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
            Log(F("[Target] Current primary target: «%s» (id %d)", LIST_PRIMARY_TARGETS[id + 1], id))
        else
            Log(F("[Target] Unknown target id %d", id))
        end
    end
})

Ftr.ApplyTarget = AddFeature({
    id   = "Apply_Target",
    name = "Apply Primary Target",
    type = eFeatureType.Button,
    desc = "Writes the selected primary target.",
    func = function()
        local name, index = GetComboName(Ftr.PrimaryTarget)
        SetInt(STAT_HEIST_TARGET, index)
        ReloadBoard()
        Log(F("[Target] Primary target set to «%s» (id %d)", name, index))
    end
})

Ftr.ReloadPlanningBoard = AddFeature({
    id   = "Reload_Planning_Board",
    name = "Reload Planning Board",
    type = eFeatureType.Button,
    desc = "Refreshes the planning board.",
    func = function()
        ReloadBoard()
    end
})

Ftr.LootSlot1 = AddFeature({
    id   = "Loot_Slot_1",
    name = "#1",
    type = eFeatureType.Combo,
    desc = "First buyer-requested item.",
    list = LIST_LOOT_ITEMS
})

Ftr.LootSlot2 = AddFeature({
    id   = "Loot_Slot_2",
    name = "#2",
    type = eFeatureType.Combo,
    desc = "Second buyer-requested item.",
    list = LIST_LOOT_ITEMS
})

Ftr.LootSlot3 = AddFeature({
    id   = "Loot_Slot_3",
    name = "#3",
    type = eFeatureType.Combo,
    desc = "Third buyer-requested item.",
    list = LIST_LOOT_ITEMS
})

Ftr.ApplyLoot = AddFeature({
    id   = "Apply_Loot",
    name = "Apply Buyer Requests",
    type = eFeatureType.Button,
    desc = "Apply this AFTER your final scope.",
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
        Log(F("[Loot] Buyer requests applied: %s (mask 0x%X)", (#names > 0) and table.concat(names, ", ") or "none", mask))
    end
})

Ftr.OwnAllPaintings = AddFeature({
    id   = "Own_All_Paintings",
    name = "Own ALL",
    type = eFeatureType.Button,
    desc = "Marks every painting as owned/collected so the full mansion gallery is kept. Owned paintings count as already stolen.",
    func = function()
        SetInt(STAT_TARGETS_OWNED, -1)
        Log("[Paintings] All mansion paintings owned (TARGETS_OWNED_BS = -1)")
        Toast("All mansion paintings owned.")
    end
})

Ftr.ResetPaintings = AddFeature({
    id   = "Reset_Paintings",
    name = "Reset Owned",
    type = eFeatureType.Button,
    desc = "Clears the owned-paintings & restores first-steal bonuses and full target rotation.",
    func = function()
        SetInt(STAT_TARGETS_OWNED, 0)
        Log("[Paintings] Owned paintings reset (TARGETS_OWNED_BS = 0)")
        Toast("Owned paintings reset.")
    end
})

Ftr.BypassFingerprint = AddFeature({
    id   = "Bypass_Fingerprint",
    name = "Fingerprint Hack",
    type = eFeatureType.Button,
    desc = "Instantly completes the fingerprint hack. Press it WHILE the minigame is on screen.",
    func = function()
        BypassHack(CFG.FINGERPRINT_STATE, "Fingerprint hack")
    end
})

Ftr.CompleteLaser = AddFeature({
    id   = "Complete_Laser",
    name = "Remove Lasers",
    type = eFeatureType.Button,
    desc = "Disables the vault laser grid. Press it in the laser room / finale.",
    func = function()
        RemoveLasers()
    end
})

Ftr.BypassVault = AddFeature({
    id   = "Bypass_Vault",
    name = "Vault Hack",
    type = eFeatureType.Button,
    desc = "Instantly completes the vault door/keypad hack. Press it WHILE the minigame is on screen.",
    func = function()
        BypassHack(CFG.VAULT_HACK_STATE, "Vault hack")
    end
})

Ftr.TakePrimary = AddFeature({
    id   = "Take_Primary",
    name = "Take Primary",
    type = eFeatureType.Button,
    desc = "Instantly takes the primary target painting (skips the minigame). Press while stealing...",
    func = function()
        TakePrimaryTarget()
    end
})

Ftr.TakeSecondary = AddFeature({
    id   = "Take_Secondary",
    name = "Take Secondary",
    type = eFeatureType.Button,
    desc = "Instantly takes the secondary targets (Paintings). Press while stealing...",
    func = function()
        TakeSecondaryTarget()
    end
})

Ftr.SoloLoot = AddFeature({
    id   = "Solo_Loot",
    name = "Solo Exhibit L2",
    type = eFeatureType.Button,
    desc = "Unlocks the restricted Exhibit L2 loot for solo.",
    func = function()
        EnableSoloLoot()
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
        Log("[Cooldown] Kortz cooldowns cleared")
    end
})

Ftr.WeeklyBoost = AddFeature({
    id   = "Weekly_Boost",
    name = "Enable Weekly Boost",
    type = eFeatureType.Button,
    desc = "Enables the weekly boost which increases hugely the primary targets prices. USE WITH CAUTION",
    func = function()
        SetInt(STAT_WEEKLY_BOOST, 1)
        Log("[Boost] Weekly boost enabled (WEEKLY_BOOST_BS = 1)")
    end
})
 
Ftr.BagCapacity = AddFeature({
    id   = "Bag_Capacity",
    name = "Fat Bag",
    type = eFeatureType.Toggle,
    desc = "Raises the heist bag capacity so you can carry far more loot. USE WITH CAUTION.",
    func = function(f)
        bagCapacityEnabled = f:IsToggled()

        if bagCapacityEnabled then
            SetBagCapacity(true)
            StartBagCapacityLoop()
        else
            SetBagCapacity(false)
        end
    end
})


Ftr.TpButtons = {}
for i, p in ipairs(TP_POINTS) do
    Ftr.TpButtons[i] = AddFeature({
        id   = "TP_Go_" .. i,
        name = p[1],
        type = eFeatureType.Button,
        desc = F("Teleport to %s.", p[1]),
        func = function()
            TeleportTo(p[2], p[3], p[4], p[5], p[6])
            Log(F("[TP] Teleported to «%s» (%.1f, %.1f, %.1f)", p[1], p[2], p[3], p[4]))
            Toast(F("Teleported to %s.", p[1]))
        end
    })
end

Ftr.LogCoords = AddFeature({
    id   = "Log_Coords",
    name = "Log My Coords",
    type = eFeatureType.Button,
    desc = "Debug: logs your current position, heading and interior id. Paste the logged line into TP_POINTS at the top to add a new destination.",
    func = function()
        LogCoords()
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

        Log(F("[Awards] %d Kortz awards unlocked", #KORTZ_AWARDS))
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

        Log(F("[Awards] %d Kortz awards reset", #KORTZ_AWARDS))
    end
})

-- ============================================================================
-- UI
-- ============================================================================

local COL_MUTED = { 0.60, 0.60, 0.60, 1.00 }

local function Muted(text)
    ImGui.TextColored(COL_MUTED[1], COL_MUTED[2], COL_MUTED[3], COL_MUTED[4], text)
end

local function RenderKortzTab()
    Muted(F("Heist Helper by Forlax  [%s]", IS_EE and "Enhanced" or "Legacy"))
    ImGui.Separator()

    if ImGui.BeginTable("KHT_Columns", 2, ImGuiTableFlags.SizingStretchSame) then
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)

        if ClickGUI.BeginCustomChildWindow("Preparations") then
            ClickGUI.RenderFeature(Ftr.ScopeOut.hash)
            ImGui.SameLine()
            ClickGUI.RenderFeature(Ftr.CompleteAll.hash)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Primary Target") then
            ClickGUI.RenderFeature(Ftr.PrimaryTarget.hash)
            ClickGUI.RenderFeature(Ftr.GetTarget.hash)
            ImGui.SameLine()
            ClickGUI.RenderFeature(Ftr.ApplyTarget.hash)
            ClickGUI.RenderFeature(Ftr.ReloadPlanningBoard.hash)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Mansion Paintings") then
            ClickGUI.RenderFeature(Ftr.OwnAllPaintings.hash)
            ImGui.SameLine()
            ClickGUI.RenderFeature(Ftr.ResetPaintings.hash)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Heist Minigames") then
            ClickGUI.RenderFeature(Ftr.BypassFingerprint.hash)
            ImGui.SameLine()
            ClickGUI.RenderFeature(Ftr.BypassVault.hash)
            ClickGUI.RenderFeature(Ftr.CompleteLaser.hash)

            ImGui.SameLine()
            ClickGUI.RenderFeature(Ftr.SoloLoot.hash)
            ClickGUI.RenderFeature(Ftr.TakePrimary.hash)
            ImGui.SameLine()
            ClickGUI.RenderFeature(Ftr.TakeSecondary.hash)

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

        if ClickGUI.BeginCustomChildWindow("Teleports") then
            for i, btn in ipairs(Ftr.TpButtons) do
                ClickGUI.RenderFeature(btn.hash)
                if i % 2 == 1 and i < #Ftr.TpButtons then
                    ImGui.SameLine()
                end
            end
            --ClickGUI.RenderFeature(Ftr.LogCoords.hash)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Misc") then
            ClickGUI.RenderFeature(Ftr.ClearCooldowns.hash)
            ImGui.SameLine()
            ClickGUI.RenderFeature(Ftr.WeeklyBoost.hash)
            ClickGUI.RenderFeature(Ftr.BagCapacity.hash)
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

Log(F("Kortz Heist Helper by Forlax loaded (%s build)", IS_EE and "Enhanced" or "Legacy"))
Toast("Helper by Forlax")
