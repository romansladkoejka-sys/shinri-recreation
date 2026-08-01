SHUI = SHUI or {}
SHUI.Inventory = SHUI.Inventory or {}

local Inventory = SHUI.Inventory

local DESIGN_W = 1600
local DESIGN_H = 900
local CANVAS_W = 1040
local CANVAS_H = 654

local OUTER_X = 11
local OUTER_Y = 20
local OUTER_W = 1018
local OUTER_H = 634

local LEFT_X = OUTER_X + 26
local LEFT_Y = OUTER_Y + 40
local LEFT_W = 296
local CONTENT_H = 568

local CHAR_X = OUTER_X + 341
local CHAR_Y = OUTER_Y + 59
local CHAR_W = 334
local CHAR_H = 568

local GRID_X = OUTER_X + 694
local GRID_Y = OUTER_Y + 40
local GRID_W = 296

local Materials = SHUI.Materials.Inventory
local Colors = SHUI.Colors.Inventory

local GOLD = Colors.Gold
local GOLD_SOFT = Colors.GoldSoft
local PANEL = Colors.Panel
local TEXT = Colors.Text
local TEXT_DIM = Colors.TextDim
local WHITE = Colors.White

local function Scale()
    return math.min(ScrW() / DESIGN_W, ScrH() / DESIGN_H)
end

local function S(value)
    return math.Round(value * Inventory.Scale)
end

local function DrawMaterial(material, x, y, w, h, color)
    if not material or material:IsError() then return end

    surface.SetMaterial(material)
    surface.SetDrawColor(color or WHITE)
    surface.DrawTexturedRect(S(x), S(y), S(w), S(h))
end

local function DrawOutlinedRect(x, y, w, h, color, thickness)
    surface.SetDrawColor(color)
    surface.DrawOutlinedRect(S(x), S(y), S(w), S(h), math.max(1, S(thickness or 1)))
end

local function CharacterName()
    local ply = LocalPlayer()

    if not IsValid(ply) then
        return "ПЕРСОНАЖ"
    end

    local name = ply:GetNWString("ShinriCharacterName", "")
    return name ~= "" and name or ply:Nick()
end

local function MakeHitbox(parent, x, y, w, h, onClick)
    return SHUI.ButtonRenderer.Create(parent, S(x), S(y), S(w), S(h), onClick)
end

local function PaintTopNavigation(frame)
    local tabs = {
        Materials.Tabs.Inventory,
        Materials.Tabs.Description,
        Materials.Tabs.Appearance
    }

    local startX = OUTER_X + 434

    for index, tab in ipairs(tabs) do
        local x = startX + (index - 1) * 54
        local selected = frame.TopTab == index

        if selected then
            DrawMaterial(tab.Active, x, 0, 41, 41, GOLD)
        else
            DrawMaterial(tab.Inactive, x, 0, 41, 41, WHITE)
        end
    end

    local headerScale = 41 / 97
    local headerLeftW = 179 * headerScale
    local headerRightW = 180 * headerScale
    local headerH = 43 * headerScale
    local headerY = OUTER_Y - headerH * 0.5

    DrawMaterial(Materials.Header.ArrowLeft, startX - headerLeftW, headerY, headerLeftW, headerH, WHITE)
    DrawMaterial(Materials.Header.ArrowRight, startX + 153, headerY, headerRightW, headerH, WHITE)
end

local function PaintLeftTabs(frame)
    local tabY = LEFT_Y + 31
    local tabW = LEFT_W / 3
    local icons = {
        Materials.Inventory.Statistic,
        Materials.Inventory.Character,
        Materials.Inventory.Brush
    }

    for index, icon in ipairs(icons) do
        local x = LEFT_X + (index - 1) * tabW
        local selected = frame.LeftTab == index

        if selected then
            surface.SetDrawColor(Colors.TabActive)
            surface.DrawRect(S(x), S(tabY), S(tabW), S(41))
            surface.SetDrawColor(GOLD)
            surface.DrawRect(S(x), S(tabY), S(tabW), S(2))
        else
            surface.SetDrawColor(Colors.TabInactive)
            surface.DrawRect(S(x), S(tabY), S(tabW), S(41))
        end

        DrawOutlinedRect(x, tabY, tabW, 41, Colors.TabBorder, 1)
        DrawMaterial(icon, x + tabW / 2 - 12, tabY + 8, 24, 24, selected and GOLD or WHITE)
    end
end

local function DrawStatusBar(material, color, y, value)
    local iconX = LEFT_X + 27
    local barX = LEFT_X + 57
    local barY = y + 5
    local barW = 210
    local barH = 10

    DrawMaterial(material, iconX, y, 20, 20, color)
    DrawMaterial(Materials.Status.BarBackground, barX, barY, barW, barH, Color(48, 48, 48))

    if Materials.Status.BarForeground and not Materials.Status.BarForeground:IsError() then
        surface.SetMaterial(Materials.Status.BarForeground)
        surface.SetDrawColor(color)
        surface.DrawTexturedRectUV(
            S(barX),
            S(barY),
            S(barW * value),
            S(barH),
            0,
            0,
            value,
            1
        )
    end

    DrawMaterial(Materials.Status.BarStartTick, barX, barY, barW * (12 / 516), barH, WHITE)
    DrawMaterial(Materials.Status.BarTicks, barX, barY, barW, barH, Color(15, 15, 15, 235))
end

local function PaintStatusPage()
    local contentY = LEFT_Y + 72

    DrawMaterial(Materials.Header.BackgroundOverlay, LEFT_X, contentY, LEFT_W, 84, Color(95, 95, 95, 45))

    draw.SimpleText(
        "Состояние",
        "SHUI.Inventory.Label",
        S(LEFT_X + 20),
        S(contentY + 19),
        TEXT_DIM,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER
    )

    DrawStatusBar(Materials.Status.HealthSimple, Color(229, 8, 25), contentY + 42, 1)
    DrawStatusBar(Materials.Status.StaminaSimple, Color(24, 145, 234), contentY + 75, 1)
    DrawStatusBar(Materials.Status.HungerSimple, Color(247, 218, 15), contentY + 108, 1)
    DrawStatusBar(Materials.Status.SleepinessSimple, Color(224, 0, 213), contentY + 141, 1)

    local tempY = contentY + 174
    DrawMaterial(Materials.Status.TemperatureSimple, LEFT_X + 27, tempY, 20, 20, WHITE)
    DrawMaterial(Materials.Status.TemperatureBar, LEFT_X + 57, tempY + 5, 210, 10, WHITE)
    DrawMaterial(Materials.Status.BarPosition, LEFT_X + 139, tempY - 1, 7, 17, WHITE)

    draw.SimpleText(
        "36.6",
        "SHUI.Inventory.Tiny",
        S(LEFT_X + 143),
        S(tempY - 5),
        TEXT,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_BOTTOM
    )

    surface.SetDrawColor(Colors.StatusDivider)
    surface.DrawLine(S(LEFT_X + 20), S(contentY + 207), S(LEFT_X + LEFT_W - 20), S(contentY + 207))

    draw.SimpleText(
        "Эффекты",
        "SHUI.Inventory.Label",
        S(LEFT_X + 20),
        S(contentY + 242),
        TEXT_DIM,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER
    )
end

local function PaintCharacterPage()
    local contentY = LEFT_Y + 72
    local ply = LocalPlayer()
    local characterID = IsValid(ply) and ply:GetNWString("ShinriCharacterID", "") or ""
    local talents = {
        ibuki = "Абсолютный музыкант",
        nagito = "Абсолютный счастливчик",
        komaru = "Обычная ученица",
        nagisa = "Абсолютный обществовед"
    }
    local talent = talents[characterID] or ""

    DrawMaterial(Materials.Header.BackgroundOverlay, LEFT_X, contentY, LEFT_W, 84, Color(95, 95, 95, 45))
    DrawMaterial(Materials.Description.Glow, LEFT_X + 55, contentY + 7, 186, 95, Color(255, 255, 255, 170))

    draw.SimpleText(CharacterName(), "SHUI.Inventory.Name", S(LEFT_X + LEFT_W * 0.5), S(contentY + 88), TEXT, TEXT_ALIGN_CENTER)
    draw.SimpleText(talent, "SHUI.Inventory.Small", S(LEFT_X + LEFT_W * 0.5), S(contentY + 110), TEXT_DIM, TEXT_ALIGN_CENTER)

    DrawMaterial(Materials.Description.Frame, LEFT_X + 58, contentY + 136, 78, 86, WHITE)
    DrawMaterial(Materials.Description.Speed, LEFT_X + 86, contentY + 158, 23, 23, GOLD)
    DrawMaterial(Materials.Description.Frame, LEFT_X + 160, contentY + 136, 78, 86, WHITE)
    DrawMaterial(Materials.Description.Stamina, LEFT_X + 188, contentY + 158, 23, 23, GOLD)
end

local function PaintAppearancePage()
    local contentY = LEFT_Y + 72

    DrawMaterial(Materials.Header.BackgroundOverlay, LEFT_X, contentY, LEFT_W, 84, Color(95, 95, 95, 45))
    draw.SimpleText("Пластика", "SHUI.Inventory.Small", S(LEFT_X + 20), S(contentY + 20), TEXT)

    surface.SetDrawColor(44, 44, 44, 255)
    surface.DrawRect(S(LEFT_X + 20), S(contentY + 48), S(LEFT_W - 40), S(3))
    surface.SetDrawColor(GOLD_SOFT)
    surface.DrawRect(S(LEFT_X + 20), S(contentY + 48), S(116), S(3))
    surface.SetDrawColor(GOLD)
    draw.NoTexture()
    surface.DrawPoly({
        {x = S(LEFT_X + 131), y = S(contentY + 48)},
        {x = S(LEFT_X + 136), y = S(contentY + 43)},
        {x = S(LEFT_X + 141), y = S(contentY + 48)},
        {x = S(LEFT_X + 136), y = S(contentY + 53)}
    })
end

local function PaintCenterBackground()
    DrawMaterial(Materials.Character.Background, CHAR_X, CHAR_Y, CHAR_W, CHAR_H, WHITE)
end

local function PaintCenterOverlays()
    local slotX = CHAR_X + 20
    local slotSize = 54
    DrawMaterial(Materials.Character.Head, slotX, CHAR_Y, slotSize, slotSize, Color(255, 255, 255, 175))
    DrawMaterial(Materials.Character.Body, slotX, CHAR_Y + 60, slotSize, slotSize, Color(255, 255, 255, 175))
    DrawMaterial(Materials.Character.Hands, slotX, CHAR_Y + 120, slotSize, slotSize, Color(255, 255, 255, 175))
    DrawMaterial(Materials.Character.Feet, slotX, CHAR_Y + 180, slotSize, slotSize, Color(255, 255, 255, 175))
    DrawMaterial(Materials.Character.Back, CHAR_X + CHAR_W - 74, CHAR_Y, slotSize, slotSize, Color(255, 255, 255, 175))

    DrawMaterial(Materials.Character.WeaponLeft, CHAR_X + 20, CHAR_Y + 446, 80, 80, Color(255, 255, 255, 190))
    DrawMaterial(Materials.Character.WeaponRight, CHAR_X + CHAR_W - 100, CHAR_Y + 446, 80, 80, Color(255, 255, 255, 190))

    DrawMaterial(Materials.Character.ArrowLeft, CHAR_X + 75, CHAR_Y + 503, 54, 54, Color(255, 255, 255, 185))
    DrawMaterial(Materials.Character.Eye, CHAR_X + 145, CHAR_Y + 516, 43, 35, GOLD)
    DrawMaterial(Materials.Character.ArrowRight, CHAR_X + 205, CHAR_Y + 503, 54, 54, Color(255, 255, 255, 185))
end

local function PaintInventoryGrid(frame)
    surface.SetDrawColor(PANEL)
    surface.DrawRect(S(GRID_X), S(GRID_Y), S(GRID_W), S(CONTENT_H))
    DrawOutlinedRect(GRID_X, GRID_Y, GRID_W, CONTENT_H, Colors.Border, 1)

    surface.SetDrawColor(12, 12, 12, 255)
    surface.DrawRect(S(GRID_X), S(GRID_Y), S(GRID_W), S(40))
    DrawOutlinedRect(GRID_X, GRID_Y, GRID_W, 40, Colors.HeaderBorder, 1)

    DrawMaterial(Materials.Inventory.Organize, GRID_X + 1, GRID_Y, 40, 40, WHITE)
    DrawMaterial(Materials.Inventory.Backpack, GRID_X + 55, GRID_Y + 9, 22, 22, WHITE)

    draw.SimpleText(
        "Все предметы",
        "SHUI.Inventory.Label",
        S(GRID_X + 88),
        S(GRID_Y + 20),
        TEXT,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER
    )

    local slot = 58
    local startY = GRID_Y + 53

    for row = 0, 7 do
        for column = 0, 4 do
            DrawMaterial(
                Materials.Inventory.Slot,
                GRID_X + column * slot,
                startY + row * slot,
                slot,
                slot,
                Color(255, 255, 255, 210)
            )
        end
    end

    surface.SetDrawColor(GOLD)
    surface.DrawRect(S(GRID_X + GRID_W - 3), S(startY), S(2), S(446))

    local footerY = GRID_Y + CONTENT_H - 32
    DrawMaterial(Materials.Inventory.Bag, GRID_X + 1, footerY + 14, 18, 18, WHITE)
    draw.SimpleText("0", "SHUI.Inventory.Small", S(GRID_X + 28), S(footerY + 12), TEXT)
    draw.SimpleText("17", "SHUI.Inventory.Small", S(GRID_X + GRID_W - 14), S(footerY + 12), TEXT, TEXT_ALIGN_RIGHT)

    surface.SetDrawColor(Colors.FooterTrack)
    surface.DrawRect(S(GRID_X + 32), S(footerY + 22), S(GRID_W - 60), S(6))
    surface.SetDrawColor(GOLD_SOFT)
    surface.DrawRect(S(GRID_X + 32), S(footerY + 22), S((GRID_W - 60) * 0.78), S(6))
    surface.SetDrawColor(Colors.FooterDanger)
    surface.DrawRect(S(GRID_X + 32 + (GRID_W - 60) * 0.9), S(footerY + 22), S((GRID_W - 60) * 0.1), S(6))
end

local function SetupModelPanel(panel)
    if not IsValid(panel) then return end

    local ply = LocalPlayer()
    local model = IsValid(ply) and ply:GetModel() or "models/player/kleiner.mdl"

    if not model or model == "" then
        model = "models/player/kleiner.mdl"
    end

    panel:SetModel(model)

    local entity = panel:GetEntity()
    if not IsValid(entity) then return end

    local mins, maxs = entity:GetRenderBounds()
    local height = math.max(1, maxs.z - mins.z)
    local centerZ = (mins.z + maxs.z) * 0.5

    panel:SetFOV(27)
    panel:SetCamPos(Vector(height * 1.02, height * 0.04, centerZ + height * 0.03))
    panel:SetLookAt(Vector(0, 0, centerZ))
    entity:SetAngles(Angle(0, 18, 0))

    local sequence = entity:LookupSequence("idle_all_01")
    if sequence and sequence >= 0 then
        entity:ResetSequence(sequence)
    end
end

function Inventory.Close()
    if IsValid(Inventory.Frame) then
        Inventory.Frame:Remove()
    end

    Inventory.Frame = nil
end

function Inventory.Open()
    Inventory.Close()

    Inventory.Scale = Scale()
    SHUI.CreateInventoryFonts(Inventory.Scale)

    local frame = vgui.Create("DFrame")
    Inventory.Frame = frame

    frame:SetSize(S(CANVAS_W), S(CANVAS_H))
    frame:SetPos((ScrW() - S(CANVAS_W)) * 0.5, (ScrH() - S(CANVAS_H)) * 0.5)
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:SetPaintShadow(false)
    frame:SetDeleteOnClose(true)
    frame:MakePopup()
    frame.TopTab = 1
    frame.LeftTab = 1

    frame.Paint = function(self, w, h)
        DrawMaterial(Materials.Header.BackgroundGradient, OUTER_X, OUTER_Y, OUTER_W, OUTER_H, WHITE)
        DrawOutlinedRect(OUTER_X, OUTER_Y, OUTER_W, OUTER_H, GOLD, 1)

        surface.SetDrawColor(PANEL)
        surface.DrawRect(S(LEFT_X), S(LEFT_Y), S(LEFT_W), S(CONTENT_H))
        DrawOutlinedRect(LEFT_X, LEFT_Y, LEFT_W, CONTENT_H, Colors.Border, 1)

        draw.SimpleText(
            CharacterName(),
            "SHUI.Inventory.Name",
            S(LEFT_X + LEFT_W * 0.5),
            S(LEFT_Y + 13),
            TEXT,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )

        PaintTopNavigation(self)
        PaintLeftTabs(self)
        PaintCenterBackground()
        PaintInventoryGrid(self)

        if self.LeftTab == 1 then
            PaintStatusPage()
        elseif self.LeftTab == 2 then
            PaintCharacterPage()
        else
            PaintAppearancePage()
        end
    end

    frame.PaintOver = function()
        PaintCenterOverlays()
    end

    local modelPanel = vgui.Create("DModelPanel", frame)
    frame.ModelPanel = modelPanel
    modelPanel:SetPos(S(CHAR_X + 82), S(CHAR_Y + 47))
    modelPanel:SetSize(S(CHAR_W - 114), S(CHAR_H - 98))
    modelPanel:SetPaintBackground(false)
    SetupModelPanel(modelPanel)

    modelPanel.LayoutEntity = function(self, entity)
        if self:IsHovered() and input.IsMouseDown(MOUSE_LEFT) then
            local currentX = gui.MouseX()
            self.LastMouseX = self.LastMouseX or currentX
            local delta = currentX - self.LastMouseX
            entity:SetAngles(entity:GetAngles() + Angle(0, delta * 0.55, 0))
            self.LastMouseX = currentX
        else
            self.LastMouseX = nil
        end

        self:RunAnimation()
    end

    for index = 1, 3 do
        MakeHitbox(frame, LEFT_X + (index - 1) * (LEFT_W / 3), LEFT_Y + 31, LEFT_W / 3, 41, function()
            frame.LeftTab = index
        end)
    end

    local closeButton = MakeHitbox(frame, OUTER_X + 1000, 7, 32, 28, Inventory.Close)
    SHUI.ButtonRenderer.SetMaterial(closeButton, Materials.Header.Back, GOLD, Colors.GoldHover)

    frame.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE or key == KEY_I then
            Inventory.Close()
        end
    end

    frame.OnRemove = function()
        if Inventory.Frame == frame then
            Inventory.Frame = nil
        end
    end
end

function ShinriOpenInventory()
    Inventory.Open()
end

concommand.Add("shui_inventory", Inventory.Open)
concommand.Add("shinri_inventory", Inventory.Open)

hook.Add("PlayerButtonDown", "SHUI.Inventory.OpenKey", function(ply, button)
    if ply ~= LocalPlayer() or button ~= KEY_I then return end
    if gui.IsGameUIVisible() or IsValid(vgui.GetKeyboardFocus()) then return end

    if IsValid(Inventory.Frame) then
        Inventory.Close()
    else
        Inventory.Open()
    end
end)

print("[SHUI] Inventory visual reconstruction loaded.")
