if not SERVER then
    return
end

SR = SR or {}
SR.Music = SR.Music or {}

local Music = SR.Music
local Config = Music.Config

util.AddNetworkString(Music.Net.Ready)
util.AddNetworkString(Music.Net.State)

local Manager = Music.Manager or {}
Music.Manager = Manager

Manager.PlayerRecords = Manager.PlayerRecords or setmetatable({}, {
    __mode = "k"
})

Manager.ReadyPlayers = Manager.ReadyPlayers or setmetatable({}, {
    __mode = "k"
})

Manager.Sequence = Manager.Sequence or 0

local function CreateInactiveState(revision)
    return {
        active = false,
        revision = revision or 0,
        fadeOut = Config.DefaultFadeOut
    }
end

local function StatesEqual(first, second)
    if first.active ~= second.active then
        return false
    end

    if not first.active then
        return first.fadeOut == second.fadeOut
    end

    return first.cueID == second.cueID
        and first.startedAt == second.startedAt
        and first.sceneVolume == second.sceneVolume
        and first.loop == second.loop
        and first.fadeIn == second.fadeIn
        and first.fadeOut == second.fadeOut
end

function Manager:GetRecord(ply)
    local record = self.PlayerRecords[ply]

    if record then
        return record
    end

    record = {
        requests = {},
        current = CreateInactiveState(0)
    }

    self.PlayerRecords[ply] = record

    return record
end

function Manager:Resolve(record)
    local winner = nil

    for _, request in pairs(record.requests) do
        local isBetter = false

        if not winner then
            isBetter = true
        elseif request.priority > winner.priority then
            isBetter = true
        elseif request.priority == winner.priority
            and request.sequence > winner.sequence then
            isBetter = true
        end

        if isBetter then
            winner = request
        end
    end

    if not winner then
        return {
            active = false,
            fadeOut = Config.DefaultFadeOut
        }
    end

    return {
        active = true,
        owner = winner.owner,
        cueID = winner.cueID,
        startedAt = winner.startedAt,
        sceneVolume = winner.sceneVolume,
        loop = winner.loop,
        fadeIn = winner.fadeIn,
        fadeOut = winner.fadeOut
    }
end

function Manager:SendState(ply, state)
    if not IsValid(ply) then
        return
    end

    net.Start(Music.Net.State)

    net.WriteUInt(Music.Protocol, 8)
    net.WriteUInt(state.revision or 0, 32)

    net.WriteBool(state.active == true)
    net.WriteFloat(state.fadeOut or Config.DefaultFadeOut)

    if state.active then
        net.WriteString(state.cueID)

        local elapsed = math.max(
            0,
            CurTime() - (state.startedAt or CurTime())
        )

        net.WriteFloat(elapsed)
        net.WriteFloat(state.sceneVolume or 1)
        net.WriteBool(state.loop == true)
        net.WriteFloat(state.fadeIn or Config.DefaultFadeIn)
    end

    net.Send(ply)
end

function Manager:Publish(ply)
    if not IsValid(ply) then
        return
    end

    local record = self:GetRecord(ply)
    local nextState = self:Resolve(record)
    local previousState = record.current

    if StatesEqual(previousState, nextState) then
        return
    end

    nextState.revision = (previousState.revision or 0) + 1
    record.current = nextState

    if self.ReadyPlayers[ply] then
        self:SendState(ply, nextState)
    end

    hook.Run(
        "SR.MusicStateChanged",
        ply,
        previousState,
        nextState
    )
end

function Manager:Request(ply, owner, cueID, options)
    if not IsValid(ply) or not ply:IsPlayer() then
        return false, "invalid_player"
    end

    if not isstring(owner) or owner == "" then
        return false, "invalid_owner"
    end

    local track = Music.GetTrack(cueID)

    if not track then
        return false, "unknown_track"
    end

    options = options or {}

    local loop = options.loop

    if loop == nil then
        loop = track.loop
    end

    self.Sequence = self.Sequence + 1

    local record = self:GetRecord(ply)

    record.requests[owner] = {
        owner = owner,
        cueID = cueID,

        priority = math.floor(
            tonumber(options.priority) or 0
        ),

        sequence = self.Sequence,

        startedAt = tonumber(options.startedAt)
            or CurTime(),

        sceneVolume = math.Clamp(
            tonumber(options.volume)
                or track.volume
                or 1,
            0,
            1
        ),

        loop = loop == true,

        fadeIn = math.max(
            tonumber(options.fadeIn)
                or Config.DefaultFadeIn,
            0
        ),

        fadeOut = math.max(
            tonumber(options.fadeOut)
                or Config.DefaultFadeOut,
            0
        )
    }

    self:Publish(ply)

    return true
end

function Manager:Release(ply, owner)
    if not IsValid(ply) then
        return false
    end

    local record = self.PlayerRecords[ply]

    if not record or not record.requests[owner] then
        return false
    end

    record.requests[owner] = nil

    self:Publish(ply)

    return true
end

function Manager:ReleaseAll(ply)
    if not IsValid(ply) then
        return
    end

    local record = self:GetRecord(ply)

    record.requests = {}

    self:Publish(ply)
end

function Manager:GetEffectiveState(ply)
    local record = self.PlayerRecords[ply]

    if not record then
        return CreateInactiveState(0)
    end

    return record.current
end

net.Receive(Music.Net.Ready, function(_, ply)
    if not IsValid(ply) then
        return
    end

    local protocol = net.ReadUInt(8)

    if protocol ~= Music.Protocol then
        return
    end

    Manager.ReadyPlayers[ply] = true

    local record = Manager:GetRecord(ply)

    Manager:SendState(ply, record.current)
end)

hook.Add(
    "PlayerDisconnected",
    "SR.Music.ManagerCleanup",
    function(ply)
        Manager.PlayerRecords[ply] = nil
        Manager.ReadyPlayers[ply] = nil
    end
)