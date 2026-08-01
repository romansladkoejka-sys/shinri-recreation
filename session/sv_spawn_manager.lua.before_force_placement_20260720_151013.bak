if not SERVER then
    return
end

SR = SR or {}
SR.Session = SR.Session or {}

local Session = SR.Session
local Manager = Session.Manager

local SpawnManager =
    Session.SpawnManager
    or {}

Session.SpawnManager = SpawnManager

SpawnManager.CachedMap = nil
SpawnManager.CachedPoints = {}
SpawnManager.WarnedMissing = false

local function GetMapCreationID(ent)
    if not IsValid(ent)
        or not ent.MapCreationID then
        return -1
    end

    return tonumber(ent:MapCreationID())
        or -1
end

local function ComparePositions(first, second)
    local firstPosition = first:GetPos()
    local secondPosition = second:GetPos()

    if firstPosition.x
        ~= secondPosition.x then
        return firstPosition.x
            < secondPosition.x
    end

    if firstPosition.y
        ~= secondPosition.y then
        return firstPosition.y
            < secondPosition.y
    end

    if firstPosition.z
        ~= secondPosition.z then
        return firstPosition.z
            < secondPosition.z
    end

    return first:EntIndex()
        < second:EntIndex()
end

function SpawnManager:Refresh()
    self.CachedMap = game.GetMap()
    self.CachedPoints = {}

    for _, ent in ipairs(
        ents.FindByClass(
            "info_player_start"
        )
    ) do
        if IsValid(ent) then
            self.CachedPoints[
                #self.CachedPoints + 1
            ] = ent
        end
    end

    table.sort(
        self.CachedPoints,
        function(first, second)
            local firstID =
                GetMapCreationID(first)

            local secondID =
                GetMapCreationID(second)

            if firstID >= 0
                and secondID >= 0
                and firstID ~= secondID then
                return firstID < secondID
            end

            if firstID >= 0
                and secondID < 0 then
                return true
            end

            if firstID < 0
                and secondID >= 0 then
                return false
            end

            return ComparePositions(
                first,
                second
            )
        end
    )

    self.WarnedMissing = false

    hook.Run(
        "SR.SessionSpawnPointsRefreshed",
        self.CachedPoints
    )

    return self.CachedPoints
end

function SpawnManager:GetPoints()
    if self.CachedMap ~= game.GetMap() then
        return self:Refresh()
    end

    local validPoints = {}

    for _, point in ipairs(
        self.CachedPoints
    ) do
        if IsValid(point) then
            validPoints[
                #validPoints + 1
            ] = point
        end
    end

    if #validPoints
        ~= #self.CachedPoints then
        self.CachedPoints = validPoints
    end

    return self.CachedPoints
end

function SpawnManager:GetStablePlayerIndex(ply)
    local record =
        Manager:GetRosterRecord(ply)

    if record
        and tonumber(record.JoinOrder) then
        return math.max(
            math.floor(record.JoinOrder),
            1
        )
    end

    local players =
        table.Copy(player.GetHumans())

    table.sort(players, function(first, second)
        local firstKey =
            Manager:GetPlayerKey(first)

        local secondKey =
            Manager:GetPlayerKey(second)

        if firstKey == secondKey then
            return first:UserID()
                < second:UserID()
        end

        return firstKey < secondKey
    end)

    for index, target in ipairs(players) do
        if target == ply then
            return index
        end
    end

    return 1
end

function SpawnManager:Select(ply)
    local points = self:GetPoints()

    if #points == 0 then
        if not self.WarnedMissing then
            self.WarnedMissing = true

            print(
                "[Shinri Session] "
                .. "No info_player_start found. "
                .. "Using gamemode fallback."
            )
        end

        hook.Run(
            "SR.SessionSpawnFallback",
            ply
        )

        return nil
    end

    local playerIndex =
        self:GetStablePlayerIndex(ply)

    local spawnIndex =
        ((playerIndex - 1) % #points) + 1

    local selected =
        points[spawnIndex]

    hook.Run(
        "SR.SessionSpawnSelected",
        ply,
        selected,
        spawnIndex,
        playerIndex
    )

    return selected
end

hook.Add(
    "InitPostEntity",
    "SR.Session.RefreshSpawnPoints",
    function()
        timer.Simple(0, function()
            SpawnManager:Refresh()
        end)
    end
)

hook.Add(
    "PostCleanupMap",
    "SR.Session.RefreshSpawnPointsAfterCleanup",
    function()
        timer.Simple(0, function()
            SpawnManager:Refresh()
        end)
    end
)

hook.Add(
    "PlayerSelectSpawn",
    "SR.Session.StableSpawn",
    function(ply)
        if not Manager:IsGameplayMapActive() then
            return
        end

        return SpawnManager:Select(ply)
    end
)

concommand.Add(
    "sr_session_spawns",
    function(ply)
        if IsValid(ply)
            and not ply:IsAdmin() then
            return
        end

        local points =
            SpawnManager:Refresh()

        print(
            "[Shinri Session] "
            .. "info_player_start count: "
            .. tostring(#points)
        )

        for index, point in ipairs(points) do
            print(string.format(
                "  #%d mapID=%d ent=%d pos=%s",
                index,
                GetMapCreationID(point),
                point:EntIndex(),
                tostring(point:GetPos())
            ))
        end
    end
)