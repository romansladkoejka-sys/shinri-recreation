if not SERVER then
    return
end

SR = SR or {}
SR.Session = SR.Session or {}

local Adapter = SR.Session.CharacterAdapter or {}
SR.Session.CharacterAdapter = Adapter

Adapter.CharacterNWKeys = {
    "SelectedCharacter",
    "ShinriCharacter",
    "ShinriCharacterID",
    "ShinriCharacterName",
    "SR.CharacterID"
}

Adapter.CharacterFields = {
    "CharacterKey",
    "SelectedCharacter",
    "ShinriCharacter",
    "ShinriCharacterID",
    "SRCharacterID"
}

Adapter.ReadyNWKeys = {
    "ReadyState",
    "ShinriReady",
    "SR.ReadyState"
}

Adapter.ReadyFields = {
    "ReadyState",
    "ShinriReady",
    "SRReadyState"
}

local function IsNonEmptyValue(value)
    if value == nil then
        return false
    end

    return tostring(value) ~= ""
end

function Adapter:GetCharacter(ply)
    if not IsValid(ply) then
        return ""
    end

    local hookValue =
        hook.Run(
            "SR.SessionCaptureCharacter",
            ply
        )

    if IsNonEmptyValue(hookValue) then
        return tostring(hookValue)
    end

    for _, key in ipairs(self.CharacterNWKeys) do
        local value = ply:GetNW2String(key, "")

        if not IsNonEmptyValue(value) then
            value = ply:GetNWString(key, "")
        end

        if IsNonEmptyValue(value) then
            return tostring(value)
        end
    end

    for _, field in ipairs(self.CharacterFields) do
        local value = ply[field]

        if IsNonEmptyValue(value) then
            return tostring(value)
        end
    end

    return ""
end

function Adapter:RestoreCharacter(ply, characterID)
    if not IsValid(ply) then
        return false
    end

    characterID = tostring(characterID or "")

    local handled =
        hook.Run(
            "SR.SessionRestoreCharacter",
            ply,
            characterID
        )

    if handled == true then
        return true
    end

    for _, key in ipairs(self.CharacterNWKeys) do
        ply:SetNWString(key, characterID)
        ply:SetNW2String(key, characterID)
    end

    for _, field in ipairs(self.CharacterFields) do
        ply[field] = characterID
    end

    ply.SRRestoredCharacter = characterID

    hook.Run(
        "SR.SessionCharacterRestored",
        ply,
        characterID
    )

    return true
end

function Adapter:GetReadyState(ply)
    if not IsValid(ply) then
        return false
    end

    local hookValue =
        hook.Run(
            "SR.SessionCaptureReadyState",
            ply
        )

    if isbool(hookValue) then
        return hookValue
    end

    for _, field in ipairs(self.ReadyFields) do
        if isbool(ply[field]) then
            return ply[field]
        end
    end

    for _, key in ipairs(self.ReadyNWKeys) do
        if ply:GetNW2Bool(key, false) then
            return true
        end

        if ply:GetNWBool(key, false) then
            return true
        end
    end

    return false
end

function Adapter:RestoreReadyState(ply, readyState)
    if not IsValid(ply) then
        return false
    end

    readyState = readyState == true

    local handled =
        hook.Run(
            "SR.SessionRestoreReadyState",
            ply,
            readyState
        )

    if handled == true then
        return true
    end

    for _, key in ipairs(self.ReadyNWKeys) do
        ply:SetNWBool(key, readyState)
        ply:SetNW2Bool(key, readyState)
    end

    for _, field in ipairs(self.ReadyFields) do
        ply[field] = readyState
    end

    return true
end