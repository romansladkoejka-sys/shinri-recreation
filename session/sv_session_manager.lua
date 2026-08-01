if not SERVER then
    return
end

SR = SR or {}
SR.Session = SR.Session or {}

local Session = SR.Session
local Phase = Session.Phase
local Config = Session.Config
local Registry = SR.MapRegistry
local CharacterAdapter = Session.CharacterAdapter

local Manager = Session.Manager or {}
Session.Manager = Manager

Manager.State = Manager.State or nil
Manager.Roster = Manager.Roster or {}
Manager.RosterBySteamID64 =
    Manager.RosterBySteamID64
    or {}

Manager.TransitionLocked = false
Manager.DefaultPhase = Phase.EXPLORATION
Manager.LoadedFromHandoff = false

local function CopyVectorSafe(value)
    if not isvector(value) then
        return nil
    end

    return {
        x = value.x,
        y = value.y,
        z = value.z
    }
end

function Manager:GetPlayerKey(ply)
    if not IsValid(ply) then
        return ""
    end

    local steamID64 = ply:SteamID64()

    if isstring(steamID64)
        and steamID64 ~= ""
        and steamID64 ~= "0" then
        return steamID64
    end

    return "BOT:" .. tostring(ply:UserID())
end

function Manager:CreateSessionID()
    local entropy = table.concat({
        tostring(os.time()),
        tostring(SysTime()),
        tostring(math.random()),
        tostring(game.GetIPAddress()),
        tostring(game.GetMap())
    }, ":")

    return string.format(
        "QG-%d-%s",
        os.time(),
        string.sub(util.CRC(entropy), 1, 10)
    )
end

function Manager:GetState()
    return self.State
end

function Manager:GetPhase()
    if not self.State then
        return nil
    end

    return self.State.Phase
end

function Manager:GetRosterRecord(ply)
    local key = self:GetPlayerKey(ply)

    if key == "" then
        return nil
    end

    return self.RosterBySteamID64[key]
end

function Manager:GetContextForPhase(phase)
    if phase == Phase.LOBBY then
        return "lobby"
    end

    if phase == Phase.STARTING then
        return "starting"
    end

    if phase == Phase.LOADING then
        return "loading"
    end

    if phase == Phase.EXPLORATION then
        return "exploration"
    end

    if phase == Phase.ENDING then
        return "ending"
    end

    return "failed"
end

function Manager:ApplyPlayerContext(ply)
    if not IsValid(ply) or not self.State then
        return
    end

    local newContext =
        self:GetContextForPhase(
            self.State.Phase
        )

    local oldContext = ply.SRContext

    if not oldContext
        and newContext ~= "lobby" then
        oldContext = "lobby"
    end

    ply.SRContext = newContext

    ply:SetNW2String(
        "SR.SessionPhase",
        self.State.Phase or ""
    )

    ply:SetNW2String(
        "SR.SessionContext",
        newContext
    )

    if oldContext ~= newContext then
        hook.Run(
            "SR.PlayerContextChanged",
            ply,
            oldContext,
            newContext
        )
    end
end

function Manager:SetPhase(newPhase, reason)
    if not Session.IsValidPhase(newPhase) then
        return false, "invalid_phase"
    end

    if not self.State then
        return false, "missing_session"
    end

    local previousPhase = self.State.Phase

    if previousPhase == newPhase then
        return true
    end

    self.State.Phase = newPhase
    self.State.UpdatedAt = os.time()
    self.State.FailureReason =
        newPhase == Phase.FAILED
        and tostring(reason or "unknown")
        or nil

    for _, ply in ipairs(player.GetAll()) do
        self:ApplyPlayerContext(ply)
    end

    hook.Run(
        "SR.SessionPhaseChanged",
        previousPhase,
        newPhase,
        self.State,
        reason
    )

    if newPhase == Phase.EXPLORATION then
        hook.Run(
            "SR.ExplorationStarted",
            self.State
        )
    end

    if newPhase == Phase.FAILED then
        hook.Run(
            "SR.SessionFailed",
            self.State,
            reason
        )
    end

    return true
end

function Manager:CreateLobbySession()
    self.Roster = {}
    self.RosterBySteamID64 = {}
    self.DefaultPhase = Phase.EXPLORATION
    self.TransitionLocked = false
    self.LoadedFromHandoff = false

    self.State = {
        Type = "LOBBY",
        Phase = Phase.LOBBY,
        MapID = "",
        BSP = game.GetMap(),
        Provider = "CURRENT",
        SessionID = "LOBBY-" .. game.GetMap(),
        Players = {},
        CreatedAt = os.time(),
        UpdatedAt = os.time()
    }

    hook.Run(
        "SR.SessionCreated",
        self.State
    )

    return self.State
end

function Manager:CreateQuickGameSession(mapID, mapDefinition)
    self.Roster = {}
    self.RosterBySteamID64 = {}
    self.DefaultPhase =
        mapDefinition.DefaultPhase
        or Phase.EXPLORATION

    self.State = {
        Type = Config.QuickGameType,
        Phase = Phase.STARTING,
        MapID = mapID,
        BSP = mapDefinition.BSP,
        Provider = mapDefinition.Provider,
        SessionID = self:CreateSessionID(),
        Players = {},
        CreatedAt = os.time(),
        UpdatedAt = os.time()
    }

    hook.Run(
        "SR.SessionCreated",
        self.State
    )

    return self.State
end

function Manager:CaptureCurrentPlayers()
    if not self.State then
        return false, "missing_session"
    end

    local players = table.Copy(
        player.GetHumans()
    )

    table.sort(players, function(first, second)
        local firstKey = self:GetPlayerKey(first)
        local secondKey = self:GetPlayerKey(second)

        if firstKey == secondKey then
            return first:UserID() < second:UserID()
        end

        return firstKey < secondKey
    end)

    self.Roster = {}
    self.RosterBySteamID64 = {}
    self.State.Players = {}

    for index, ply in ipairs(players) do
        local steamID64 = self:GetPlayerKey(ply)

        local record = {
            SteamID64 = steamID64,
            Character =
                CharacterAdapter:GetCharacter(ply),

            PlayerName = ply:Nick(),
            SessionID = self.State.SessionID,

            ReadyState =
                CharacterAdapter:GetReadyState(ply),

            JoinOrder = index,
            Restored = false,
            CapturedAt = os.time(),
            CapturePosition =
                CopyVectorSafe(ply:GetPos())
        }

        self.Roster[#self.Roster + 1] = record
        self.RosterBySteamID64[steamID64] = record
        self.State.Players[#self.State.Players + 1] =
            steamID64

        ply.SRSessionID = self.State.SessionID
        ply:SetNW2String(
            "SR.SessionID",
            self.State.SessionID
        )
    end

    hook.Run(
        "SR.SessionPlayersCaptured",
        self.State,
        self.Roster
    )

    return true
end

function Manager:BuildHandoffPayload()
    return {
        Version = Session.Version,
        CreatedAt = os.time(),

        TargetMapID = self.State.MapID,
        TargetBSP = self.State.BSP,
        DefaultPhase = self.DefaultPhase,

        Session = self.State,
        Players = self.Roster
    }
end

function Manager:SaveHandoff()
    if not self.State then
        return false, "missing_session"
    end

    file.CreateDir(
        Config.HandoffDirectory
    )

    local payload = self:BuildHandoffPayload()
    local encoded = util.TableToJSON(payload, true)

    if not encoded then
        return false, "json_encode_failed"
    end

    file.Write(
        Config.HandoffFile,
        encoded
    )

    if not file.Exists(
        Config.HandoffFile,
        "DATA"
    ) then
        return false, "handoff_write_failed"
    end

    hook.Run(
        "SR.SessionHandoffSaved",
        payload
    )

    return true
end

function Manager:DeleteHandoff()
    if file.Exists(
        Config.HandoffFile,
        "DATA"
    ) then
        file.Delete(Config.HandoffFile)
    end
end

function Manager:IndexImportedRoster(records)
    self.Roster = {}
    self.RosterBySteamID64 = {}

    for index, record in ipairs(records or {}) do
        record.SteamID64 =
            tostring(record.SteamID64 or "")

        record.Character =
            tostring(record.Character or "")

        record.PlayerName =
            tostring(record.PlayerName or "")

        record.SessionID =
            tostring(
                record.SessionID
                or self.State.SessionID
                or ""
            )

        record.ReadyState =
            record.ReadyState == true

        record.JoinOrder =
            tonumber(record.JoinOrder)
            or index

        record.Restored = false

        if record.SteamID64 ~= "" then
            self.Roster[#self.Roster + 1] =
                record

            self.RosterBySteamID64[
                record.SteamID64
            ] = record
        end
    end

    table.sort(self.Roster, function(first, second)
        if first.JoinOrder == second.JoinOrder then
            return first.SteamID64 < second.SteamID64
        end

        return first.JoinOrder < second.JoinOrder
    end)
end

function Manager:LoadHandoff()
    if not file.Exists(
        Config.HandoffFile,
        "DATA"
    ) then
        return false, "not_found"
    end

    local raw = file.Read(
        Config.HandoffFile,
        "DATA"
    )

    if not isstring(raw) or raw == "" then
        self:DeleteHandoff()
        return false, "empty_handoff"
    end

    local payload = util.JSONToTable(raw)

    if not istable(payload)
        or not istable(payload.Session) then
        self:DeleteHandoff()
        return false, "invalid_json"
    end

    local createdAt =
        tonumber(payload.CreatedAt)
        or 0

    if createdAt <= 0
        or os.time() - createdAt
            > Config.HandoffTTL then
        self:DeleteHandoff()
        return false, "expired"
    end

    local targetBSP =
        string.lower(
            tostring(payload.TargetBSP or "")
        )

    if targetBSP == ""
        or targetBSP
            ~= string.lower(game.GetMap()) then
        self:DeleteHandoff()
        return false, "wrong_map"
    end

    local mapDefinition =
        Registry.Get(
            payload.TargetMapID
                or payload.Session.MapID
        )

    if not mapDefinition then
        self:DeleteHandoff()
        return false, "unknown_map_id"
    end

    if mapDefinition.BSP ~= targetBSP then
        self:DeleteHandoff()
        return false, "registry_mismatch"
    end

    self.State = payload.Session

    self.State.Type =
        self.State.Type
        or Config.QuickGameType

    self.State.MapID =
        mapDefinition.ID

    self.State.BSP =
        mapDefinition.BSP

    self.State.Provider =
        mapDefinition.Provider

    self.State.Phase =
        Phase.LOADING

    self.State.UpdatedAt =
        os.time()

    self.DefaultPhase =
        payload.DefaultPhase
        or mapDefinition.DefaultPhase
        or Phase.EXPLORATION

    self.TransitionLocked = false
    self.LoadedFromHandoff = true

    self:IndexImportedRoster(
        payload.Players
    )

    self:DeleteHandoff()

    timer.Remove(
        "SR.Session.LoadingTimeout"
    )

    timer.Create(
        "SR.Session.LoadingTimeout",
        Config.LoadingTimeout,
        1,
        function()
            if Manager:GetPhase()
                ~= Phase.LOADING then
                return
            end

            Manager:SetPhase(
                Manager.DefaultPhase,
                "restore_timeout"
            )
        end
    )

    hook.Run(
        "SR.SessionHandoffLoaded",
        self.State,
        self.Roster
    )

    if #self.Roster == 0 then
        timer.Simple(0, function()
            if Manager:GetPhase()
                == Phase.LOADING then
                Manager:SetPhase(
                    Manager.DefaultPhase,
                    "empty_roster"
                )
            end
        end)
    end

    return true
end

function Manager:ApplyMembership(ply, record)
    if not IsValid(ply)
        or not record
        or not self.State then
        return false
    end

    ply.SRSessionID =
        self.State.SessionID

    ply.SRSessionMember = true

    ply:SetNW2String(
        "SR.SessionID",
        self.State.SessionID or ""
    )

    ply:SetNW2String(
        "SR.SessionType",
        self.State.Type or ""
    )

    ply:SetNW2String(
        "SR.SessionMapID",
        self.State.MapID or ""
    )

    CharacterAdapter:RestoreCharacter(
        ply,
        record.Character
    )

    CharacterAdapter:RestoreReadyState(
        ply,
        record.ReadyState
    )

    self:ApplyPlayerContext(ply)

    return true
end

function Manager:RestorePlayer(ply)
    if not IsValid(ply)
        or not self.State then
        return false, "invalid_player"
    end

    local record =
        self:GetRosterRecord(ply)

    if not record then
        return false, "not_session_member"
    end

    self:ApplyMembership(ply, record)

    if record.Restored == true then
        return true
    end

    record.Restored = true
    record.RestoredAt = os.time()
    record.RestoredName = ply:Nick()

    hook.Run(
        "SR.SessionPlayerRestored",
        ply,
        record,
        self.State
    )

    if not ply.SRSessionRestoreRespawnScheduled then
        ply.SRSessionRestoreRespawnScheduled = true

        timer.Simple(0, function()
            if not IsValid(ply) then
                return
            end

            if ply.SRSessionRestoreRespawned then
                return
            end

            ply.SRSessionRestoreRespawned = true
            ply:Spawn()
        end)
    end

    self:MaybeCompleteLoading()

    return true
end

function Manager:GetRestoreCounts()
    local restored = 0
    local expected = #self.Roster

    for _, record in ipairs(self.Roster) do
        if record.Restored == true then
            restored = restored + 1
        end
    end

    return restored, expected
end

function Manager:MaybeCompleteLoading()
    if self:GetPhase() ~= Phase.LOADING then
        return false
    end

    local restored, expected =
        self:GetRestoreCounts()

    if expected > 0
        and restored < expected then
        return false
    end

    timer.Remove(
        "SR.Session.LoadingTimeout"
    )

    self:SetPhase(
        self.DefaultPhase,
        "all_players_restored"
    )

    return true
end

function Manager:IsGameplayMapActive()
    if not self.State then
        return false
    end

    local phase = self.State.Phase

    if phase ~= Phase.LOADING
        and phase ~= Phase.EXPLORATION then
        return false
    end

    local mapDefinition =
        Registry.Get(self.State.MapID)

    if not mapDefinition then
        return false
    end

    return mapDefinition.BSP
        == string.lower(game.GetMap())
end

function Manager:ScheduleRestore(ply)
    if not IsValid(ply) then
        return
    end

    local timerName =
        "SR.Session.Restore."
        .. tostring(ply:UserID())

    timer.Remove(timerName)

    timer.Create(
        timerName,
        Config.RestoreRetryInterval,
        Config.RestoreRetryCount,
        function()
            if not IsValid(ply) then
                timer.Remove(timerName)
                return
            end

            if Manager:GetPhase()
                == Phase.LOBBY then
                Manager:ApplyPlayerContext(ply)
                timer.Remove(timerName)
                return
            end

            local restored =
                Manager:RestorePlayer(ply)

            if restored then
                timer.Remove(timerName)
            end
        end
    )
end

function Manager:Bootstrap()
    local loaded =
        self:LoadHandoff()

    if not loaded then
        self:CreateLobbySession()
    end

    hook.Run(
        "SR.SessionManagerReady",
        self.State
    )
end

hook.Add(
    "PlayerInitialSpawn",
    "SR.Session.InitialSpawn",
    function(ply)
        Manager:ScheduleRestore(ply)
    end
)

hook.Add(
    "PlayerAuthed",
    "SR.Session.PlayerAuthed",
    function(ply)
        Manager:ScheduleRestore(ply)
    end
)

hook.Add(
    "PlayerSpawn",
    "SR.Session.PlayerSpawn",
    function(ply)
        if Manager:GetPhase()
            == Phase.LOBBY then
            Manager:ApplyPlayerContext(ply)
            return
        end

        timer.Simple(0, function()
            if IsValid(ply) then
                Manager:RestorePlayer(ply)
            end
        end)
    end
)

hook.Add(
    "PlayerDisconnected",
    "SR.Session.PlayerDisconnected",
    function(ply)
        timer.Remove(
            "SR.Session.Restore."
            .. tostring(ply:UserID())
        )
    end
)

Manager:Bootstrap()