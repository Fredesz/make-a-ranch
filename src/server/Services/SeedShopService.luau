--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CropConfig = require(ReplicatedStorage.Shared.Config.CropConfig)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local PlayerDataService = require(script.Parent.Parent.PlayerDataService)
local CropService = require(script.Parent.CropService)
local PlotService = require(script.Parent.PlotService)

local MAX_SAFE_INTEGER = 9007199254740991
local pads: { [Player]: Part } = {}
local initialized = false
local SeedShopService = {}

function SeedShopService.GetPad(player: Player): Part?
    return pads[player]
end

function SeedShopService.Buy(player: Player, cropId: string, quantity: number): (boolean, string?)
    local pad = pads[player]
    if not pad or not pad:IsDescendantOf(workspace) then
        return false, "InvalidPlotOrDistance"
    end
    local character = player.Character
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0
        or (root.Position - pad.Position).Magnitude > PlotConfig.SellInteractionDistance then
        return false, "InvalidPlotOrDistance"
    end
    local crop = if typeof(cropId) == "string" then CropConfig[cropId] else nil
    if not crop or cropId ~= "Carrot" then return false, "UnknownCrop" end
    local seeds = CropService.GetSeeds(player)
    if not seeds then return false, "DataNotFound" end
    if typeof(quantity) ~= "number" or quantity ~= quantity
        or quantity < 1 or quantity % 1 ~= 0
        or quantity > MAX_SAFE_INTEGER - seeds then
        return false, "InvalidQuantity"
    end
    local total = crop.BuyPrice * quantity
    if total > MAX_SAFE_INTEGER or total % 1 ~= 0 then
        return false, "InvalidPrice"
    end
    local paid, reason = PlayerDataService.RemoveCoins(player, total)
    if not paid then return false, reason end
    local added = CropService.AddSeeds(player, quantity)
    assert(added, "Seed balance changed during purchase")
    return true, nil
end

local function createPad(player: Player)
    if pads[player] then return end
    local slot = PlotService.GetSlot(player)
    if not slot then return end
    local pad = slot.Parent:FindFirstChild("SeedShop")
    assert(pad and pad:IsA("Part"), "The permanent SeedShop pad is missing")
    pads[player] = pad
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Buy Carrot Seed"
    prompt.ObjectText = "Seed Shop | " .. CropConfig.Carrot.BuyPrice .. " Coins"
    prompt.MaxActivationDistance = PlotConfig.SellInteractionDistance
    prompt.RequiresLineOfSight = false
    prompt.Triggered:Connect(function(actor: Player)
        if actor ~= player then return end
        local ok, reason = SeedShopService.Buy(actor, "Carrot", 1)
        local notice = ReplicatedStorage:FindFirstChild("HudNotice")
        if notice and notice:IsA("RemoteEvent") then
            notice:FireClient(actor, if ok then "Carrot seed purchased!" else "Seed purchase failed", reason)
        end
    end)
    prompt.Parent = pad
end

function SeedShopService.Init()
    if initialized then return end
    initialized = true
    CropService.Init()
    Players.PlayerAdded:Connect(function(player: Player)
        task.defer(function()
            if player.Parent == Players then createPad(player) end
        end)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        pads[player] = nil
    end)
    for _, player in Players:GetPlayers() do createPad(player) end
end

return SeedShopService
