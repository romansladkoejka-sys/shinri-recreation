if not SERVER then
    return
end

SR = SR or {}
SR.Session = SR.Session or {}
SR.MapRegistry = SR.MapRegistry or {}

local Session = SR.Session
local Phase = Session.Phase
local Config = Session.Config
local Manager = Session.Manager
local Registry = SR.MapRegistry

local QuickGameService = SR.QuickGameService

if not QuickGameService then
    error("[Shinri Quick Game] QuickGameService is missing")
end

QuickGameService.MapTransitionStart =
    QuickGameService.MapTransitionStart
    or QuickGameService.Start

local MapTransitionStart =
    QuickGameService.MapTransitionStart

local academyDefinition =
    Registry.Get("ACADEMY")

if academyDefinition then
    academyDefinition.ExplorationSpawn = {
        Strategy = "FIXED_MAP_PROFILE",

        -- Коридор первого этажа Academy.
        -- Подтверждён entity f1_corridor_lights.
        Position = {
            x = -188,
            y = -2931,
            z = 8
        },

        Angles = {
            p = 0,
            y = -90,
            r = 0
        },

        PlayerSpacing = 48
    }
end

local function FailStart(reason)
    Manager.TransitionLocked = false

    if Manager:GetState() then
        Manager:SetPhase(
            Phase.FAILED,
            reason
        )
    end

    return false, reason
end

local function RestoreWithoutRespawn(ply)
    local record =
        Manager:GetRosterRecord(ply)

    if not record then
        return false, "roster_record_missing"
    end

    local applied =
        Manager:ApplyMembership(
            ply,
            record
        )

    if not applied then
        return false, "membership_restore_failed"
    end

    if record.Restored ~= true then
        record.Restored = true
        record.RestoredAt = os.time()
        record.RestoredName = ply:Nick()

        hook.Run(
            "SR.SessionPlayerRestored",
            ply,
            record,
            Manager:GetState()
        )
    end

    return true
end

function QuickGameService.Start(requestedBy)
    local canStart, startError =
        QuickGameService.CanStart()

    if not canStart then
        return false, startError
    end

    local mapID =
        Config.QuickGameMapID

    local mapDefinition =
        Registry.Get(mapID)

    if not mapDefinition then
        return false, "map_not_registered"
    end

    local currentBSP =
        string.lower(game.GetMap() or "")

    if currentBSP ~= mapDefinition.BSP then
        return MapTransitionStart(
            requestedBy
        )
    end

    Manager.TransitionLocked = true
    Manager:DeleteHandoff()

    Manager:CreateQuickGameSession(
        mapDefinition.ID,
        mapDefinition
    )

    Manager:SetPhase(
        Phase.STARTING,
        "same_map_start"
    )

    local captured, captureError =
        Manager:CaptureCurrentPlayers()

    if not captured then
        return FailStart(
            captureError or "capture_failed"
        )
    end

    hook.Run(
        "SR.QuickGameStarting",
        Manager:GetState(),
        requestedBy
    )

    Manager:SetPhase(
        Phase.LOADING,
        "same_map_loading"
    )

    for _, ply in ipairs(player.GetHumans()) do
        -- Важно: не вызывать Manager:RestorePlayer().
        -- Он планирует ply:Spawn(), который сбрасывает позицию.
        local restored, restoreError =
            RestoreWithoutRespawn(ply)

        if not restored then
            return FailStart(
                restoreError
            )
        end
    end

    Manager:SetPhase(
        Phase.EXPLORATION,
        "same_map_restore_complete"
    )

    Manager.TransitionLocked = false

    hook.Run(
        "SR.QuickGamePlacementRequested",
        Manager:GetState()
    )

    hook.Run(
        "SR.QuickGameStarted",
        Manager:GetState(),
        requestedBy
    )

    return true, Manager:GetState()
end

concommand.Add(
    "sr_quickgame_same_map_status",
    function(ply)
        if IsValid(ply) and not ply:IsAdmin() then
            return
        end

        local definition =
            Registry.Get("ACADEMY")

        print("===== Same Map Quick Game =====")
        print("Map: " .. tostring(game.GetMap()))
        print("Phase: " .. tostring(Manager:GetPhase()))

        if definition and definition.ExplorationSpawn then
            local position =
                definition.ExplorationSpawn.Position

            print(string.format(
                "Academy position: %s %s %s",
                tostring(position.x),
                tostring(position.y),
                tostring(position.z)
            ))
        else
            print("Academy profile: missing")
        end
    end
)