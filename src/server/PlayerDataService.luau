--!strict

local Players = game:GetService("Players")

export type PlayerData = {
    Coins: number,
    Inventory: {},
    Buildings: {},
}

local STARTING_COINS = 100
local MAX_SAFE_INTEGER = 9007199254740991

local dataByPlayer: { [Player]: PlayerData } = {}
local initialized = false
local PlayerDataService = {}

local function createData(player: Player)
    if dataByPlayer[player] then
        return
    end

    dataByPlayer[player] = {
        Coins = STARTING_COINS,
        Inventory = {},
        Buildings = {},
    }
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
        dataByPlayer[player] = nil
    end)

    for _, player in Players:GetPlayers() do
        createData(player)
    end
end

-- Return a snapshot so callers cannot mutate the stored data.
-- Inventory and Buildings remain empty until their respective systems exist.
function PlayerDataService.GetData(player: Player): PlayerData?
    local data = dataByPlayer[player]
    if not data then
        return nil
    end

    return {
        Coins = data.Coins,
        Inventory = table.clone(data.Inventory),
        Buildings = table.clone(data.Buildings),
    }
end

function PlayerDataService.GetCoins(player: Player): number?
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
    if amount > data.Coins then
        return false, "InsufficientCoins"
    end

    data.Coins -= amount
    return true, nil
end

return PlayerDataService
