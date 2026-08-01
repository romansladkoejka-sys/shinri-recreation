if not SERVER then
    return
end

SR = SR or {}
SR.Music = SR.Music or {}

local Music = SR.Music
local Manager = Music.Manager
local Config = Music.Config

local Lobby = Music.Lobby or {}
Music.Lobby = Lobby

Lobby.Inside = Lobby.Inside or setmetatable({}, {
    __mode = "k"
})

Lobby.Managed = Lobby.Managed or setmetatable({}, {
    __mode = "k"
})

Lobby.Zones = {}

local function NormalizeSoundPath(path)
    if not isstring(path) then
        return ""
    end

    path = string.lower(path)
    path = string.Replace(path, "\\", "/")
    path = string.gsub(path, "^sound/", "")

    return path
end

function Lobby:IsDedicatedLobbyMap()
    local mapName = string.lower(game.GetMap() or "")

    return Config.LobbyMaps[mapName] == true
end

function Lobby:Enter(ply)
    return Manager:Request(
        ply,
        Config.LobbyOwner,
        Config.LobbyCue,
        {
            priority = Config.LobbyPriority,
            fadeIn = Config.DefaultFadeIn,
            fadeOut = Config.DefaultFadeOut
        }
    )
end

function Lobby:Leave(ply)
    return Manager:Release(
        ply,
        Config.LobbyOwner
    )
end

function Lobby:SetPlayerInside(ply, inside, source)
    if not IsValid(ply) then
        return
    end

    inside = inside == true

    local previous = self.Inside[ply] == true

    if previous == inside then
        return
    end

    self.Inside[ply] = inside

    if inside then
        self:Enter(ply)
    else
        self:Leave(ply)
    end

    hook.Run(
        "SR.LobbyMusicPresenceChanged",
        ply,
        previous,
        inside,
        source
    )
end

function Lobby:IsLegacyAmbient(ent)
    if not IsValid(ent) then
        return false
    end

    if ent:GetClass() ~= "ambient_generic" then
        return false
    end

    local track = Music.GetTrack(Config.LobbyCue)

    if not track then
        return false
    end

    local keyValues = ent:GetKeyValues() or {}

    local actual = NormalizeSoundPath(
        keyValues.message or ""
    )

    local expected = NormalizeSoundPath(
        track.legacyMessage or track.path
    )

    return actual == expected
end

function Lobby:AddZone(position, radius)
    if not isvector(position) then
        return
    end

    radius = math.max(
        tonumber(radius) or 896,
        1
    )

    radius = radius
        * math.max(Config.LegacyZoneRadiusMultiplier, 0.01)

    for _, zone in ipairs(self.Zones) do
        if zone.position:DistToSqr(position) < 1 then
            return
        end
    end

    self.Zones[#self.Zones + 1] = {
        position = Vector(
            position.x,
            position.y,
            position.z
        ),

        radius = radius
    }
end

function Lobby:CaptureLegacyAmbient(ent)
    if not Config.EnableLegacyAmbientAdapter then
        return
    end

    if not self:IsLegacyAmbient(ent) then
        return
    end

    if ent.SRMusicLegacyCaptured then
        return
    end

    ent.SRMusicLegacyCaptured = true

    local keyValues = ent:GetKeyValues() or {}

    self:AddZone(
        ent:GetPos(),
        tonumber(keyValues.radius) or 896
    )

    -- Это адресный input конкретной entity,
    -- а не глобальная консольная команда stopsound.
    ent:Fire("StopSound", "", 0)

    timer.Simple(0, function()
        if IsValid(ent) then
            ent:Remove()
        end
    end)

    hook.Run(
        "SR.LegacyLobbyAmbientCaptured",
        ent:GetPos(),
        tonumber(keyValues.radius) or 896
    )
end

function Lobby:ScanLegacyAmbientEntities()
    for _, ent in ipairs(
        ents.FindByClass("ambient_generic")
    ) do
        self:CaptureLegacyAmbient(ent)
    end
end

function Lobby:IsPlayerInFallbackLobby(ply)
    if not IsValid(ply) then
        return false
    end

    if Config.AutoStartOnLobbyMaps
        and self:IsDedicatedLobbyMap() then
        return true
    end

    if not Config.EnableLegacyRadiusDetection then
        return false
    end

    local playerPosition = ply:GetPos()

    for _, zone in ipairs(self.Zones) do
        local radiusSquared = zone.radius * zone.radius

        if playerPosition:DistToSqr(zone.position)
            <= radiusSquared then
            return true
        end
    end

    return false
end

function Lobby:UpdateFallbackPlayer(ply)
    if not IsValid(ply) then
        return
    end

    if self.Managed[ply] then
        return
    end

    self:SetPlayerInside(
        ply,
        self:IsPlayerInFallbackLobby(ply),
        "fallback"
    )
end

hook.Add(
    "SR.PlayerContextChanged",
    "SR.Music.LobbyContext",
    function(ply, oldContext, newContext)
        if newContext ~= "lobby"
            and oldContext ~= "lobby" then
            return
        end

        Lobby.Managed[ply] = true

        Lobby:SetPlayerInside(
            ply,
            newContext == "lobby",
            "gamemode_context"
        )
    end
)

hook.Add(
    "SR.PlayerEnteredLobby",
    "SR.Music.LobbyEnter",
    function(ply)
        Lobby.Managed[ply] = true
        Lobby:SetPlayerInside(ply, true, "gamemode_event")
    end
)

hook.Add(
    "SR.PlayerLeftLobby",
    "SR.Music.LobbyLeave",
    function(ply)
        Lobby.Managed[ply] = true
        Lobby:SetPlayerInside(ply, false, "gamemode_event")
    end
)

hook.Add(
    "InitPostEntity",
    "SR.Music.LobbyCaptureAmbient",
    function()
        timer.Simple(0.25, function()
            Lobby:ScanLegacyAmbientEntities()
        end)
    end
)

hook.Add(
    "OnEntityCreated",
    "SR.Music.LobbyCheckCreatedAmbient",
    function(ent)
        timer.Simple(0, function()
            if IsValid(ent) then
                Lobby:CaptureLegacyAmbient(ent)
            end
        end)
    end
)

hook.Add(
    "PostCleanupMap",
    "SR.Music.LobbyMapCleanup",
    function()
        Lobby.Zones = {}

        timer.Simple(0.25, function()
            Lobby:ScanLegacyAmbientEntities()
        end)
    end
)

hook.Add(
    "PlayerInitialSpawn",
    "SR.Music.LobbyInitialPlayer",
    function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                Lobby:UpdateFallbackPlayer(ply)
            end
        end)
    end
)

hook.Add(
    "PlayerDisconnected",
    "SR.Music.LobbyPlayerCleanup",
    function(ply)
        Lobby.Inside[ply] = nil
        Lobby.Managed[ply] = nil
    end
)

timer.Create(
    "SR.Music.LobbyFallbackDetection",
    math.max(Config.LobbyCheckInterval, 0.1),
    0,
    function()
        for _, ply in ipairs(player.GetAll()) do
            Lobby:UpdateFallbackPlayer(ply)
        end
    end
)

concommand.Add(
    "sr_music_lobby_rescan",
    function(ply)
        if IsValid(ply) and not ply:IsAdmin() then
            return
        end

        Lobby:ScanLegacyAmbientEntities()

        for _, target in ipairs(player.GetAll()) do
            Lobby:UpdateFallbackPlayer(target)
        end
    end
)