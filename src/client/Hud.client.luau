--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local BuildingConfig = require(config.BuildingConfig)
local CropConfig = require(config.CropConfig)
local ProductConfig = require(config.ProductConfig)
local VariantConfig = require(config.VariantConfig)
local request = ReplicatedStorage:WaitForChild("GetHudState") :: RemoteFunction
local seedRequest = ReplicatedStorage:WaitForChild("SeedShopRequest") :: RemoteEvent
local sellRequest = ReplicatedStorage:WaitForChild("SellRequest") :: RemoteEvent
local buildRequest = ReplicatedStorage:WaitForChild("BuildRequest") :: RemoteEvent
local hudNotice = ReplicatedStorage:WaitForChild("HudNotice") :: RemoteEvent
local selection = script.Parent:WaitForChild("BuildSelection") :: BindableEvent
local modeChanged = script.Parent:WaitForChild("BuildModeChanged") :: BindableEvent

local DARK = Color3.fromRGB(25, 29, 39)
local WHITE = Color3.fromRGB(255, 252, 239)
local RED = Color3.fromRGB(255, 71, 75)
local ORANGE = Color3.fromRGB(255, 168, 51)
local GREEN = Color3.fromRGB(79, 220, 75)
local CYAN = Color3.fromRGB(47, 204, 239)
local PANEL = Color3.fromRGB(255, 244, 213)

local gui = Instance.new("ScreenGui")
gui.Name = "RanchHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local clickSound = Instance.new("Sound")
clickSound.Name = "RanchClick"
clickSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
clickSound.Volume = 0.35
clickSound.Parent = SoundService

local function block(parent: Instance, name: string, size: UDim2, position: UDim2,
    color: Color3, corner: number): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = color
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local rounding = Instance.new("UICorner")
    rounding.CornerRadius = UDim.new(0, corner)
    rounding.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = DARK
    stroke.Thickness = 3
    stroke.Parent = frame
    return frame
end

local function text(parent: Instance, name: string, value: string, size: UDim2,
    position: UDim2, fontSize: number, color: Color3): TextLabel
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Size = size
    item.Position = position
    item.BackgroundTransparency = 1
    item.Font = Enum.Font.GothamBlack
    item.Text = value
    item.TextSize = fontSize
    item.TextColor3 = color
    item.TextStrokeColor3 = DARK
    item.TextStrokeTransparency = if color == DARK then 1 else 0.15
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Parent = parent
    return item
end

local function button(parent: Instance, name: string, value: string, size: UDim2,
    position: UDim2, color: Color3, fontSize: number): TextButton
    local item = Instance.new("TextButton")
    item.Name = name
    item.Size = size
    item.Position = position
    item.BackgroundColor3 = color
    item.BorderSizePixel = 0
    item.Font = Enum.Font.GothamBlack
    item.Text = value
    item.TextColor3 = WHITE
    item.TextStrokeColor3 = DARK
    item.TextStrokeTransparency = 0
    item.TextSize = fontSize
    item.TextWrapped = true
    item.AutoButtonColor = true
    item.Parent = parent
    local rounding = Instance.new("UICorner")
    rounding.CornerRadius = UDim.new(0, 9)
    rounding.Parent = item
    local stroke = Instance.new("UIStroke")
    stroke.Color = DARK
    stroke.Thickness = 3
    stroke.Parent = item
    local shine = Instance.new("UIGradient")
    shine.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, color),
    })
    shine.Rotation = 90
    shine.Parent = item
    return item
end

local heading = block(gui, "Currency", UDim2.fromOffset(408, 76),
    UDim2.fromOffset(18, 18), DARK, 13)
local coins = text(heading, "Coins", "💵  ... Coins", UDim2.fromOffset(390, 39),
    UDim2.fromOffset(12, 4), 28, GREEN)
local seeds = text(heading, "Seeds", "🥕  ... Seeds", UDim2.fromOffset(280, 26),
    UDim2.fromOffset(12, 43), 18, CYAN)
local eggStatus = text(heading, "EggStatus", "", UDim2.fromOffset(122, 26),
    UDim2.fromOffset(280, 43), 15, ORANGE)
eggStatus.TextXAlignment = Enum.TextXAlignment.Right

local nav = block(gui, "Navigation", UDim2.fromOffset(98, 350),
    UDim2.fromOffset(18, 108), PANEL, 13)
local navButtons: { [string]: TextButton } = {}
local panels: { [string]: Frame } = {}
local pages = {
    { Id = "Shop", Icon = "🛒", Caption = "TIENDA", Color = RED },
    { Id = "Inventory", Icon = "🎒", Caption = "BOLSA", Color = ORANGE },
    { Id = "Build", Icon = "🔨", Caption = "CREAR", Color = GREEN },
    { Id = "Guide", Icon = "📖", Caption = "GUÍA", Color = CYAN },
}
for index, page in pages do
    local item = button(nav, page.Id, page.Icon .. "\n" .. page.Caption,
        UDim2.fromOffset(76, 70), UDim2.fromOffset(11, 11 + (index - 1) * 82),
        page.Color, 17)
    navButtons[page.Id] = item
end

local function pageFrame(name: string, color: Color3): Frame
    local frame = block(gui, name, UDim2.fromOffset(390, 374),
        UDim2.fromOffset(132, 108), PANEL, 13)
    local cap = block(frame, "Header", UDim2.new(1, -16, 0, 52),
        UDim2.fromOffset(8, 8), color, 9)
    text(cap, "Title", name == "Inventory" and "ARTÍCULOS" or
        (name == "Build" and "CONSTRUIR" or name == "Guide" and "GUÍA" or "TIENDA"),
        UDim2.new(1, -18, 1, 0), UDim2.fromOffset(9, 0), 25, WHITE)
    frame.Visible = false
    panels[name] = frame
    return frame
end

local shop = pageFrame("Shop", RED)
local shopCard = block(shop, "SeedCard", UDim2.new(1, -24, 0, 165),
    UDim2.fromOffset(12, 75), Color3.fromRGB(255, 225, 151), 11)
text(shopCard, "Icon", "🥕", UDim2.fromOffset(65, 74),
    UDim2.fromOffset(12, 6), 46, WHITE)
text(shopCard, "Name", "CARROT SEED", UDim2.new(1, -92, 0, 38),
    UDim2.fromOffset(86, 10), 23, DARK)
text(shopCard, "Price", tostring(CropConfig.Carrot.BuyPrice) .. " Coins cada una",
    UDim2.new(1, -92, 0, 28), UDim2.fromOffset(86, 48), 17, DARK)
local buyButton = button(shopCard, "Buy", "COMPRAR  +1",
    UDim2.new(1, -24, 0, 54), UDim2.fromOffset(12, 98), GREEN, 21)
text(shop, "ShopHint", "Acércate al puesto amarillo de tu parcela para comprar.",
    UDim2.new(1, -28, 0, 70), UDim2.fromOffset(14, 252), 16, DARK)
buyButton.Activated:Connect(function()
    clickSound:Play()
    seedRequest:FireServer()
end)

local inventory = pageFrame("Inventory", ORANGE)
local list = Instance.new("ScrollingFrame")
list.Name = "ItemList"
list.Size = UDim2.new(1, -24, 0, 175)
list.Position = UDim2.fromOffset(12, 75)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = DARK
list.CanvasSize = UDim2.fromOffset(0, 0)
list.Parent = inventory
local selectedText = text(inventory, "Selected", "Selecciona un artículo.",
    UDim2.new(1, -24, 0, 31), UDim2.fromOffset(12, 253), 15, DARK)
local sellButton = button(inventory, "Sell", "VENDER PILA",
    UDim2.new(1, -24, 0, 48), UDim2.fromOffset(12, 291), CYAN, 20)
local selectedId: string? = nil
local selectedVariant: string? = nil
local selectedQuantity = 0
local inventoryKey = ""

local function renderInventory(entries: { any })
    local parts = {}
    for _, entry in entries do
        table.insert(parts, entry.ItemId .. "/" .. entry.Variant .. "/" .. entry.Quantity)
    end
    local key = table.concat(parts, "|")
    if key == inventoryKey then return end
    inventoryKey = key
    for _, child in list:GetChildren() do
        if child:IsA("TextButton") then child:Destroy() end
    end
    selectedQuantity = 0
    for index, entry in entries do
        local itemId = entry.ItemId
        local variant = entry.Variant
        local quantity = entry.Quantity
        local value = (CropConfig[itemId] or ProductConfig[itemId])
        local multiplier = VariantConfig[variant]
        local worth = if value and multiplier then value.SellPrice * multiplier.ValueMultiplier
            * quantity else 0
        local row = button(list, "Item_" .. index,
            itemId .. "  •  " .. variant .. "  ×" .. quantity .. "\n" .. worth .. " Coins",
            UDim2.new(1, -10, 0, 53), UDim2.fromOffset(2, (index - 1) * 60),
            if itemId == "Egg" then ORANGE else GREEN, 15)
        row.TextXAlignment = Enum.TextXAlignment.Left
        if itemId == selectedId and variant == selectedVariant then
            selectedQuantity = quantity
            row.BackgroundColor3 = CYAN
        end
        row.Activated:Connect(function()
            clickSound:Play()
            selectedId = itemId
            selectedVariant = variant
            inventoryKey = "" -- Refresh the selected row's highlight.
            selectedQuantity = quantity
            selectedText.Text = itemId .. " / " .. variant .. " ×" .. quantity
            renderInventory(entries)
        end)
    end
    list.CanvasSize = UDim2.fromOffset(0, #entries * 60)
    if selectedQuantity > 0 then
        selectedText.Text = (selectedId or "") .. " / " .. (selectedVariant or "")
            .. " ×" .. selectedQuantity
    else
        selectedId = nil
        selectedVariant = nil
        selectedText.Text = if #entries == 0 then "Bolsa vacía." else "Selecciona un artículo."
    end
end

sellButton.Activated:Connect(function()
    clickSound:Play()
    if selectedId and selectedVariant and selectedQuantity > 0 then
        sellRequest:FireServer(selectedId, selectedVariant, selectedQuantity)
    else
        selectedText.Text = "Elige una pila para vender."
    end
end)
text(inventory, "SellHint", "La venta se confirma cerca del puesto azul.",
    UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 340), 12, DARK)

local build = pageFrame("Build", GREEN)
local buildButtons: { [string]: TextButton } = {}
for index, buildingId in { "Barn", "SmallField", "ChickenCoop" } do
    local definition = BuildingConfig[buildingId]
    local item = button(build, buildingId,
        definition.DisplayName .. "  •  " .. definition.Price .. " Coins",
        UDim2.new(1, -24, 0, 59), UDim2.fromOffset(12, 75 + (index - 1) * 68),
        if index == 1 then RED else if index == 2 then ORANGE else CYAN, 17)
    buildButtons[buildingId] = item
    item.Activated:Connect(function()
        clickSound:Play()
        selection:Fire(buildingId)
    end)
end
text(build, "BuildHint", "Elige, apunta dentro de tu parcela y haz clic. Gira con R.",
    UDim2.new(1, -24, 0, 60), UDim2.fromOffset(12, 286), 15, DARK)

local guide = pageFrame("Guide", CYAN)
local steps = {
    "Tu parcela se asigna al entrar. Busca el cartel con tu nombre.",
    "Compra Carrot Seeds en TIENDA cerca del puesto amarillo.",
    "Planta en el suelo marrón. Espera y cosecha la Carrot.",
    "Abre BOLSA, elige una pila y véndela junto al puesto azul.",
    "Coloca Small Field para plantar más o Chicken Coop para obtener Eggs.",
    "Coins, semillas, inventario, construcciones y producción se guardan.",
}
local stepIndex = 1
local stepNumber = text(guide, "StepNumber", "PASO 1 / " .. #steps,
    UDim2.new(1, -28, 0, 34), UDim2.fromOffset(14, 82), 18, DARK)
local stepText = text(guide, "StepText", steps[stepIndex],
    UDim2.new(1, -28, 0, 145), UDim2.fromOffset(14, 120), 22, DARK)
local nextButton = button(guide, "Next", "SIGUIENTE  ▶",
    UDim2.new(1, -24, 0, 50), UDim2.fromOffset(12, 283), ORANGE, 19)
nextButton.Activated:Connect(function()
    clickSound:Play()
    stepIndex = stepIndex % #steps + 1
    stepNumber.Text = "PASO " .. stepIndex .. " / " .. #steps
    stepText.Text = steps[stepIndex]
end)

local activePage = "Guide"
local function showPage(name: string)
    activePage = if activePage == name then "" else name
    for id, frame in panels do frame.Visible = id == activePage end
    for id, item in navButtons do
        item.BackgroundTransparency = if id == activePage then 0 else 0.15
    end
end
for id, item in navButtons do
    item.Activated:Connect(function()
        clickSound:Play()
        showPage(id)
    end)
end
panels.Guide.Visible = true

local notice = block(gui, "Notice", UDim2.fromOffset(390, 58),
    UDim2.new(0.5, -195, 1, -80), DARK, 12)
notice.Visible = false
local noticeText = text(notice, "Message", "", UDim2.new(1, -20, 1, -8),
    UDim2.fromOffset(10, 4), 17, WHITE)
noticeText.TextXAlignment = Enum.TextXAlignment.Center
local noticeToken = 0
local function showNotice(message: string)
    noticeToken += 1
    local token = noticeToken
    noticeText.Text = message
    notice.Visible = true
    notice.BackgroundTransparency = 0
    task.delay(3, function()
        if noticeToken ~= token then return end
        local tween = TweenService:Create(notice, TweenInfo.new(0.25),
            { BackgroundTransparency = 1 })
        tween:Play()
        tween.Completed:Wait()
        if noticeToken == token then notice.Visible = false end
    end)
end

local errors: { [string]: string } = {
    InsufficientCoins = "No tienes suficientes Coins.",
    InsufficientItems = "No tienes esa cantidad de artículos.",
    InvalidPlotOrDistance = "Acércate al puesto de tu parcela.",
    OutsidePlot = "La construcción debe quedar dentro de tu parcela.",
    Overlapping = "Ese espacio está ocupado.",
    AlreadyOwned = "Ya tienes un Chicken Coop.",
    NoSeeds = "Compra más semillas en TIENDA.",
    DataNotReady = "Tus datos todavía se están cargando.",
    NotReady = "El cultivo todavía está creciendo.",
}
buildRequest.OnClientEvent:Connect(function(ok: boolean, reason: string?)
    clickSound:Play()
    showNotice(if ok then "¡Construcción colocada!" else
        (errors[reason or ""] or "No se pudo colocar: " .. (reason or "Error")))
end)
hudNotice.OnClientEvent:Connect(function(message: string, reason: string?)
    showNotice(if reason then (errors[reason] or message .. ": " .. reason) else message)
end)
modeChanged.Event:Connect(function(selected: string?)
    for id, item in buildButtons do
        item.BackgroundColor3 = if id == selected then Color3.fromRGB(255, 211, 50)
            else if id == "Barn" then RED else if id == "SmallField" then ORANGE else CYAN
    end
end)

local scales = {}
for _, frame in { heading, nav, shop, inventory, build, guide, notice } do
    local scale = Instance.new("UIScale")
    scale.Parent = frame
    table.insert(scales, scale)
end
local lastViewport = Vector2.zero
local function updateLayout()
    local camera = workspace.CurrentCamera
    if not camera or camera.ViewportSize == lastViewport then return end
    lastViewport = camera.ViewportSize
    local scale = math.min(1, math.max(0.55, camera.ViewportSize.X / 850))
    for _, item in scales do item.Scale = scale end
    nav.Position = UDim2.fromOffset(18, 18 + 90 * scale)
    for _, frame in panels do frame.Position = UDim2.fromOffset(18 + 114 * scale, 18 + 90 * scale) end
    notice.Position = UDim2.new(0.5, -195 * scale, 1, -(58 * scale + 22))
end
updateLayout()

task.spawn(function()
    while gui.Parent do
        updateLayout()
        local ok, snapshot = pcall(function() return request:InvokeServer() end)
        if ok and typeof(snapshot) == "table" then
            coins.Text = "💵  " .. tostring(snapshot.Coins) .. " COINS"
            seeds.Text = "🥕  " .. tostring(snapshot.Seeds) .. " SEMILLAS"
            local eggAt = snapshot.EggReadyAt
            eggStatus.Text = if eggAt == nil then "" else if eggAt <= os.time()
                then "🥚 LISTO" else "🥚 " .. tostring(eggAt - os.time()) .. " s"
            renderInventory(snapshot.Inventory or {})
        else
            coins.Text = "💵  CARGANDO..."
        end
        task.wait(1)
    end
end)

local highlights: { [Instance]: Highlight } = {}
task.spawn(function()
    while gui.Parent do
        local folder = workspace:FindFirstChild("RanchPlots")
        if folder then
            for _, slot in folder:GetDescendants() do
                if slot.Name ~= "CropSlot" then continue end
                local variant = slot:GetAttribute("Variant")
                local crop = slot:FindFirstChild("Carrot")
                local current = highlights[slot]
                if (variant == "Golden" or variant == "Rainbow") and crop then
                    if not current then
                        current = Instance.new("Highlight")
                        current.Name = "VariantGlow"
                        current.Adornee = crop
                        current.FillTransparency = 0.72
                        current.OutlineTransparency = 0.1
                        current.Parent = crop
                        highlights[slot] = current
                    end
                    current.OutlineColor = if variant == "Golden"
                        then Color3.fromRGB(255, 215, 45)
                        else Color3.fromHSV((os.clock() * 0.25) % 1, 0.85, 1)
                elseif current then
                    current:Destroy()
                    highlights[slot] = nil
                end
            end
        end
        task.wait(0.2)
    end
end)
