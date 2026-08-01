SHUI = SHUI or {}

surface.CreateFont("SHUI.Title", {
    font = "Trebuchet MS",
    size = 26,
    weight = 900
})

surface.CreateFont("SHUI.Menu", {
    font = "Trebuchet MS",
    size = 22,
    weight = 700
})

surface.CreateFont("SHUI.Footer", {
    font = "Trebuchet MS",
    size = 18,
    weight = 500
})

function SHUI.CreateInventoryFonts(scale)
    scale = scale or 1

    surface.CreateFont("SHUI.Inventory.Name", {
        font = "Roboto",
        size = math.max(14, math.Round(15 * scale)),
        weight = 700,
        extended = true
    })

    surface.CreateFont("SHUI.Inventory.Label", {
        font = "Roboto",
        size = math.max(12, math.Round(13 * scale)),
        weight = 500,
        extended = true
    })

    surface.CreateFont("SHUI.Inventory.Small", {
        font = "Roboto",
        size = math.max(10, math.Round(11 * scale)),
        weight = 500,
        extended = true
    })

    surface.CreateFont("SHUI.Inventory.Tiny", {
        font = "Roboto",
        size = math.max(9, math.Round(9 * scale)),
        weight = 500,
        extended = true
    })
end
