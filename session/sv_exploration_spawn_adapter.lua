if not SERVER then
    return
end

SR = SR or {}
SR.Session = SR.Session or {}
SR.MapRegistry = SR.MapRegistry or {}

local Session = SR.Session
local Phase = Session.Phase
local Manager = Session.Manager
local SpawnManager = Session.SpawnManager
local Registry = SR.MapRegistry

local Adapter =
    Session.ExplorationSpawnAdapter
    or {}

Session.ExplorationSpawnAdapter = Adapter

local PLAYER_OFFSETS = {
    Vector(0, 0, 0),
    Vector(48, 0, 0),
    Vector(-48, 0, 0),
    Vector(0, 48, 0),
    Vector(0, -48, 0),
    Vector(48, 48, 0),
    Vector(-48, 48, 0),
    Vector(48, -48, 0),
    Vector(-48, -48, 0)
}

function Adapter:GetProfile()
    local state = Manager:GetState()

    if not state then
        return nil
    end

    local mapDefinition =
        Registry.Get(state.MapID)

    if not mapDefinition then
        return nil
    end

    return mapDefinition.ExplorationSpawn
end

function Adapter:GetStableIndex(ply)
    if SpawnManager
        and SpawnManager.GetStablePlayerIndex then
        return SpawnManager:GetStablePlayerIndex(ply)
    end

    return math.max(
        ply:UserID(),
        1
    )
end

function Adapter:GetDestination(ply)
    local profile = self:GetProfile()

    if not profile
        or not istable(profile.Position) then
        return nil, nil, "profile_missing"
    end

    local basePosition = Vector(
        tonumber(profile.Position.x) or 0,
        tonumber(profile.Position.y) or 0,
        tonumber(profile.Position.z) or 0
    )

    local index =
        self:GetStableIndex(ply)

    local offsetIndex =
        ((index - 1) % #PLAYER_OFFSETS) + 1

    local spacing =
        math.max(
            tonumber(profile.PlayerSpacing) or 48,
            1
        )

    local normalizedOffset =
        PLAYER_OFFSETS[offsetIndex]

    local offset = Vector(
        normalizedOffset.x / 48 * spacing,
        normalizedOffset.y / 48 * spacing,
        normalizedOffset.z
    )

    local angles = Angle(
        tonumber(profile.Angles and profile.Angles.p) or 0,
        tonumber(profile.Angles and profile.Angles.y) or -90,
        tonumber(profile.Angles and profile.Angles.r) or 0
    )

    return basePosition + offset, angles
end

function Adapter:PlacePlayer(ply, reason)
    if not IsValid(ply)
        or not ply:IsPlayer() then
        return false, "invalid_player"
    end

    if Manager:GetPhase()
        ~= Phase.EXPLORATION then
        return false, "not_exploration"
    end

    if string.lower(game.GetMap())
        ~= "dro_hopespeak_v3" then
        return false, "wrong_map"
    end

    local record =
        Manager:GetRosterRecord(ply)

    if not record then
        return false, "not_session_member"
    end

    local position, angles, destinationError =
        self:GetDestination(ply)

    if not position then
        return false, destinationError
    end

    if ply:InVehicle() then
        ply:ExitVehicle()
    end

    ply:SetPos(position)
    ply:SetEyeAngles(angles)
    ply:SetVelocity(-ply:GetVelocity())

    timer.Simple(0, function()
        if not IsValid(ply) then
            return
        end

        ply:SetPos(position)
        ply:DropToFloor()
        ply:SetEyeAngles(angles)
        ply:SetVelocity(-ply:GetVelocity())
    end)

    ply.SRExplorationPlaced = true
    ply.SRExplorationPosition = position

    hook.Run(
        "SR.ExplorationPlayerPlaced",
        ply,
        position,
        reason
    )

    print(string.format(
        "[Shinri Exploration] PLACED %s at %s | reason=%s",
        ply:Nick(),
        tostring(position),
        tostring(reason or "unknown")
    ))

    return true
end

function Adapter:QueuePlayer(ply, reason)
    if not IsValid(ply) then
        return
    end

    ply.SRExplorationPlacementGeneration =
        (ply.SRExplorationPlacementGeneration or 0)
        + 1

    local generation =
        ply.SRExplorationPlacementGeneration

    local delays = {
        0.05,
        0.25,
        0.75,
        1.50
    }

    for attempt, delay in ipairs(delays) do
        timer.Simple(delay, function()
            if not IsValid(ply) then
                return
            end

            if ply.SRExplorationPlacementGeneration
                ~= generation then
                return
            end

            local success, placementError =
                Adapter:PlacePlayer(
                    ply,
                    tostring(reason or "queue")
                        .. "_attempt_"
                        .. tostring(attempt)
                )

            if not success then
                print(string.format(
                    "[Shinri Exploration] FAILED %s | error=%s | attempt=%d",
                    ply:Nick(),
                    tostring(placementError),
                    attempt
                ))
            end
        end)
    end
end

function Adapter:PlaceAll(reason)
    local placed = 0

    for _, ply in ipairs(player.GetHumans()) do
        if Manager:GetRosterRecord(ply) then
            self:QueuePlayer(
                ply,
                reason
            )

            placed = placed + 1
        end
    end

    print(
        "[Shinri Exploration] Placement queued for "
        .. tostring(placed)
        .. " player(s)"
    )
end

hook.Add(
    "SR.QuickGamePlacementRequested",
    "SR.ExplorationSpawn.QuickGamePlacement",
    function()
        Adapter:PlaceAll(
            "quick_game_request"
        )
    end
)

hook.Add(
    "SR.ExplorationStarted",
    "SR.ExplorationSpawn.PhaseStarted",
    function()
        Adapter:PlaceAll(
            "exploration_started"
        )
    end
)

hook.Add(
    "SR.QuickGameStarted",
    "SR.ExplorationSpawn.QuickGameStarted",
    function()
        Adapter:PlaceAll(
            "quick_game_started"
        )
    end
)

hook.Add(
    "PlayerSpawn",
    "SR.ExplorationSpawn.Respawn",
    function(ply)
        timer.Simple(0.1, function()
            if not IsValid(ply) then
                return
            end

            if Manager:GetPhase()
                ~= Phase.EXPLORATION then
                return
            end

            if not Manager:GetRosterRecord(ply) then
                return
            end

            Adapter:QueuePlayer(
                ply,
                "player_spawn"
            )
        end)
    end
)

concommand.Add(
    "sr_exploration_place_players",
    function(ply)
        if IsValid(ply) and not ply:IsAdmin() then
            return
        end

        Adapter:PlaceAll(
            "manual_command"
        )
    end
)

concommand.Add(
    "sr_exploration_spawn_status",
    function(ply)
        if IsValid(ply) and not ply:IsAdmin() then
            return
        end

        print("===== Exploration Spawn Status =====")
        print("Map: " .. tostring(game.GetMap()))
        print("Phase: " .. tostring(Manager:GetPhase()))

        local profile = Adapter:GetProfile()

        print(
            "Profile: "
            .. tostring(profile ~= nil)
        )

        for _, target in ipairs(player.GetAll()) do
            print(string.format(
                "%s | pos=%s | member=%s | placed=%s",
                target:Nick(),
                tostring(target:GetPos()),
                tostring(
                    Manager:GetRosterRecord(target)
                        ~= nil
                ),
                tostring(
                    target.SRExplorationPlaced
                        == true
                )
            ))
        end
    end
)