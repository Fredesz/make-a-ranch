--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)

type Plot = { Model: Model, Slot: Part, Index: number }
local plots: { [Player]: Plot } = {}
local usedIndices: { [number]: boolean } = {}
local initialized = false
local template: Model? = nil
local PlotService = {}

local function assignPlot(player: Player, container: Folder)
    if plots[player] then
        return
    end

    local index = 1
    while usedIndices[index] do
        index += 1
    end
    usedIndices[index] = true

    local model: Model
    if index == 1 then
        local first = container:FindFirstChild("Plot_1")
        assert(first and first:IsA("Model"), "The permanent Plot_1 is missing")
        model = first
    else
        assert(template, "Plot template is missing")
        model = template:Clone()
        local offset = Vector3.new((index - 1) * PlotConfig.Spacing, 0, 0)
        for _, descendant in model:GetDescendants() do
            if descendant:IsA("BasePart") then
                descendant.Position += offset
            end
        end
    end
    model.Name = "Plot_" .. player.UserId
    model:SetAttribute("OwnerUserId", player.UserId)
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
    local first = container:WaitForChild("Plot_1")
    assert(first:IsA("Model"), "RanchPlots.Plot_1 must be a Model")
    for _, name in { "Ground", "CropSlot", "SeedShop", "SellPad" } do
        assert(first:FindFirstChild(name), "Plot_1 is missing " .. name)
    end
    template = first:Clone()
    template.Parent = nil

    Players.PlayerAdded:Connect(function(player: Player)
        assignPlot(player, container)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        local plot = plots[player]
        if plot then
            plots[player] = nil
            usedIndices[plot.Index] = nil
            plot.Model:Destroy()
            if plot.Index == 1 then
                assert(template, "Plot template is missing")
                local replacement = template:Clone()
                replacement.Name = "Plot_1"
                replacement.Parent = container
            end
        end
    end)
    for _, player in Players:GetPlayers() do
        assignPlot(player, container)
    end
end

return PlotService
