SHUI = SHUI or {}

SHUI.Version = "0.2"
SHUI.ButtonRenderer = SHUI.ButtonRenderer or {}

function SHUI.ButtonRenderer.Create(parent, x, y, width, height, onClick)
    local button = vgui.Create("Panel", parent)
    button:SetPos(x, y)
    button:SetSize(width, height)
    button:SetMouseInputEnabled(true)
    button:SetKeyboardInputEnabled(false)
    button:SetCursor("hand")
    button.SHUIOnClick = onClick

    button.OnMousePressed = function(self, mouseCode)
        if mouseCode ~= MOUSE_LEFT then return end

        self.SHUIPressed = true
        self:MouseCapture(true)
    end

    button.OnMouseReleased = function(self, mouseCode)
        if mouseCode ~= MOUSE_LEFT or not self.SHUIPressed then return end

        self.SHUIPressed = false
        self:MouseCapture(false)

        if self:IsHovered() and self.SHUIOnClick then
            self.SHUIOnClick(self)
        end
    end

    button.OnRemove = function(self)
        if self.SHUIPressed then
            self:MouseCapture(false)
        end
    end

    return button
end

function SHUI.ButtonRenderer.SetMaterial(button, material, color, hoverColor)
    button.Paint = function(self, width, height)
        if not material or material:IsError() then return end

        surface.SetMaterial(material)
        surface.SetDrawColor(self:IsHovered() and hoverColor or color)
        surface.DrawTexturedRect(0, 0, width, height)
    end
end
