local ChatFrame
local ChatEntry
local ChatLog

local InputHistory = {}
local HistoryPosition = 1

local ChatOpen = false
local CursorEnabled = false

local LastMessageTime = 0
local ClosedChatDuration = 7

surface.CreateFont("ShinriChatText", {
    font = "Tahoma",
    size = 18,
    weight = 500
})

surface.CreateFont("ShinriChatHint", {
    font = "Tahoma",
    size = 14,
    weight = 500
})

surface.CreateFont("ShinriChatOOC", {
    font = "Tahoma",
    size = 17,
    weight = 600
})


local function AddChatMessage(ply, characterName, msgType, text)

    if not IsValid(ChatLog) then return end

    local name = characterName ~= "" and characterName or (IsValid(ply) and ply:Nick() or "SERVER")

    if msgType == "me" then

        ChatLog:InsertColorChange(205, 135, 255, 255)
        ChatLog:AppendText("* " .. name .. " " .. text .. "\n")

    elseif msgType == "do" then

        ChatLog:InsertColorChange(135, 195, 255, 255)
        ChatLog:AppendText("* " .. text .. " (" .. name .. ")\n")

    elseif msgType == "roll" then

        ChatLog:InsertColorChange(255, 210, 90, 255)
        ChatLog:AppendText(
            name .. " бросает кубик: " .. text .. "/100\n"
        )

    elseif msgType == "ooc" then

        ChatLog:InsertColorChange(160, 160, 160, 255)
        ChatLog:AppendText("[OOC] ")

        ChatLog:InsertColorChange(130, 190, 255, 255)
        ChatLog:AppendText(name .. ": ")

        ChatLog:InsertColorChange(210, 210, 210, 255)
        ChatLog:AppendText(text .. "\n")

    elseif msgType == "system" then

        ChatLog:InsertColorChange(255, 110, 110, 255)
        ChatLog:AppendText("[SYSTEM] " .. text .. "\n")

    else

        ChatLog:InsertColorChange(100, 180, 255, 255)
        ChatLog:AppendText(name .. ": ")

        ChatLog:InsertColorChange(235, 235, 235, 255)
        ChatLog:AppendText(text .. "\n")

    end

    ChatLog:GotoTextEnd()

    LastMessageTime = CurTime()

end


local function UpdateChatAppearance()

    if not IsValid(ChatFrame) then return end

    if ChatOpen then

        ChatFrame:SetAlpha(255)

    else

        local elapsed = CurTime() - LastMessageTime

        if elapsed <= ClosedChatDuration then

            local fadeStart = ClosedChatDuration - 2

            if elapsed > fadeStart then

                local fraction =
                    1 - ((elapsed - fadeStart) / 2)

                ChatFrame:SetAlpha(
                    math.Clamp(fraction * 210, 0, 210)
                )

            else

                ChatFrame:SetAlpha(210)

            end

        else

            ChatFrame:SetAlpha(0)

        end

    end

end


local function CloseShinriChat()

    ChatOpen = false
    CursorEnabled = false

    if IsValid(ChatEntry) then
        ChatEntry:SetVisible(false)
        ChatEntry:KillFocus()
    end

    if IsValid(ChatFrame) then
        ChatFrame:SetMouseInputEnabled(false)
        ChatFrame:SetKeyboardInputEnabled(false)
    end

    gui.EnableScreenClicker(false)

end


local function SendCurrentMessage()

    if not IsValid(ChatEntry) then return end

    local text = string.Trim(ChatEntry:GetValue())

    if text == "" then
        CloseShinriChat()
        return
    end

    table.insert(InputHistory, text)

    if #InputHistory > 50 then
        table.remove(InputHistory, 1)
    end

    HistoryPosition = #InputHistory + 1

    net.Start("ShinriChat_Send")
        net.WriteString(text)
    net.SendToServer()

    ChatEntry:SetText("")

    CloseShinriChat()

end


local function CreateShinriChat()

    if IsValid(ChatFrame) then return end

    ChatFrame = vgui.Create("DFrame")

    ChatFrame:SetSize(620, 330)
    ChatFrame:SetPos(20, ScrH() - 520)

    ChatFrame:SetTitle("")
    ChatFrame:SetDraggable(false)
    ChatFrame:ShowCloseButton(false)

    ChatFrame.Paint = function(self, w, h)

        local alpha = self:GetAlpha()

        draw.RoundedBox(
            3,
            0,
            0,
            w,
            h,
            Color(35, 13, 18, math.min(alpha, 210))
        )

        if ChatOpen then

            draw.RoundedBox(
                0,
                0,
                0,
                w,
                30,
                Color(75, 18, 28, 235)
            )

            draw.SimpleText(
                "ESC — закрыть | F3 — курсор | ↑ ↓ — история | Enter — отправить",
                "ShinriChatHint",
                9,
                8,
                Color(225, 225, 225),
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_TOP
            )

        end

    end


    ChatLog = vgui.Create("RichText", ChatFrame)

    ChatLog:SetPos(10, 38)
    ChatLog:SetSize(600, 240)

    function ChatLog:PerformLayout()

        self:SetFontInternal("ShinriChatText")
        self:SetFGColor(
            Color(235, 235, 235)
        )

    end


    ChatEntry = vgui.Create(
        "DTextEntry",
        ChatFrame
    )

    ChatEntry:SetPos(10, 288)
    ChatEntry:SetSize(600, 32)

    ChatEntry:SetFont("ShinriChatText")

    ChatEntry:SetPlaceholderText(
        "Сообщение | /me | /do | /roll | // OOC"
    )

    ChatEntry:SetVisible(false)


    ChatEntry.OnKeyCodeTyped =
        function(self, key)

        if key == KEY_ENTER
        or key == KEY_PAD_ENTER then

            SendCurrentMessage()

            return true

        end


        if key == KEY_ESCAPE then

            CloseShinriChat()

            return true

        end


        if key == KEY_F3 then

            CursorEnabled = not CursorEnabled

            gui.EnableScreenClicker(CursorEnabled)

            if not CursorEnabled then
                self:RequestFocus()
            end

            return true

        end


        if key == KEY_UP then

            if #InputHistory == 0 then
                return true
            end

            HistoryPosition =
                math.max(
                    1,
                    HistoryPosition - 1
                )

            self:SetText(
                InputHistory[
                    HistoryPosition
                ] or ""
            )

            self:SetCaretPos(
                #self:GetValue()
            )

            return true

        end


        if key == KEY_DOWN then

            if #InputHistory == 0 then
                return true
            end

            HistoryPosition =
                math.min(
                    #InputHistory + 1,
                    HistoryPosition + 1
                )

            if HistoryPosition >
                #InputHistory then

                self:SetText("")

            else

                self:SetText(
                    InputHistory[
                        HistoryPosition
                    ] or ""
                )

            end

            self:SetCaretPos(
                #self:GetValue()
            )

            return true

        end

    end

end


local function OpenShinriChat()

    CreateShinriChat()

    ChatOpen = true

    ChatFrame:SetAlpha(255)

    ChatEntry:SetVisible(true)

    ChatFrame:MakePopup()

    ChatFrame:SetMouseInputEnabled(true)
    ChatFrame:SetKeyboardInputEnabled(true)

    CursorEnabled = false
    gui.EnableScreenClicker(false)

    ChatEntry:RequestFocus()

    HistoryPosition =
        #InputHistory + 1

end


hook.Add(
    "PlayerBindPress",
    "ShinriChat_Open",
    function(ply, bind, pressed)

        if not pressed then return end

        bind = string.lower(bind)

        if string.find(
            bind,
            "messagemode",
            1,
            true
        ) then

            OpenShinriChat()

            return true

        end

    end
)


hook.Add(
    "StartChat",
    "ShinriChat_BlockDefault",
    function()

        OpenShinriChat()

        return true

    end
)


hook.Add(
    "Think",
    "ShinriChat_Fade",
    function()

        UpdateChatAppearance()

    end
)


net.Receive(
    "ShinriChat_Receive",
    function()

        local ply =
            net.ReadEntity()

        local characterName =
            net.ReadString()

        local msgType =
            net.ReadString()

        local text =
            net.ReadString()

        CreateShinriChat()

        AddChatMessage(
            ply,
            characterName,
            msgType,
            text
        )

    end
)


