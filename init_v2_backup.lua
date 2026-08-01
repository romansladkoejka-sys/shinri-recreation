AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_chat.lua")

include("shared.lua")

util.AddNetworkString("ShinriChat_Send")
util.AddNetworkString("ShinriChat_Receive")

local function SendChat(ply, msgType, text, extra)
    net.Start("ShinriChat_Receive")
        net.WriteEntity(ply)
        net.WriteString(msgType)
        net.WriteString(text)
        net.WriteString(extra or "")
    net.Broadcast()
end

net.Receive("ShinriChat_Send", function(len, ply)
    local text = string.Trim(net.ReadString())

    if text == "" then return end
    if #text > 500 then
        text = string.sub(text, 1, 500)
    end

    -- /me действие персонажа
    if string.StartWith(string.lower(text), "/me ") then
        local action = string.Trim(string.sub(text, 5))
        if action == "" then return end

        SendChat(ply, "me", action)
        print("[RP /me] " .. ply:Nick() .. " " .. action)
        return
    end

    -- /do описание ситуации
    if string.StartWith(string.lower(text), "/do ") then
        local action = string.Trim(string.sub(text, 5))
        if action == "" then return end

        SendChat(ply, "do", action)
        print("[RP /do] " .. ply:Nick() .. ": " .. action)
        return
    end

    -- /roll случайное число 1-100
    if string.lower(text) == "/roll" then
        local result = math.random(1, 100)

        SendChat(ply, "roll", tostring(result))
        print("[RP /roll] " .. ply:Nick() .. " rolled " .. result)
        return
    end

    -- Обычное сообщение
    SendChat(ply, "normal", text)
    print("[Shinri Chat] " .. ply:Nick() .. ": " .. text)
end)

function GM:PlayerInitialSpawn(ply)
    print("[Shinri Recreation] Player connected: " .. ply:Nick())
end

function GM:PlayerSpawn(ply)
    self.BaseClass.PlayerSpawn(self, ply)

    ply:SetWalkSpeed(160)
    ply:SetRunSpeed(240)
end
