SR = SR or {}
SR.Music = SR.Music or {}

local Music = SR.Music

Music.Protocol = 1

Music.Net = Music.Net or {
    Ready = "SR.Music.Ready",
    State = "SR.Music.State"
}

Music.Config = Music.Config or {}

local Config = Music.Config

Config.LobbyCue = Config.LobbyCue or "lobby.default"
Config.LobbyOwner = Config.LobbyOwner or "lobby"
Config.LobbyPriority = Config.LobbyPriority or 10

Config.DefaultFadeIn = Config.DefaultFadeIn or 1.25
Config.DefaultFadeOut = Config.DefaultFadeOut or 0.75

if Config.AutoStartOnLobbyMaps == nil then
    Config.AutoStartOnLobbyMaps = false
end

if Config.EnableLegacyAmbientAdapter == nil then
    Config.EnableLegacyAmbientAdapter = true
end

if Config.EnableLegacyRadiusDetection == nil then
    Config.EnableLegacyRadiusDetection = true
end

Config.LobbyCheckInterval = tonumber(Config.LobbyCheckInterval) or 0.5
Config.LegacyZoneRadiusMultiplier = tonumber(Config.LegacyZoneRadiusMultiplier) or 1

Config.LobbyMaps = {
    ["dro_lobby"] = true
}

Config.LobbyMaps = {
    ["dro_lobby"] = true
}

Music.Tracks = Music.Tracks or {}
Music.Backends = Music.Backends or {}

function Music.RegisterTrack(id, definition)
    assert(isstring(id) and id ~= "", "Music track ID must be a non-empty string")
    assert(istable(definition), "Music track definition must be a table")
    assert(isstring(definition.path) and definition.path ~= "", "Music track path is required")

    local track = {
        id = id,
        path = definition.path,
        backend = definition.backend or "file",
        loop = definition.loop ~= false,
        volume = math.Clamp(tonumber(definition.volume) or 1, 0, 1),
        legacyMessage = definition.legacyMessage
    }

    Music.Tracks[id] = track

    return track
end

function Music.GetTrack(id)
    return Music.Tracks[id]
end

function Music.TrackExists(id)
    return Music.Tracks[id] ~= nil
end

function Music.RegisterBackend(id, backend)
    assert(isstring(id) and id ~= "", "Music backend ID must be a non-empty string")
    assert(istable(backend), "Music backend must be a table")
    assert(isfunction(backend.Load), "Music backend must implement Load")

    Music.Backends[id] = backend

    return backend
end

function Music.GetBackend(id)
    return Music.Backends[id]
end

Music.RegisterTrack("lobby.default", {
    path = "sound/dro/music/dromix.wav",
    legacyMessage = "dro/music/dromix.wav",
    backend = "file",
    loop = true,
    volume = 1
})