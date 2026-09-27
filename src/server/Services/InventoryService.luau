--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CropConfig = require(ReplicatedStorage.Shared.Config.CropConfig)
local VariantConfig = require(ReplicatedStorage.Shared.Config.VariantConfig)
local PlayerDataService = require(script.Parent.Parent.PlayerDataService)

local InventoryService = {}

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

return InventoryService
