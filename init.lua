AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_chat.lua")
AddCSLuaFile("cl_characters.lua")
AddCSLuaFile("cl_escape_menu.lua")

include("shared.lua")
include("sv_characters.lua")

util.AddNetworkString("ShinriChat_Send")
util.AddNetworkString("ShinriChat_Receive")

local CHAT_DISTANCE = 600

local function SendToPlayer(receiver, ply, msgType, text)
    net.Start("ShinriChat_Receive")
        net.WriteEntity(ply)
        net.WriteString(ShinriGetCharacterName(ply))
        net.WriteString(msgType)
        net.WriteString(text)
    net.Send(receiver)
end

local function SendLocal(ply, msgType, text)
    local origin = ply:GetPos()
    local maxDistSqr = CHAT_DISTANCE * CHAT_DISTANCE

    for _, receiver in ipairs(player.GetAll()) do
        if IsValid(receiver) and receiver:GetPos():DistToSqr(origin) <= maxDistSqr then
            SendToPlayer(receiver, ply, msgType, text)
        end
    end
end

local function SendGlobal(ply, msgType, text)
    net.Start("ShinriChat_Receive")
        net.WriteEntity(ply)
        net.WriteString(ShinriGetCharacterName(ply))
        net.WriteString(msgType)
        net.WriteString(text)
    net.Broadcast()
end

net.Receive("ShinriChat_Send", function(len, ply)
    local text = string.Trim(net.ReadString())

    if text == "" then return end

    if #text > 500 then
        text = string.sub(text, 1, 500)
    end

    local lower = string.lower(text)

    -- Р“Р»РѕР±Р°Р»СЊРЅС‹Р№ OOC: // СЃРѕРѕР±С‰РµРЅРёРµ
    if string.StartWith(text, "//") then
        local message = string.Trim(string.sub(text, 3))

        if message == "" then return end

        SendGlobal(ply, "ooc", message)

        print("[OOC] " .. ply:Nick() .. ": " .. message)
        return
    end

    -- /me
    if string.StartWith(lower, "/me ") then
        local action = string.Trim(string.sub(text, 5))

        if action == "" then return end

        SendLocal(ply, "me", action)

        print("[RP /me] " .. ply:Nick() .. " " .. action)
        return
    end

    -- /do
    if string.StartWith(lower, "/do ") then
        local action = string.Trim(string.sub(text, 5))

        if action == "" then return end

        SendLocal(ply, "do", action)

        print("[RP /do] " .. ply:Nick() .. ": " .. action)
        return
    end

    -- /roll
    if lower == "/roll" then
        local result = math.random(1, 100)

        SendLocal(ply, "roll", tostring(result))

        print("[RP /roll] " .. ply:Nick() .. " rolled " .. result)
        return
    end

    -- РћР±С‹С‡РЅС‹Р№ Р»РѕРєР°Р»СЊРЅС‹Р№ IC С‡Р°С‚
    SendLocal(ply, "normal", text)

    print("[IC] " .. ShinriGetCharacterName(ply) .. ": " .. text)
end)

function GM:PlayerInitialSpawn(ply)
    print("[Shinri Recreation] Player connected: " .. ply:Nick())
end

function GM:PlayerSpawn(ply)
    self.BaseClass.PlayerSpawn(self, ply)

    ply:SetWalkSpeed(160)
    ply:SetRunSpeed(240)
end




AddCSLuaFile("ui/shui.lua")
AddCSLuaFile("ui/shui_colors.lua")
AddCSLuaFile("ui/shui_fonts.lua")
AddCSLuaFile("ui/shui_materials.lua")

resource.AddFile("materials/shinri_ui/logo.png")

AddCSLuaFile("ui/inventory/cl_inventory.lua")

local function AddResourceDirectory(path)
    local files, directories = file.Find(path .. "/*", "GAME")

    for _, fileName in ipairs(files or {}) do
        resource.AddFile(path .. "/" .. fileName)
    end

    for _, directoryName in ipairs(directories or {}) do
        AddResourceDirectory(path .. "/" .. directoryName)
    end
end

AddResourceDirectory("materials/dro/sprites/inventory")

