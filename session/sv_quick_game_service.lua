if not SERVER then
    return
end

SR = SR or {}
SR.Session = SR.Session or {}

local Session = SR.Session
local Manager = Session.Manager
local Registry = SR.MapRegistry
local Phase = Session.Phase
local Config = Session.Config

local QuickGameService =
    SR.QuickGameService
    or {}

SR.QuickGameService =
    QuickGameService

function QuickGameService.CanStart()
    if Manager.TransitionLocked then
        return false, "transition_locked"
    end

    local phase = Manager:GetPhase()

    if phase ~= Phase.LOBBY
        and phase ~= Phase.FAILED then
        return false,
            "invalid_phase_"
            .. tostring(phase)
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

    local mapPath =
        "maps/"
        .. mapDefinition.BSP
        .. ".bsp"

    local mapAvailable =
        file.Exists(mapPath, "GAME")
        or string.lower(game.GetMap())
            == mapDefinition.BSP

    if not mapAvailable then
        return false, "map_bsp_not_mounted"
    end

    Manager.TransitionLocked = true

    Manager:CreateQuickGameSession(
        mapDefinition.ID,
        mapDefinition
    )

    Manager:SetPhase(
        Phase.STARTING,
        "quick_game_start"
    )

    local captured, captureError =
        Manager:CaptureCurrentPlayers()

    if not captured then
        Manager.TransitionLocked = false

        Manager:SetPhase(
            Phase.FAILED,
            captureError
        )

        return false, captureError
    end

    hook.Run(
        "SR.QuickGameStarting",
        Manager:GetState(),
        requestedBy
    )

    Manager:SetPhase(
        Phase.LOADING,
        "handoff_prepare"
    )

    local saved, saveError =
        Manager:SaveHandoff()

    if not saved then
        Manager.TransitionLocked = false

        Manager:SetPhase(
            Phase.FAILED,
            saveError
        )

        return false, saveError
    end

    hook.Run(
        "SR.QuickGameMapLoadRequested",
        mapDefinition,
        Manager:GetState()
    )

    timer.Simple(0.5, function()
        if not Manager.TransitionLocked then
            return
        end

        RunConsoleCommand(
            "changelevel",
            mapDefinition.BSP
        )
    end)

    return true, Manager:GetState()
end

concommand.Add(
    "sr_quickgame_start",
    function(ply)
        if IsValid(ply)
            and not ply:IsAdmin() then
            print(
                "[Shinri Quick Game] "
                .. "Admin permission required."
            )

            return
        end

        local success, result =
            QuickGameService.Start(ply)

        if not success then
            print(
                "[Shinri Quick Game] "
                .. "Start failed: "
                .. tostring(result)
            )

            return
        end

        print(
            "[Shinri Quick Game] "
            .. "Session started: "
            .. tostring(
                result.SessionID
            )
        )

        print(
            "[Shinri Quick Game] "
            .. "Target MapID: "
            .. tostring(result.MapID)
        )

        print(
            "[Shinri Quick Game] "
            .. "Target BSP: "
            .. tostring(result.BSP)
        )
    end
)

concommand.Add(
    "sr_session_status",
    function(ply)
        if IsValid(ply)
            and not ply:IsAdmin() then
            return
        end

        local state =
            Manager:GetState()

        print(
            "===== Shinri Session Status ====="
        )

        if not state then
            print("State: NONE")
            return
        end

        local restored, expected =
            Manager:GetRestoreCounts()

        print(
            "Type: "
            .. tostring(state.Type)
        )

        print(
            "Phase: "
            .. tostring(state.Phase)
        )

        print(
            "SessionID: "
            .. tostring(state.SessionID)
        )

        print(
            "MapID: "
            .. tostring(state.MapID)
        )

        print(
            "BSP: "
            .. tostring(state.BSP)
        )

        print(
            "Provider: "
            .. tostring(state.Provider)
        )

        print(
            "Players restored: "
            .. tostring(restored)
            .. "/"
            .. tostring(expected)
        )

        for index, record in ipairs(
            Manager.Roster
        ) do
            print(string.format(
                "#%d SteamID64=%s Name=%s Character=%s Ready=%s Restored=%s",
                index,
                tostring(record.SteamID64),
                tostring(record.PlayerName),
                tostring(record.Character),
                tostring(record.ReadyState),
                tostring(record.Restored)
            ))
        end
    end
)

concommand.Add(
    "sr_session_ready",
    function(ply, _, args)
        if not IsValid(ply) then
            return
        end

        local value =
            tonumber(args[1] or "1")
            ~= 0

        Session.CharacterAdapter:
            RestoreReadyState(
                ply,
                value
            )

        print(
            "[Shinri Session] "
            .. ply:Nick()
            .. " ready state: "
            .. tostring(value)
        )
    end
)

hook.Add(
    "SR.RequestQuickGameStart",
    "SR.QuickGameService.Start",
    function(requestedBy)
        return QuickGameService.Start(
            requestedBy
        )
    end
)