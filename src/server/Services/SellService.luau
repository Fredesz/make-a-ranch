--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CropConfig = require(ReplicatedStorage.Shared.Config.CropConfig)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local VariantConfig = require(ReplicatedStorage.Shared.Config.VariantConfig)
local PlayerDataService = require(script.Parent.Parent.PlayerDataService)
local InventoryService = require(script.Parent.InventoryService)
local PlotService = require(script.Parent.PlotService)

local MAX_SAFE_INTEGER = 9007199254740991
local pads: { [Player]: Part } = {}
local initialized = false
local SellService = {}

local function nearPad(player: Player): boolean
    local pad = pads[player]
    if not pad or not pad:IsDescendantOf(workspace) then return false end
    local character = player.Character
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    return root ~= nil and root:IsA("BasePart")
        and humanoid ~= nil and humanoid.Health > 0
        and (root.Position - pad.Position).Magnitude <= PlotConfig.SellInteractionDistance
end

function SellService.GetPad(player: Player): Part?
    return pads[player]
end

function SellService.Sell(
    player: Player,
    itemId: string,
    variant: string,
    quantity: number
): (boolean, string?)
    if not nearPad(player) then return false, "InvalidPlotOrDistance" end
    local crop = if typeof(itemId) == "string" then CropConfig[itemId] else nil
    local variantData = if typeof(variant) == "string" then VariantConfig[variant] else nil
    if not crop or not variantData then return false, "UnknownItemOrVariant" end
    if typeof(quantity) ~= "number" or quantity ~= quantity
        or quantity < 1 or quantity % 1 ~= 0 or quantity > MAX_SAFE_INTEGER then
        return false, "InvalidQuantity"
    end
    local unitPrice = crop.SellPrice * variantData.ValueMultiplier
    local totalPrice = unitPrice * quantity
    if totalPrice ~= totalPrice or totalPrice < 0 or totalPrice > MAX_SAFE_INTEGER
        or totalPrice % 1 ~= 0 then
        return false, "InvalidSaleValue"
    end
    return PlayerDataService.SellInventoryItem(player, itemId, variant, quantity, totalPrice)
end

local function createPad(player: Player)
    if pads[player] then return end
    local slot = PlotService.GetSlot(player)
    if not slot then return end
    local pad = slot.Parent:FindFirstChild("SellPad")
    assert(pad and pad:IsA("Part"), "The permanent SellPad is missing")
    pads[player] = pad

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Sell first stack"
    prompt.ObjectText = "Crop Market"
    prompt.MaxActivationDistance = PlotConfig.SellInteractionDistance
    prompt.RequiresLineOfSight = false
    prompt.Triggered:Connect(function(actor: Player)
        if actor ~= player then return end
        local inventory = InventoryService.GetInventory(actor)
        local entry = nil
        for _, candidate in inventory or {} do
            if CropConfig[candidate.ItemId] then
                entry = candidate
                break
            end
        end
        local ok, reason = false, "InsufficientItems"
        if entry then
            ok, reason = SellService.Sell(actor, entry.ItemId, entry.Variant, entry.Quantity)
        end
        local notice = ReplicatedStorage:FindFirstChild("HudNotice")
        if notice and notice:IsA("RemoteEvent") then
            notice:FireClient(actor, if ok then "Items sold!" else "Sale failed", reason)
        end
    end)
    prompt.Parent = pad
end

function SellService.Init()
    if initialized then return end
    initialized = true
    PlotService.Init()
    Players.PlayerAdded:Connect(function(player: Player)
        task.defer(function()
            if player.Parent == Players then createPad(player) end
        end)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        pads[player] = nil -- PlotService destroys the plot and its pad.
    end)
    for _, player in Players:GetPlayers() do createPad(player) end
end

return SellService
