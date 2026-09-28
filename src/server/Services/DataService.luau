--!strict

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimalConfig = require(ReplicatedStorage.Shared.Config.AnimalConfig)
local BuildingConfig = require(ReplicatedStorage.Shared.Config.BuildingConfig)
local CropConfig = require(ReplicatedStorage.Shared.Config.CropConfig)
local DataConfig = require(ReplicatedStorage.Shared.Config.DataConfig)
local VariantConfig = require(ReplicatedStorage.Shared.Config.VariantConfig)
local PlayerDataService = require(script.Parent.Parent.PlayerDataService)
local BuildService = require(script.Parent.BuildService)
local CropService = require(script.Parent.CropService)

local MAX_SAFE_INTEGER = 9007199254740991
local store: GlobalDataStore? = nil
local loaded: { [Player]: boolean } = {}
local initialized = false
local DataService = {}

local function getStore(): GlobalDataStore
    if not store then
        store = DataStoreService:GetDataStore(DataConfig.StoreName)
    end
    return store
end

local function validWhole(value: any): boolean
    return typeof(value) == "number" and value == value
        and value >= 0 and value <= MAX_SAFE_INTEGER and value % 1 == 0
end

local function knownItem(itemId: string): boolean
    if CropConfig[itemId] then return true end
    for _, animal in AnimalConfig do
        if animal.ProductId == itemId then return true end
    end
    return false
end

local function sanitize(raw: any): PlayerDataService.PlayerData?
    if typeof(raw) ~= "table" or not validWhole(raw.Coins) then return nil end
    if raw.Seeds ~= nil and not validWhole(raw.Seeds) then return nil end
    local data: PlayerDataService.PlayerData = {
        Coins = raw.Coins,
        Seeds = if raw.Seeds == nil then CropConfig.Carrot.StartingSeeds else raw.Seeds,
        Inventory = {},
        Buildings = {},
    }
    if typeof(raw.Inventory) == "table" then
        for _, entry in raw.Inventory do
            if typeof(entry) == "table" and typeof(entry.ItemId) == "string"
                and knownItem(entry.ItemId) and typeof(entry.Variant) == "string"
                and VariantConfig[entry.Variant] and validWhole(entry.Quantity)
                and entry.Quantity > 0 then
                table.insert(data.Inventory, {
                    ItemId = entry.ItemId,
                    Variant = entry.Variant,
                    Quantity = entry.Quantity,
                })
            end
        end
    end
    if typeof(raw.Buildings) == "table" then
        for _, entry in raw.Buildings do
            if typeof(entry) == "table" and typeof(entry.BuildingId) == "string"
                and BuildingConfig[entry.BuildingId]
                and typeof(entry.GridX) == "number" and entry.GridX == entry.GridX
                and typeof(entry.GridZ) == "number" and entry.GridZ == entry.GridZ
                and entry.GridX % 1 == 0 and entry.GridZ % 1 == 0
                and math.abs(entry.GridX) <= 1000 and math.abs(entry.GridZ) <= 1000
                and typeof(entry.Rotation) == "number"
                and entry.Rotation >= 0 and entry.Rotation < 360
                and entry.Rotation % 90 == 0 then
                table.insert(data.Buildings, {
                    BuildingId = entry.BuildingId,
                    GridX = entry.GridX,
                    GridZ = entry.GridZ,
                    Rotation = entry.Rotation,
                })
            end
        end
    end
    return data
end

function DataService.Load(player: Player): (boolean, string?)
    if game.GameId == 0 and RunService:IsStudio() then
        return false, "Publish a test experience before enabling DataStore"
    end
    local ok, raw = pcall(function()
        return getStore():GetAsync(DataConfig.KeyPrefix .. player.UserId)
    end)
    if not ok then return false, tostring(raw) end
    CropService.EnsureSession(player)
    if raw ~= nil then
        local data = sanitize(raw)
        if not data then return false, "InvalidSavedData" end
        if not PlayerDataService.LoadData(player, data) then
            return false, "PlayerLeftDuringLoad"
        end
        BuildService.Restore(player)
    end
    PlayerDataService.SetReady(player, true)
    CropService.RefreshSeeds(player)
    loaded[player] = true
    return true, nil
end

function DataService.Save(player: Player): (boolean, string?)
    if not loaded[player] then return false, "DataNotLoaded" end
    local snapshot = PlayerDataService.GetData(player)
    if not snapshot then return false, "DataNotFound" end
    local ok, err = pcall(function()
        getStore():UpdateAsync(DataConfig.KeyPrefix .. player.UserId, function(_old)
            return snapshot
        end)
    end)
    if not ok then return false, tostring(err) end
    return true, nil
end

function DataService.GetStatus(player: Player): string
    return if loaded[player] then "Loaded" else "Unavailable"
end

function DataService.Init()
    if initialized then return end
    initialized = true
    PlayerDataService.Init()
    PlayerDataService.EnableLoadGate()
    BuildService.Init()
    PlayerDataService.SetBeforeRemove(function(player: Player)
        local ok, reason = DataService.Save(player)
        if not ok and reason ~= "DataNotLoaded" then
            warn("Player data save failed:", player.UserId, reason)
        end
        loaded[player] = nil
    end)
    Players.PlayerAdded:Connect(function(player: Player)
        task.defer(function()
            if player.Parent ~= Players then return end
            local ok, reason = DataService.Load(player)
            if not ok then
                PlayerDataService.SetReady(player, true)
                CropService.RefreshSeeds(player)
                warn("Player data load unavailable:", player.UserId, reason)
            end
        end)
    end)
    for _, player in Players:GetPlayers() do
        task.defer(function()
            if player.Parent == Players then
                local ok, reason = DataService.Load(player)
                if not ok then
                    PlayerDataService.SetReady(player, true)
                    CropService.RefreshSeeds(player)
                    warn("Player data load unavailable:", player.UserId, reason)
                end
            end
        end)
    end
    game:BindToClose(function()
        for _, player in Players:GetPlayers() do
            local ok, reason = DataService.Save(player)
            if not ok and reason ~= "DataNotLoaded" then
                warn("Shutdown save failed:", player.UserId, reason)
            end
        end
    end)
end

return DataService
