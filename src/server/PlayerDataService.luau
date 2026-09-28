--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CropConfig = require(ReplicatedStorage.Shared.Config.CropConfig)

export type InventoryEntry = {
    ItemId: string,
    Variant: string,
    Quantity: number,
}

export type PlayerData = {
    Coins: number,
    Seeds: number,
    Inventory: { InventoryEntry },
    Buildings: { BuildingEntry },
}

export type BuildingEntry = {
    BuildingId: string,
    GridX: number,
    GridZ: number,
    Rotation: number,
}

local STARTING_COINS = 100
local MAX_SAFE_INTEGER = 9007199254740991

local dataByPlayer: { [Player]: PlayerData } = {}
local readyByPlayer: { [Player]: boolean } = {}
local loadGateEnabled = false
local initialized = false
local PlayerDataService = {}
local beforeRemove: ((Player) -> ())? = nil

local function copyInventory(inventory: { InventoryEntry }): { InventoryEntry }
    local result: { InventoryEntry } = {}
    for _, entry in inventory do
        table.insert(result, {
            ItemId = entry.ItemId,
            Variant = entry.Variant,
            Quantity = entry.Quantity,
        })
    end
    return result
end

local function copyBuildings(buildings: { BuildingEntry }): { BuildingEntry }
    local result: { BuildingEntry } = {}
    for _, entry in buildings do
        table.insert(result, {
            BuildingId = entry.BuildingId,
            GridX = entry.GridX,
            GridZ = entry.GridZ,
            Rotation = entry.Rotation,
        })
    end
    return result
end

local function createData(player: Player)
    if dataByPlayer[player] then
        return
    end

    dataByPlayer[player] = {
        Coins = STARTING_COINS,
        Seeds = CropConfig.Carrot.StartingSeeds,
        Inventory = {},
        Buildings = {},
    }
    readyByPlayer[player] = not loadGateEnabled
end

local function isValidAmount(amount: number): boolean
    return typeof(amount) == "number"
        and amount == amount
        and amount >= 0
        and amount <= MAX_SAFE_INTEGER
        and amount % 1 == 0
end

function PlayerDataService.Init()
    if initialized then
        return
    end
    initialized = true

    Players.PlayerAdded:Connect(createData)
    Players.PlayerRemoving:Connect(function(player: Player)
        if beforeRemove then beforeRemove(player) end
        dataByPlayer[player] = nil
        readyByPlayer[player] = nil
    end)

    for _, player in Players:GetPlayers() do
        createData(player)
    end
end

function PlayerDataService.EnableLoadGate()
    loadGateEnabled = true
    for player in dataByPlayer do readyByPlayer[player] = false end
end

function PlayerDataService.SetReady(player: Player, ready: boolean)
    if dataByPlayer[player] then readyByPlayer[player] = ready end
end

function PlayerDataService.IsReady(player: Player): boolean
    return readyByPlayer[player] == true
end

function PlayerDataService.SetBeforeRemove(callback: (Player) -> ())
    beforeRemove = callback
end

function PlayerDataService.LoadData(player: Player, snapshot: PlayerData): boolean
    if not dataByPlayer[player] then return false end
    dataByPlayer[player] = {
        Coins = snapshot.Coins,
        Seeds = snapshot.Seeds,
        Inventory = copyInventory(snapshot.Inventory),
        Buildings = copyBuildings(snapshot.Buildings),
    }
    return true
end

-- Return a snapshot so callers cannot mutate the stored data.
function PlayerDataService.GetData(player: Player): PlayerData?
    if not PlayerDataService.IsReady(player) then return nil end
    local data = dataByPlayer[player]
    if not data then
        return nil
    end

    return {
        Coins = data.Coins,
        Seeds = data.Seeds,
        Inventory = copyInventory(data.Inventory),
        Buildings = copyBuildings(data.Buildings),
    }
end

function PlayerDataService.GetSeeds(player: Player): number?
    if not PlayerDataService.IsReady(player) then return nil end
    local data = dataByPlayer[player]
    return if data then data.Seeds else nil
end

function PlayerDataService.AddSeeds(player: Player, quantity: number): (boolean, string?)
    if not isValidAmount(quantity) or quantity == 0 then return false, "InvalidQuantity" end
    local data = dataByPlayer[player]
    if not data then return false, "DataNotFound" end
    if not PlayerDataService.IsReady(player) then return false, "DataNotReady" end
    if quantity > MAX_SAFE_INTEGER - data.Seeds then return false, "QuantityLimitExceeded" end
    data.Seeds += quantity
    return true, nil
end

function PlayerDataService.ConsumeSeed(player: Player): (boolean, string?)
    local data = dataByPlayer[player]
    if not data then return false, "DataNotFound" end
    if not PlayerDataService.IsReady(player) then return false, "DataNotReady" end
    if data.Seeds == 0 then return false, "NoSeeds" end
    data.Seeds -= 1
    return true, nil
end

function PlayerDataService.GetBuildings(player: Player): { BuildingEntry }?
    local data = dataByPlayer[player]
    return if data then copyBuildings(data.Buildings) else nil
end

-- The caller validates placement; this records it and charges atomically.
function PlayerDataService.PurchaseBuilding(
    player: Player,
    entry: BuildingEntry,
    price: number
): (boolean, string?)
    if not isValidAmount(price) then return false, "InvalidPrice" end
    local data = dataByPlayer[player]
    if not data then return false, "DataNotFound" end
    if not PlayerDataService.IsReady(player) then return false, "DataNotReady" end
    if data.Coins < price then return false, "InsufficientCoins" end
    data.Coins -= price
    table.insert(data.Buildings, {
        BuildingId = entry.BuildingId,
        GridX = entry.GridX,
        GridZ = entry.GridZ,
        Rotation = entry.Rotation,
    })
    return true, nil
end

function PlayerDataService.GetInventory(player: Player): { InventoryEntry }?
    if not PlayerDataService.IsReady(player) then return nil end
    local data = dataByPlayer[player]
    return if data then copyInventory(data.Inventory) else nil
end

-- Called only by server services after they validate the item definition.
function PlayerDataService.AddInventoryItem(
    player: Player,
    itemId: string,
    variant: string,
    quantity: number
): (boolean, string?)
    if typeof(itemId) ~= "string" or itemId == ""
        or typeof(variant) ~= "string" or variant == ""
        or not isValidAmount(quantity) or quantity == 0 then
        return false, "InvalidItem"
    end

    local data = dataByPlayer[player]
    if not data then
        return false, "DataNotFound"
    end
    if not PlayerDataService.IsReady(player) then return false, "DataNotReady" end
    for _, entry in data.Inventory do
        if entry.ItemId == itemId and entry.Variant == variant then
            if quantity > MAX_SAFE_INTEGER - entry.Quantity then
                return false, "QuantityLimitExceeded"
            end
            entry.Quantity += quantity
            return true, nil
        end
    end
    table.insert(data.Inventory, { ItemId = itemId, Variant = variant, Quantity = quantity })
    return true, nil
end

-- Check and apply inventory removal and coin credit without yielding.
function PlayerDataService.SellInventoryItem(
    player: Player,
    itemId: string,
    variant: string,
    quantity: number,
    totalPrice: number
): (boolean, string?)
    if typeof(itemId) ~= "string" or typeof(variant) ~= "string"
        or not isValidAmount(quantity) or quantity == 0
        or not isValidAmount(totalPrice) then
        return false, "InvalidSale"
    end
    local data = dataByPlayer[player]
    if not data then return false, "DataNotFound" end
    if not PlayerDataService.IsReady(player) then return false, "DataNotReady" end
    local index: number? = nil
    for i, entry in data.Inventory do
        if entry.ItemId == itemId and entry.Variant == variant then
            index = i
            break
        end
    end
    if not index or data.Inventory[index].Quantity < quantity then
        return false, "InsufficientItems"
    end
    if totalPrice > MAX_SAFE_INTEGER - data.Coins then
        return false, "BalanceLimitExceeded"
    end
    data.Inventory[index].Quantity -= quantity
    if data.Inventory[index].Quantity == 0 then
        table.remove(data.Inventory, index)
    end
    data.Coins += totalPrice
    return true, nil
end

function PlayerDataService.GetCoins(player: Player): number?
    if not PlayerDataService.IsReady(player) then return nil end
    local data = dataByPlayer[player]
    return if data then data.Coins else nil
end

-- Failed operations leave the balance unchanged and return a reason.
function PlayerDataService.AddCoins(player: Player, amount: number): (boolean, string?)
    if not isValidAmount(amount) then
        return false, "InvalidAmount"
    end

    local data = dataByPlayer[player]
    if not data then
        return false, "DataNotFound"
    end
    if not PlayerDataService.IsReady(player) then return false, "DataNotReady" end
    if amount > MAX_SAFE_INTEGER - data.Coins then
        return false, "BalanceLimitExceeded"
    end

    data.Coins += amount
    return true, nil
end

function PlayerDataService.RemoveCoins(player: Player, amount: number): (boolean, string?)
    if not isValidAmount(amount) then
        return false, "InvalidAmount"
    end

    local data = dataByPlayer[player]
    if not data then
        return false, "DataNotFound"
    end
    if not PlayerDataService.IsReady(player) then return false, "DataNotReady" end
    if amount > data.Coins then
        return false, "InsufficientCoins"
    end

    data.Coins -= amount
    return true, nil
end

return PlayerDataService
