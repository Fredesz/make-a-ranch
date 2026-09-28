--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimalConfig = require(ReplicatedStorage.Shared.Config.AnimalConfig)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local InventoryService = require(script.Parent.InventoryService)
local PlotService = require(script.Parent.PlotService)

type CoopState = { Coop: Part, Hen: Part, Egg: Part? }
local states: { [Player]: CoopState } = {}
local initialized = false
local ChickenService = {}
local chicken = AnimalConfig.Chicken

local function nearCoop(player: Player, coop: Part): boolean
    local character = player.Character
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    return root ~= nil and root:IsA("BasePart")
        and humanoid ~= nil and humanoid.Health > 0
        and (root.Position - coop.Position).Magnitude <= PlotConfig.SellInteractionDistance
end

local function scheduleEgg(player: Player, state: CoopState)
    task.delay(chicken.ProductionTime, function()
        if states[player] ~= state or state.Egg or not state.Coop:IsDescendantOf(workspace) then
            return
        end
        local egg = Instance.new("Part")
        egg.Name = chicken.ProductId
        egg.Anchored = true
        egg.CanCollide = false
        egg.Size = Vector3.new(0.8, 1, 0.8)
        egg.Position = state.Coop.Position + Vector3.new(0,
            state.Coop.Size.Y / 2 + egg.Size.Y / 2, 0)
        egg.Color = chicken.EggColor
        egg.Parent = state.Coop
        state.Egg = egg
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Collect Egg"
        prompt.ObjectText = "Chicken Coop"
        prompt.MaxActivationDistance = PlotConfig.SellInteractionDistance
        prompt.RequiresLineOfSight = false
        prompt.Triggered:Connect(function(actor: Player)
            local ok, reason = ChickenService.Collect(actor, state.Coop)
            local notice = ReplicatedStorage:FindFirstChild("HudNotice")
            if notice and notice:IsA("RemoteEvent") then
                notice:FireClient(actor, if ok then "Egg collected!" else "Collection failed", reason)
            end
        end)
        prompt.Parent = egg
    end)
end

function ChickenService.Collect(player: Player, coop: Instance): (boolean, string?)
    local state = states[player]
    if not state or state.Coop ~= coop or not state.Egg
        or not state.Coop:IsDescendantOf(workspace) or not nearCoop(player, state.Coop) then
        return false, "NotReadyOrNotOwned"
    end
    local added, reason = InventoryService.AddProduct(player, chicken.ProductId, "Normal", 1)
    if not added then return false, reason end
    state.Egg:Destroy()
    state.Egg = nil
    scheduleEgg(player, state)
    return true, nil
end

function ChickenService.RegisterCoop(player: Player, coop: Part): boolean
    if states[player] or coop.Name ~= "ChickenCoop"
        or coop:GetAttribute("OwnerUserId") ~= player.UserId then
        return false
    end
    local plot = PlotService.GetSlot(player)
    if not plot or coop.Parent ~= plot.Parent then return false end
    local hen = Instance.new("Part")
    hen.Name = "Chicken"
    hen.Anchored = true
    hen.CanCollide = false
    hen.Size = Vector3.new(1.5, 1.5, 1.5)
    hen.Position = coop.Position + Vector3.new(0,
        coop.Size.Y / 2 + hen.Size.Y / 2, -1)
    hen.Color = chicken.Color
    hen.Parent = coop
    local state: CoopState = { Coop = coop, Hen = hen, Egg = nil }
    states[player] = state
    scheduleEgg(player, state)
    return true
end

function ChickenService.GetCoop(player: Player): Part?
    local state = states[player]
    return if state then state.Coop else nil
end

function ChickenService.Init()
    if initialized then return end
    initialized = true
    Players.PlayerRemoving:Connect(function(player: Player)
        states[player] = nil
    end)
end

return ChickenService
