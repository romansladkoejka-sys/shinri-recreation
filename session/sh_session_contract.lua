SR = SR or {}
SR.Session = SR.Session or {}

local Session = SR.Session

Session.Version = 1

Session.Phase = Session.Phase or {
    LOBBY = "LOBBY",
    STARTING = "STARTING",
    LOADING = "LOADING",
    EXPLORATION = "EXPLORATION",
    ENDING = "ENDING",
    FAILED = "FAILED"
}

Session.ValidPhases = Session.ValidPhases or {}

for _, phase in pairs(Session.Phase) do
    Session.ValidPhases[phase] = true
end

Session.Config = Session.Config or {}

local Config = Session.Config

Config.HandoffDirectory =
    Config.HandoffDirectory
    or "shinri_recreation"

Config.HandoffFile =
    Config.HandoffFile
    or "shinri_recreation/session_handoff.json"

Config.HandoffTTL =
    tonumber(Config.HandoffTTL)
    or 600

Config.LoadingTimeout =
    tonumber(Config.LoadingTimeout)
    or 20

Config.RestoreRetryInterval =
    tonumber(Config.RestoreRetryInterval)
    or 0.5

Config.RestoreRetryCount =
    tonumber(Config.RestoreRetryCount)
    or 30

Config.QuickGameMapID =
    Config.QuickGameMapID
    or "ACADEMY"

Config.QuickGameType =
    Config.QuickGameType
    or "QUICK_GAME"

function Session.IsValidPhase(phase)
    return Session.ValidPhases[phase] == true
end