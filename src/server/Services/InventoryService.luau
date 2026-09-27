--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CropConfig = require(ReplicatedStorage.Shared.Config.CropConfig)
local VariantConfig = require(ReplicatedStorage.Shared.Config.VariantConfig)
local AnimalConfig = require(ReplicatedStorage.Shared.Config.AnimalConfig)
local PlayerDataService = require(script.Parent.Parent.PlayerDataService)

local InventoryService = {}

local function knownProduct(itemId: string): boolean
    if CropConfig[itemId] ~= nil then return true end
    for _, animal in AnimalConfig do
        if animal.ProductId == itemId then return true end
    end
    return false
end

function InventoryService.GetInventory(player: Player): { PlayerDataService.InventoryEntry }?
    return PlayerDataService.GetInventory(player)
end

-- Server-only entry point. Invalid definitions never enter player data.
function InventoryService.AddCrop(
    player: Player,
    itemId: string,
    variant: string,
    quantity: number
): (boolean, string?)
    if typeof(itemId) ~= "string" or CropConfig[itemId] == nil
        or typeof(variant) ~= "string" or VariantConfig[variant] == nil then
        return false, "UnknownItemOrVariant"
    end
    return PlayerDataService.AddInventoryItem(player, itemId, variant, quantity)
end

function InventoryService.AddProduct(
    player: Player,
    itemId: string,
    variant: string,
    quantity: number
): (boolean, string?)
    if typeof(itemId) ~= "string" or not knownProduct(itemId)
        or typeof(variant) ~= "string" or VariantConfig[variant] == nil then
        return false, "UnknownItemOrVariant"
    end
    return PlayerDataService.AddInventoryItem(player, itemId, variant, quantity)
end

return InventoryService
