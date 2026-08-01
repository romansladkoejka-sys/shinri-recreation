SR = SR or {}
SR.MapRegistry = SR.MapRegistry or {}

local Registry = SR.MapRegistry

Registry.Entries = Registry.Entries or {}

local function NormalizeID(id)
    if not isstring(id) then
        return ""
    end

    return string.upper(string.Trim(id))
end

function Registry.Register(id, definition)
    id = NormalizeID(id)

    assert(id ~= "", "Map Registry ID is required")
    assert(istable(definition), "Map Registry definition must be a table")
    assert(
        isstring(definition.BSP)
            and definition.BSP ~= "",
        "Map Registry BSP is required"
    )

    local defaultPhase =
        definition.DefaultPhase
        or SR.Session.Phase.EXPLORATION

    assert(
        SR.Session.IsValidPhase(defaultPhase),
        "Map Registry DefaultPhase is invalid"
    )

    Registry.Entries[id] = {
        ID = id,
        BSP = string.lower(definition.BSP),
        Provider = definition.Provider or "UNKNOWN",
        DefaultPhase = defaultPhase
    }

    return Registry.Entries[id]
end

function Registry.Get(id)
    return Registry.Entries[NormalizeID(id)]
end

function Registry.Exists(id)
    return Registry.Get(id) ~= nil
end

function Registry.ResolveBSP(id)
    local definition = Registry.Get(id)

    if not definition then
        return nil
    end

    return definition.BSP
end

Registry.Register("ACADEMY", {
    BSP = "dro_hopespeak_v3",
    Provider = "ORIGINAL",
    DefaultPhase = SR.Session.Phase.EXPLORATION
})

-- SR_ACADEMY_EXPLORATION_SPAWN_BEGIN
local academyDefinition = Registry.Get("ACADEMY")

if academyDefinition then
    academyDefinition.ExplorationSpawn = {
        Strategy = "ENTITY_ANCHOR",

        -- Основная часть Academy, возле оригинального кота.
        TargetName = "lobby-china_cat_meow_button",

        Radius = 192,
        VerticalSearch = 768,

        FallbackPosition = {
            x = 3923,
            y = 251,
            z = 32
        }
    }
end
-- SR_ACADEMY_EXPLORATION_SPAWN_END