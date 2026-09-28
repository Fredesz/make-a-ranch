--!strict

local Players = game:GetService("Players")

type Plot = { Model: Model, Slot: Part, Index: number }
local plots: { [Player]: Plot } = {}
local usedIndices: { [number]: boolean } = {}
local initialized = false
local templates: { Model } = {}
local PlotService = {}

local function updateSign(model: Model, index: number, player: Player)
    local sign = model:FindFirstChild("OwnerSign")
    assert(sign, "The plot owner sign is missing")
    for _, descendant in sign:GetDescendants() do
        if descendant:IsA("TextLabel") and descendant.Name == "OwnerText" then
            descendant.Text = string.format("Parcela %d\n%s", index, player.DisplayName)
            descendant.TextScaled = true
        end
    end
end

local function assignPlot(player: Player, container: Folder)
    if plots[player] then
        return
    end

    local index = 1
    while index <= #templates and usedIndices[index] do
        index += 1
    end
    if index > #templates then
        player:Kick("Todas las parcelas están ocupadas. Intenta entrar en otro servidor.")
        return
    end
    usedIndices[index] = true

    local model = container:FindFirstChild("Plot_" .. index)
    assert(model and model:IsA("Model"), "The permanent plot is missing")
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("OwnerName", player.Name)
    updateSign(model, index, player)
    local spawn = workspace:FindFirstChild("RanchSpawn")
    if spawn and spawn:IsA("SpawnLocation") then
        player.RespawnLocation = spawn
    end
    local slot = model:FindFirstChild("CropSlot")
    assert(slot and slot:IsA("Part"), "The plot crop slot is missing")
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant:SetAttribute("OwnerUserId", player.UserId)
        end
    end

    plots[player] = { Model = model, Slot = slot, Index = index }
    model.Parent = container
end

function PlotService.GetSlot(player: Player): Part?
    local plot = plots[player]
    return if plot then plot.Slot else nil
end

function PlotService.OwnsSlot(player: Player, slot: Instance): boolean
    local plot = plots[player]
    return plot ~= nil and (plot.Slot == slot
        or (slot.Name == "CropSlot" and slot:GetAttribute("FieldSlot") == true
            and slot.Parent == plot.Model))
        and slot:IsDescendantOf(workspace)
end

function PlotService.Init()
    if initialized then
        return
    end
    initialized = true

    local container = workspace:WaitForChild("RanchPlots") :: Folder
    for _, model in container:GetChildren() do
        assert(model:IsA("Model"), "RanchPlots children must be Models")
        local index = model:GetAttribute("PlotIndex")
        assert(typeof(index) == "number" and index >= 1 and index % 1 == 0,
            "Each plot needs a positive PlotIndex")
        assert(not templates[index], "Duplicate PlotIndex")
        for _, name in { "Ground", "CropSlot", "SeedShop", "SellPad", "OwnerSign" } do
            assert(model:FindFirstChild(name), "Plot is missing " .. name)
        end
        templates[index] = model:Clone()
    end
    assert(#templates == #container:GetChildren(), "Plot indices must be consecutive")
    assert(#templates > 0, "No ranch plots found")

    Players.PlayerAdded:Connect(function(player: Player)
        assignPlot(player, container)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        local plot = plots[player]
        if plot then
            plots[player] = nil
            usedIndices[plot.Index] = nil
            plot.Model:Destroy()
            local replacement = templates[plot.Index]:Clone()
            replacement.Parent = container
        end
    end)
    for _, player in Players:GetPlayers() do
        assignPlot(player, container)
    end
end

return PlotService
