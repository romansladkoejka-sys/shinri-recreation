if not CLIENT then
    return
end

SR = SR or {}
SR.Music = SR.Music or {}

local Music = SR.Music
local Config = Music.Config

local volumeConVar = CreateClientConVar(
    "sr_music_volume",
    "1",
    true,
    false,
    "Shinri Recreation music volume",
    0,
    1
)

local FileBackend = {}

function FileBackend:Load(track, callback)
    sound.PlayFile(
        track.path,
        "noplay noblock",
        function(channel, errorCode, errorName)
            if not IsValid(channel) then
                callback(
                    nil,
                    errorCode,
                    errorName or "unknown_error"
                )

                return
            end

            callback(channel)
        end
    )
end

Music.RegisterBackend("file", FileBackend)

if Music.Controller
    and Music.Controller.StopImmediate then
    Music.Controller:StopImmediate("lua_reload")
end

local Controller = {
    Generation = 0,
    LastRevision = -1,

    Channel = nil,
    CurrentCue = nil,
    CurrentState = nil,

    SceneVolume = 1,
    FadeMultiplier = 0,
    Fade = nil,
    StopReason = nil
}

Music.Controller = Controller

function Controller:GetFinalVolume()
    return math.Clamp(
        self.SceneVolume
            * volumeConVar:GetFloat()
            * self.FadeMultiplier,
        0,
        1
    )
end

function Controller:DestroyCurrentChannel()
    local channel = self.Channel

    self.Channel = nil
    self.CurrentCue = nil
    self.CurrentState = nil
    self.Fade = nil
    self.FadeMultiplier = 0
    self.StopReason = nil

    if IsValid(channel) then
        channel:Stop()
    end
end

function Controller:StopImmediate(reason)
    self.Generation = self.Generation + 1

    local previousCue = self.CurrentCue

    self:DestroyCurrentChannel()

    if previousCue then
        hook.Run(
            "SR.MusicPlaybackStopped",
            previousCue,
            reason or "immediate"
        )
    end
end

function Controller:BeginFade(target, duration, stopAfter)
    target = math.Clamp(target, 0, 1)
    duration = math.max(tonumber(duration) or 0, 0)

    if duration <= 0 then
        self.FadeMultiplier = target
        self.Fade = nil

        if stopAfter then
            local previousCue = self.CurrentCue
            local stopReason = self.StopReason

            self:DestroyCurrentChannel()

            if previousCue then
                hook.Run(
                    "SR.MusicPlaybackStopped",
                    previousCue,
                    stopReason or "fade_complete"
                )
            end
        end

        return
    end

    self.Fade = {
        startedAt = RealTime(),
        duration = duration,
        from = self.FadeMultiplier,
        target = target,
        stopAfter = stopAfter == true
    }
end

function Controller:FadeOutCurrent(duration, reason)
    if not IsValid(self.Channel) then
        self:DestroyCurrentChannel()
        return
    end

    self.StopReason = reason or "state_stopped"

    self:BeginFade(
        0,
        duration or Config.DefaultFadeOut,
        true
    )
end

function Controller:GetDesiredTime(state, channel)
    local elapsed = math.max(
        tonumber(state.elapsed) or 0,
        0
    )

    local length = channel:GetLength()

    if length and length > 0 then
        if state.loop then
            elapsed = elapsed % length
        else
            elapsed = math.min(
                elapsed,
                math.max(length - 0.05, 0)
            )
        end
    end

    return elapsed
end

function Controller:ResyncCurrentChannel(state)
    if not IsValid(self.Channel) then
        return
    end

    local desired = self:GetDesiredTime(
        state,
        self.Channel
    )

    local current = self.Channel:GetTime()

    if math.abs(current - desired) >= 1.5 then
        self.Channel:SetTime(desired)
    end
end

function Controller:ApplyState(state)
    if state.revision <= self.LastRevision then
        return
    end

    self.LastRevision = state.revision
    self.Generation = self.Generation + 1

    local generation = self.Generation

    if not state.active then
        self:FadeOutCurrent(
            state.fadeOut,
            "server_state"
        )

        return
    end

    local track = Music.GetTrack(state.cueID)

    if not track then
        self:FadeOutCurrent(
            state.fadeOut,
            "unknown_track"
        )

        hook.Run(
            "SR.MusicPlaybackFailed",
            state.cueID,
            -1,
            "Track is not registered"
        )

        return
    end

    if self.CurrentCue == state.cueID
        and IsValid(self.Channel) then

        self.CurrentState = state
        self.SceneVolume = state.sceneVolume

        self.Channel:EnableLooping(state.loop)
        self:ResyncCurrentChannel(state)

        self.Fade = nil
        self.FadeMultiplier = 1

        return
    end

    local backend = Music.GetBackend(track.backend)

    if not backend then
        hook.Run(
            "SR.MusicPlaybackFailed",
            state.cueID,
            -2,
            "Unknown music backend"
        )

        return
    end

    backend:Load(
        track,
        function(channel, errorCode, errorName)
            if generation ~= self.Generation then
                if IsValid(channel) then
                    channel:Stop()
                end

                return
            end

            if not IsValid(channel) then
                hook.Run(
                    "SR.MusicPlaybackFailed",
                    state.cueID,
                    errorCode,
                    errorName
                )

                return
            end

            local previousCue = self.CurrentCue

            self:DestroyCurrentChannel()

            self.Channel = channel
            self.CurrentCue = state.cueID
            self.CurrentState = state
            self.SceneVolume = state.sceneVolume
            self.FadeMultiplier = 0

            channel:EnableLooping(state.loop)
            channel:SetVolume(0)

            local desiredTime = self:GetDesiredTime(
                state,
                channel
            )

            if desiredTime > 0 then
                channel:SetTime(desiredTime)
            end

            channel:Play()

            self:BeginFade(
                1,
                state.fadeIn,
                false
            )

            if previousCue then
                hook.Run(
                    "SR.MusicPlaybackStopped",
                    previousCue,
                    "replaced"
                )
            end

            hook.Run(
                "SR.MusicPlaybackStarted",
                state.cueID,
                channel
            )
        end
    )
end

hook.Add(
    "Think",
    "SR.Music.UpdateController",
    function()
        local fade = Controller.Fade

        if fade then
            local fraction = math.Clamp(
                (RealTime() - fade.startedAt)
                    / fade.duration,
                0,
                1
            )

            Controller.FadeMultiplier = Lerp(
                fraction,
                fade.from,
                fade.target
            )

            if fraction >= 1 then
                local stopAfter = fade.stopAfter
                local stopReason = Controller.StopReason
                local previousCue = Controller.CurrentCue

                Controller.Fade = nil
                Controller.FadeMultiplier = fade.target

                if stopAfter then
                    Controller:DestroyCurrentChannel()

                    if previousCue then
                        hook.Run(
                            "SR.MusicPlaybackStopped",
                            previousCue,
                            stopReason or "fade_complete"
                        )
                    end

                    return
                end
            end
        end

        if IsValid(Controller.Channel) then
            Controller.Channel:SetVolume(
                Controller:GetFinalVolume()
            )
        end
    end
)

net.Receive(
    Music.Net.State,
    function()
        local protocol = net.ReadUInt(8)
        local revision = net.ReadUInt(32)

        local active = net.ReadBool()
        local fadeOut = net.ReadFloat()

        if protocol ~= Music.Protocol then
            hook.Run(
                "SR.MusicProtocolMismatch",
                protocol,
                Music.Protocol
            )

            return
        end

        local state = {
            revision = revision,
            active = active,
            fadeOut = fadeOut
        }

        if active then
            state.cueID = net.ReadString()
            state.elapsed = net.ReadFloat()
            state.sceneVolume = net.ReadFloat()
            state.loop = net.ReadBool()
            state.fadeIn = net.ReadFloat()
        end

        Controller:ApplyState(state)
    end
)

local function SendReady()
    net.Start(Music.Net.Ready)
    net.WriteUInt(Music.Protocol, 8)
    net.SendToServer()
end

hook.Add(
    "InitPostEntity",
    "SR.Music.SendReady",
    function()
        SendReady()
    end
)

hook.Add(
    "OnReloaded",
    "SR.Music.HandleReload",
    function()
        Controller:StopImmediate("lua_reload")

        timer.Simple(0, function()
            if IsValid(LocalPlayer()) then
                SendReady()
            end
        end)
    end
)

hook.Add(
    "ShutDown",
    "SR.Music.StopOnMapChange",
    function()
        Controller:StopImmediate("map_change")
    end
)

concommand.Add(
    "sr_music_status",
    function()
        print("===== Shinri Music Status =====")
        print("Cue:", Controller.CurrentCue or "none")
        print("Channel valid:", IsValid(Controller.Channel))
        print("Scene volume:", Controller.SceneVolume)
        print("User volume:", volumeConVar:GetFloat())
        print("Fade:", Controller.FadeMultiplier)
        print("Revision:", Controller.LastRevision)
    end
)