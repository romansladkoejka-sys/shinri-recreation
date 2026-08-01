util.AddNetworkString("ShinriCharacter_Open")
util.AddNetworkString("ShinriCharacter_Select")

local Characters = {
    ibuki = {
        name = "Ибуки Миода",
        model = "models/player/dewobedil/danganronpa/ibuki_mioda/default_p.mdl"
    },

    nagito = {
        name = "Нагито Комаэда",
        model = "models/dro/player/characters2/char2/nagito_suit.mdl"
    },

    komaru = {
        name = "Комару Наэги",
        model = "models/player/someguy/komaru_p.mdl"
    },

    nagisa = {
        name = "Нагиса Шингецу",
        model = "models/dro/player/characters4/nagisa_scots/nagisa_scots.mdl"
    }
}

function ShinriGetCharacterName(ply)

    if not IsValid(ply) then
        return "Unknown"
    end

    local name = ply:GetNWString("ShinriCharacterName", "")

    if name == "" then
        return ply:Nick()
    end

    return name
end


hook.Add("PlayerInitialSpawn", "ShinriCharacter_InitialSpawn", function(ply)

    timer.Simple(2, function()

        if not IsValid(ply) then return end

        net.Start("ShinriCharacter_Open")
        net.Send(ply)

    end)

end)


net.Receive("ShinriCharacter_Select", function(len, ply)

    local id = net.ReadString()

    local character = Characters[id]

    if not character then return end

    ply:SetNWString(
        "ShinriCharacterID",
        id
    )

    ply:SetNWString(
        "ShinriCharacterName",
        character.name
    )

    if character.model then
        ply:SetModel(character.model)

        if id == "nagito" then
            ply:SetViewOffsetDucked(Vector(0, 0, 42))
        elseif id == "nagisa" then
            ply:SetViewOffset(Vector(0, 0, 48))
            ply:SetViewOffsetDucked(Vector(0, 0, 32))
        elseif id == "komaru" then
            ply:SetViewOffset(Vector(0, 0, 58))
            ply:SetViewOffsetDucked(Vector(0, 0, 32))
        elseif id == "ibuki" then
            ply:SetViewOffset(Vector(0, 0, 60))
            ply:SetViewOffsetDucked(Vector(0, 0, 36))
        end
    end

    print(
        "[Character] "
        .. ply:Nick()
        .. " selected "
        .. character.name
    )

end)


hook.Add("PlayerSpawn", "ShinriCharacter_ApplyModel", function(ply)

    timer.Simple(0, function()

        if not IsValid(ply) then return end

        local id = ply:GetNWString("ShinriCharacterID", "")
        local character = Characters[id]

        if character and character.model then
            ply:SetModel(character.model)

        if id == "nagito" then
            ply:SetViewOffsetDucked(Vector(0, 0, 42))
        elseif id == "nagisa" then
            ply:SetViewOffset(Vector(0, 0, 48))
            ply:SetViewOffsetDucked(Vector(0, 0, 32))
        elseif id == "komaru" then
            ply:SetViewOffset(Vector(0, 0, 58))
            ply:SetViewOffsetDucked(Vector(0, 0, 32))
        elseif id == "ibuki" then
            ply:SetViewOffset(Vector(0, 0, 60))
            ply:SetViewOffsetDucked(Vector(0, 0, 36))
        end
        end

    end)

end)









