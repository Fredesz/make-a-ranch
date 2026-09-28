--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local BuildingConfig = require(ReplicatedStorage.Shared.Config.BuildingConfig)
local request = ReplicatedStorage:WaitForChild("GetHudState") :: RemoteFunction
local buildRequest = ReplicatedStorage:WaitForChild("BuildRequest") :: RemoteEvent
local hudNotice = ReplicatedStorage:WaitForChild("HudNotice") :: RemoteEvent
local selection = script.Parent:WaitForChild("BuildSelection") :: BindableEvent
local modeChanged = script.Parent:WaitForChild("BuildModeChanged") :: BindableEvent

local gui = Instance.new("ScreenGui")
gui.Name = "RanchHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function panel(name: string, size: UDim2, position: UDim2): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = Color3.fromRGB(29, 45, 39)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(106, 153, 110)
    stroke.Thickness = 2
    stroke.Parent = frame
    return frame
end

local function label(parent: Instance, name: string, text: string, size: UDim2,
    position: UDim2, fontSize: number): TextLabel
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Size = size
    item.Position = position
    item.BackgroundTransparency = 1
    item.Font = Enum.Font.GothamMedium
    item.Text = text
    item.TextColor3 = Color3.fromRGB(247, 246, 220)
    item.TextSize = fontSize
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Parent = parent
    return item
end

local function button(parent: Instance, name: string, text: string, size: UDim2,
    position: UDim2): TextButton
    local item = Instance.new("TextButton")
    item.Name = name
    item.Size = size
    item.Position = position
    item.BackgroundColor3 = Color3.fromRGB(82, 128, 76)
    item.BorderSizePixel = 0
    item.Font = Enum.Font.GothamBold
    item.Text = text
    item.TextColor3 = Color3.fromRGB(255, 255, 245)
    item.TextSize = 14
    item.TextWrapped = true
    item.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = item
    return item
end

local clickSound = Instance.new("Sound")
clickSound.Name = "RanchClick"
clickSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
clickSound.Volume = 0.35
clickSound.Parent = SoundService

local stats = panel("Stats", UDim2.fromOffset(260, 116), UDim2.fromOffset(18, 18))
label(stats, "Title", "MAKE A RANCH", UDim2.new(1, -24, 0, 27),
    UDim2.fromOffset(12, 8), 19)
local coins = label(stats, "Coins", "Coins: ...", UDim2.new(1, -24, 0, 28),
    UDim2.fromOffset(12, 42), 17)
local seeds = label(stats, "Seeds", "Seeds: ...", UDim2.new(1, -24, 0, 28),
    UDim2.fromOffset(12, 75), 16)

local bag = panel("Bag", UDim2.fromOffset(260, 115), UDim2.fromOffset(18, 145))
label(bag, "Title", "INVENTORY", UDim2.new(1, -24, 0, 26),
    UDim2.fromOffset(12, 8), 16)
local bagContents = label(bag, "Contents", "Empty", UDim2.new(1, -24, 1, -44),
    UDim2.fromOffset(12, 37), 14)
bagContents.TextYAlignment = Enum.TextYAlignment.Top

local build = panel("Build", UDim2.fromOffset(285, 205),
    UDim2.new(0, 18, 1, -223))
label(build, "Title", "BUILD  •  rotate with R", UDim2.new(1, -24, 0, 26),
    UDim2.fromOffset(12, 8), 15)
local buildButtons: { [string]: TextButton } = {}
for index, buildingId in { "Barn", "SmallField", "ChickenCoop" } do
    local definition = BuildingConfig[buildingId]
    local item = button(build, buildingId,
        definition.DisplayName .. "  •  " .. definition.Price .. " Coins",
        UDim2.new(1, -24, 0, 42), UDim2.fromOffset(12, 35 + (index - 1) * 51))
    buildButtons[buildingId] = item
    item.Activated:Connect(function()
        clickSound:Play()
        selection:Fire(buildingId)
    end)
end
label(build, "Hint", "Select, point inside your plot, click to place.",
    UDim2.new(1, -24, 0, 19), UDim2.fromOffset(12, 187), 11)

local tutorial = panel("Tutorial", UDim2.fromOffset(300, 158),
    UDim2.new(1, -318, 0, 18))
label(tutorial, "Title", "RANCH GUIDE", UDim2.new(1, -24, 0, 26),
    UDim2.fromOffset(12, 8), 16)
local steps = {
    "Walk to the yellow pad to buy Carrot seeds.",
    "Use the soil prompt to plant, then wait for growth.",
    "Harvest and check your inventory above.",
    "Sell crops at the blue pad for Coins.",
    "Build a Small Field or Chicken Coop on your plot.",
    "Collect eggs from the coop. Progress saves when you leave.",
}
local stepIndex = 1
local stepText = label(tutorial, "Step", steps[stepIndex],
    UDim2.new(1, -24, 0, 66), UDim2.fromOffset(12, 39), 14)
local nextButton = button(tutorial, "Next", "NEXT", UDim2.fromOffset(92, 31),
    UDim2.new(1, -104, 1, -40))
nextButton.Activated:Connect(function()
    clickSound:Play()
    stepIndex = stepIndex % #steps + 1
    stepText.Text = steps[stepIndex]
end)

local notice = panel("Notice", UDim2.fromOffset(340, 54),
    UDim2.new(0.5, -170, 1, -78))
notice.Visible = false
local noticeText = label(notice, "Message", "", UDim2.new(1, -24, 1, -12),
    UDim2.fromOffset(12, 6), 15)
noticeText.TextXAlignment = Enum.TextXAlignment.Center
local scaledPanels = { stats, bag, build, tutorial, notice }
local panelScales = {}
for _, frame in scaledPanels do
    local scale = Instance.new("UIScale")
    scale.Parent = frame
    table.insert(panelScales, scale)
end
local lastViewport = Vector2.zero
local function updateLayout()
    local camera = workspace.CurrentCamera
    if not camera or camera.ViewportSize == lastViewport then return end
    lastViewport = camera.ViewportSize
    local scale = math.min(1, math.max(0.55, camera.ViewportSize.X / 650))
    for _, item in panelScales do item.Scale = scale end
    bag.Position = UDim2.fromOffset(18, 18 + 127 * scale)
    build.Position = UDim2.new(0, 18, 1, -(205 * scale + 18))
    tutorial.Position = UDim2.new(1, -(300 * scale + 18), 0, 18)
    notice.Position = UDim2.new(0.5, -170 * scale, 1, -(54 * scale + 24))
end
updateLayout()
local noticeToken = 0
local function showNotice(message: string)
    noticeToken += 1
    local token = noticeToken
    noticeText.Text = message
    notice.Visible = true
    notice.BackgroundTransparency = 0.08
    task.delay(3, function()
        if noticeToken ~= token then return end
        local tween = TweenService:Create(notice, TweenInfo.new(0.3),
            { BackgroundTransparency = 1 })
        tween:Play()
        tween.Completed:Wait()
        if noticeToken == token then notice.Visible = false end
    end)
end

local errors: { [string]: string } = {
    InsufficientCoins = "Not enough Coins.",
    OutsidePlot = "Place the building inside your plot.",
    Overlapping = "That space is occupied.",
    InvalidPlot = "Wait for your plot to load.",
    AlreadyOwned = "You already have a Chicken Coop.",
    InvalidPlotOrDistance = "Move closer to your own ranch station.",
    NoSeeds = "Buy more Carrot seeds at the yellow pad.",
    NotReady = "This crop is still growing.",
    DataNotReady = "Your ranch data is still loading.",
    InsufficientItems = "You do not have enough items to sell.",
}
buildRequest.OnClientEvent:Connect(function(ok: boolean, reason: string?)
    clickSound:Play()
    showNotice(if ok then "Building placed!" else
        (errors[reason or ""] or "Could not place building: " .. (reason or "Unknown")))
end)
hudNotice.OnClientEvent:Connect(function(message: string, reason: string?)
    showNotice(if reason then (errors[reason] or message .. ": " .. reason) else message)
end)

modeChanged.Event:Connect(function(selected: string?)
    for id, item in buildButtons do
        item.BackgroundColor3 = if id == selected then Color3.fromRGB(195, 149, 53)
            else Color3.fromRGB(82, 128, 76)
    end
end)

task.spawn(function()
    while gui.Parent do
        updateLayout()
        local ok, snapshot = pcall(function()
            return request:InvokeServer()
        end)
        if ok and typeof(snapshot) == "table" then
            coins.Text = "Coins: " .. tostring(snapshot.Coins)
            seeds.Text = "Carrot seeds: " .. tostring(snapshot.Seeds)
            local lines = {}
            for index, entry in snapshot.Inventory do
                if index > 3 then
                    table.insert(lines, "+ " .. tostring(#snapshot.Inventory - 3) .. " more")
                    break
                end
                table.insert(lines, entry.ItemId .. " (" .. entry.Variant .. ") × "
                    .. tostring(entry.Quantity))
            end
            bagContents.Text = if #lines > 0 then table.concat(lines, "\n") else "Empty"
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
        task.wait(0.1)
    end
end)
