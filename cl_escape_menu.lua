print("[Shinri] cl_escape_menu.lua loaded")

local EscapeMenu
local escapeWasVisible = false
local nextEscapeAction = 0

local function CloseEscapeMenu()
    if IsValid(EscapeMenu) then
        EscapeMenu:Remove()
    end

    EscapeMenu = nil
    gui.EnableScreenClicker(false)
end

function ShinriOpenEscapeMenu()
    if IsValid(EscapeMenu) then
        CloseEscapeMenu()
        return
    end

    EscapeMenu = vgui.Create("DFrame")
    EscapeMenu:SetSize(ScrW(), ScrH())
    EscapeMenu:SetPos(0, 0)
    EscapeMenu:SetTitle("")
    EscapeMenu:SetDraggable(false)
    EscapeMenu:ShowCloseButton(false)
    EscapeMenu:SetDeleteOnClose(true)
    EscapeMenu:MakePopup()

    EscapeMenu.Paint = function(self, w, h)
        Derma_DrawBackgroundBlur(self, self.StartTime or SysTime())

        surface.SetDrawColor(0, 0, 0, 160)
        surface.DrawRect(0, 0, w, h)
        -- Оригинальный фон ESC Menu из UI @ ST
        local leftBg = Material("dro/sprites/escmenu/left_bg.png", "smooth")

        if not leftBg:IsError() then
            surface.SetMaterial(leftBg)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local logo = Material("shinri_ui/logo.png", "smooth")

        if not logo:IsError() then
            surface.SetMaterial(logo)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(50, 45, 250, 100)
        else
            draw.SimpleText(
                "LOGO ERROR",
                "Trebuchet24",
                65,
                55,
                Color(255, 0, 0),
                TEXT_ALIGN_LEFT
            )
        end

        surface.SetDrawColor(225, 25, 35, 255)
        surface.DrawRect(50, 125, 205, 4)

        draw.SimpleText(
            "SHINRI RECREATION",
            "Trebuchet18",
            50,
            h - 50,
            Color(175, 175, 175),
            TEXT_ALIGN_LEFT
        )
    end

    EscapeMenu.StartTime = SysTime()

    local menuItems = {
        {
            text = "ПРОДОЛЖИТЬ ИГРУ",
            action = function()
                CloseEscapeMenu()
            end
        },
        {
            text = "ВЫБРАТЬ ПЕРСОНАЖА",
            action = function()
                CloseEscapeMenu()

                timer.Simple(0, function()
                    if isfunction(ShinriOpenCharacterMenu) then
                        ShinriOpenCharacterMenu()
                    else
                        chat.AddText(
                            Color(220, 40, 50),
                            "[Shinri] ",
                            color_white,
                            "Р¤СѓРЅРєС†РёСЏ РјРµРЅСЋ РїРµСЂСЃРѕРЅР°Р¶РµР№ РЅРµ РЅР°Р№РґРµРЅР°."
                        )
                    end
                end)
            end
        },
        {
            text = "ОТКРЫТЬ ХАБ",
            action = function()
                chat.AddText(
                    Color(255, 200, 90),
                    "[Shinri] ",
                    color_white,
                    "РҐР°Р± РїРѕРєР° РЅР°С…РѕРґРёС‚СЃСЏ РІ СЂР°Р·СЂР°Р±РѕС‚РєРµ."
                )
            end
        },
        {
            text = "РЕДАКТОР АНИМАЦИЙ",
            action = function()
                chat.AddText(
                    Color(255, 200, 90),
                    "[Shinri] ",
                    color_white,
                    "Р РµРґР°РєС‚РѕСЂ Р°РЅРёРјР°С†РёР№ РїРѕРєР° РЅР°С…РѕРґРёС‚СЃСЏ РІ СЂР°Р·СЂР°Р±РѕС‚РєРµ."
                )
            end
        },
        {
            text = "НАСТРОЙКИ",
            action = function()
                CloseEscapeMenu()

                timer.Simple(0, function()
                    gui.ActivateGameUI()

                    timer.Simple(0.05, function()
                        RunConsoleCommand(
                            "gamemenucommand",
                            "openoptionsdialog"
                        )
                    end)
                end)
            end
        },
        {
            text = "МЕНЮ GARRY'S MOD",
            action = function()
                CloseEscapeMenu()

                timer.Simple(0, function()
                    gui.ActivateGameUI()
                end)
            end
        },
        {
            text = "ОТКЛЮЧИТЬСЯ",
            action = function()
                CloseEscapeMenu()
                RunConsoleCommand("disconnect")
            end
        }
    }

    local startY = math.max(175, ScrH() * 0.23)
    local buttonHeight = math.Clamp(ScrH() * 0.058, 46, 62)
    local spacing = 9
    local buttonWidth = ScrW() * 0.29

    for index, item in ipairs(menuItems) do
        local button = vgui.Create("DButton", EscapeMenu)

        button:SetPos(
            55,
            startY + (index - 1) * (buttonHeight + spacing)
        )

        button:SetSize(buttonWidth, buttonHeight)
        button:SetText("")

        button.Paint = function(self, w, h)
            local hovered = self:IsHovered()

            if hovered then
                surface.SetDrawColor(235, 190, 75, 245)
                surface.DrawRect(0, 0, w, h)

                surface.SetDrawColor(255, 235, 160, 255)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            else
                surface.SetDrawColor(20, 8, 12, 185)
                surface.DrawRect(0, 0, w, h)

                surface.SetDrawColor(245, 195, 75, 255)
                surface.DrawRect(0, 6, 5, h - 12)
            end

            draw.SimpleText(
                item.text,
                "Trebuchet24",
                28,
                h / 2,
                hovered and Color(25, 8, 10) or Color(255, 255, 255),
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
        end

        button.DoClick = item.action
    end
end

-- Р СѓС‡РЅР°СЏ РєРѕРјР°РЅРґР° РґР»СЏ РїСЂРѕРІРµСЂРєРё Р·Р°РіСЂСѓР·РєРё С„Р°Р№Р»Р°.
concommand.Add("shinri_menu", function()
    ShinriOpenEscapeMenu()
end)

-- РџРµСЂРµС…РІР°С‚ СЃС‚Р°РЅРґР°СЂС‚РЅРѕРіРѕ ESC-РјРµРЅСЋ.
hook.Add("Think", "Shinri_EscapeMenuThink", function()
    local gameUIVisible = gui.IsGameUIVisible()

    if gameUIVisible and not escapeWasVisible and CurTime() >= nextEscapeAction then
        gui.HideGameUI()

        nextEscapeAction = CurTime() + 0.20

        if IsValid(EscapeMenu) then
            CloseEscapeMenu()
        else
            ShinriOpenEscapeMenu()
        end
    end

    escapeWasVisible = gameUIVisible
end)



