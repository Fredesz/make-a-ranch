--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)

type Plot = { Model: Model, Slot: Part, Index: number }
local plots: { [Player]: Plot } = {}
local usedIndices: { [number]: boolean } = {}
local initialized = false
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

    local model = Instance.new("Model")
    model.Name = "Plot_" .. player.UserId
    model:SetAttribute("OwnerUserId", player.UserId)

    local ground = Instance.new("Part")
    ground.Name = "Ground"
    ground.Anchored = true
    ground.Size = PlotConfig.GroundSize
    ground.Position = PlotConfig.Origin + Vector3.new((index - 1) * PlotConfig.Spacing, 0, 0)
    ground.Color = PlotConfig.GroundColor
    ground.Parent = model

    local slot = Instance.new("Part")
    slot.Name = "CropSlot"
    slot.Anchored = true
    slot.Size = PlotConfig.SoilSize
    slot.Position = ground.Position + Vector3.new(0, (ground.Size.Y + slot.Size.Y) / 2, 0)
    slot.Color = PlotConfig.SoilColor
    slot.Parent = model

    plots[player] = { Model = model, Slot = slot, Index = index }
    model.Parent = container
end

function PlotService.GetSlot(player: Player): Part?
    local plot = plots[player]
    return if plot then plot.Slot else nil
end

function PlotService.OwnsSlot(player: Player, slot: Instance): boolean
    local plot = plots[player]
    return plot ~= nil and plot.Slot == slot and slot:IsDescendantOf(workspace)
end

function PlotService.Init()
    if initialized then
        return
    end
    initialized = true

    local container = Instance.new("Folder")
    container.Name = "RanchPlots"
    container.Parent = workspace

    Players.PlayerAdded:Connect(function(player: Player)
        assignPlot(player, container)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        local plot = plots[player]
        if plot then
            plots[player] = nil
            usedIndices[plot.Index] = nil
            plot.Model:Destroy()
        end
    end)
    for _, player in Players:GetPlayers() do
        assignPlot(player, container)
    end
end

return PlotService
