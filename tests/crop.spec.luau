
CropService.Init()
CropService.Init()
SellService.Init()
SeedShopService.Init()
local farmer = join(10)
local intruder = join(11)
advance(0)
local soil = PlotService.GetSlot(farmer)
local function standAt(player, position)
    local character = Instance.new("Model")
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Position = position
    root.Parent = character
    local humanoid = Instance.new("Humanoid")
    humanoid.Health = 100
    humanoid.Parent = character
    player.Character = character
end
standAt(farmer, soil.Position)
standAt(intruder, soil.Position)
assert(CropService.GetSeeds(farmer) == CropConfig.Carrot.StartingSeeds)
assert(not CropService.Plant(intruder, soil))
assert(not CropService.Plant(farmer, Instance.new("Part")))
standAt(farmer, soil.Position + Vector3.new(100, 0, 0))
assert(not CropService.Plant(farmer, soil))
standAt(farmer, soil.Position)
farmer.Character:FindFirstChildOfClass("Humanoid").Health = 0
assert(not CropService.Plant(farmer, soil))
standAt(farmer, soil.Position)

for cycle = 1, 10 do
    local expected = if cycle % 3 == 1 then "Golden" else if cycle % 3 == 2 then "Normal" else "Rainbow"
    queueDraw(if expected == "Golden" then 1 else if expected == "Normal" then 6 else 100)
    -- First cycle uses the actual prompt callback, later cycles the same server API.
    if cycle == 1 then
        soil:FindFirstChild("CropInteraction").Triggered:Fire(farmer)
    else
        assert(CropService.Plant(farmer, soil))
    end
    assert(soil:GetAttribute("CropState") == "Growing")
    assert(soil:GetAttribute("GrowthStage") == 1)
    assert(CropService.GetSeeds(farmer) == CropConfig.Carrot.StartingSeeds - cycle)
    assert(not CropService.Plant(farmer, soil))
    assert(not CropService.Harvest(farmer, soil))
    -- Forging the replicated state cannot bypass the server clock.
    soil:SetAttribute("CropState", "Ready")
    assert(not CropService.Harvest(farmer, soil))
    advance(CropConfig.Carrot.GrowthTime / 3)
    assert(soil:GetAttribute("GrowthStage") == 2)
    advance(CropConfig.Carrot.GrowthTime / 3)
    assert(soil:GetAttribute("GrowthStage") == 3)
    assert(not CropService.Harvest(farmer, soil))
    advance(CropConfig.Carrot.GrowthTime / 3)
    assert(soil:GetAttribute("CropState") == "Ready")
    assert(soil:GetAttribute("Variant") == expected)
    assert(soil:FindFirstChild("Carrot").Color == VariantConfig[expected].ReadyColor)
    assert(not CropService.Harvest(intruder, soil))
    local ok, harvestedId, variantId = CropService.Harvest(farmer, soil)
    assert(ok and harvestedId == "Carrot" and variantId == expected)
    assert(soil:GetAttribute("CropState") == "Empty")
    assert(soil:GetAttribute("Variant") == nil)
    assert(soil:FindFirstChild("Carrot") == nil)
    assert(not CropService.Harvest(farmer, soil))
    local inventory = InventoryService.GetInventory(farmer)
    local entryCount = 0
    for _, entry in inventory do
        assert(entry.ItemId == "Carrot")
        assert(VariantConfig[entry.Variant] ~= nil)
        entryCount += entry.Quantity
    end
    assert(entryCount == cycle)
end
local planted, reason = CropService.Plant(farmer, soil)
assert(not planted and reason == "NoSeeds")
assert(PlayerDataService.GetCoins(farmer) == 100)
local byVariant = {}
for _, entry in InventoryService.GetInventory(farmer) do
    byVariant[entry.Variant] = entry.Quantity
end
assert(byVariant.Golden == 4 and byVariant.Normal == 3 and byVariant.Rainbow == 3)
assert(#InventoryService.GetInventory(farmer) == 3)
assert(not InventoryService.AddCrop(farmer, "FakeCrop", "Normal", 1))
assert(not InventoryService.AddCrop(farmer, "Carrot", "FakeVariant", 1))
assert(not InventoryService.AddCrop(farmer, "Carrot", "Normal", 0))
assert(not InventoryService.AddCrop(farmer, "Carrot", "Normal", -1))
assert(not InventoryService.AddCrop(farmer, "Carrot", "Normal", 0/0))
local snapshot = InventoryService.GetInventory(farmer)
snapshot[1].Quantity = 999
table.clear(snapshot)
assert(#InventoryService.GetInventory(farmer) == 3)
local fullSnapshot = PlayerDataService.GetData(farmer)
fullSnapshot.Inventory[1].Quantity = 999
assert(#PlayerDataService.GetData(farmer).Inventory == 3)
assert(not InventoryService.AddCrop({ UserId = -1 }, "Carrot", "Normal", 1))

-- Disconnect with growth timers still pending, then reuse the plot position.
local owner = join(12)
advance(0)
local oldSlot = PlotService.GetSlot(owner)
standAt(owner, oldSlot.Position)
assert(CropService.Plant(owner, oldSlot))
leave(owner)
local newcomer = join(13)
advance(0)
local newSlot = PlotService.GetSlot(newcomer)
assert(newSlot.Position.X == oldSlot.Position.X)
advance(CropConfig.Carrot.GrowthTime)
assert(CropService.GetSeeds(owner) == nil)
assert(InventoryService.GetInventory(owner) == nil)
assert(newSlot:GetAttribute("CropState") == "Empty")
assert(newSlot:FindFirstChild("Carrot") == nil)
assert(CropService.GetSeeds(newcomer) == CropConfig.Carrot.StartingSeeds)
local fleeting = join(14)
leave(fleeting)
advance(0)
assert(CropService.GetSeeds(fleeting) == nil)
local full = join(15)
advance(0)
local fullSlot = PlotService.GetSlot(full)
standAt(full, fullSlot.Position)
assert(PlayerDataService.AddInventoryItem(full, "Carrot", "Normal", 9007199254740991))
queueDraw(6) -- Normal
assert(CropService.Plant(full, fullSlot))
advance(CropConfig.Carrot.GrowthTime)
local didHarvest, failure = CropService.Harvest(full, fullSlot)
assert(not didHarvest and failure == "QuantityLimitExceeded")
assert(fullSlot:GetAttribute("CropState") == "Ready")
assert(fullSlot:GetAttribute("Variant") == "Normal")
assert(fullSlot:FindFirstChild("Carrot") ~= nil)
assert(InventoryService.GetInventory(full)[1].Quantity == 9007199254740991)
print("PASS: 10 crop cycles, variant-preserving inventory, aggregation, validation, snapshots, cleanup and stale timers")

-- A sale must debit the correct stack and credit its configured value once.
local pad = SellService.GetPad(farmer)
assert(pad and pad:GetAttribute("OwnerUserId") == farmer.UserId)
standAt(farmer, pad.Position)
standAt(intruder, pad.Position)
assert(not SellService.Sell(intruder, "Carrot", "Normal", 1))
assert(not SellService.Sell(farmer, "FakeCrop", "Normal", 1))
assert(not SellService.Sell(farmer, "Carrot", "FakeVariant", 1))
assert(not SellService.Sell(farmer, "Carrot", "Normal", 0))
assert(not SellService.Sell(farmer, "Carrot", "Normal", 999))
assert(PlayerDataService.GetCoins(farmer) == 100)
assert(SellService.Sell(farmer, "Carrot", "Normal", 2))
assert(PlayerDataService.GetCoins(farmer) == 130)
assert(SellService.Sell(farmer, "Carrot", "Golden", 1))
assert(PlayerDataService.GetCoins(farmer) == 160)
assert(SellService.Sell(farmer, "Carrot", "Rainbow", 3))
assert(PlayerDataService.GetCoins(farmer) == 385)
local remaining = {}
for _, entry in InventoryService.GetInventory(farmer) do
    remaining[entry.Variant] = entry.Quantity
end
assert(remaining.Normal == 1 and remaining.Golden == 3 and remaining.Rainbow == nil)
assert(not SellService.Sell(farmer, "Carrot", "Rainbow", 1))
assert(PlayerDataService.GetCoins(farmer) == 385)
standAt(farmer, pad.Position + Vector3.new(100, 0, 0))
assert(not SellService.Sell(farmer, "Carrot", "Normal", 1))
assert(PlayerDataService.GetCoins(farmer) == 385)
print("PASS: valid and invalid crop sales, variant prices, stack removal, ownership and distance")

local shop = SeedShopService.GetPad(farmer)
assert(shop and shop:GetAttribute("OwnerUserId") == farmer.UserId)
standAt(farmer, shop.Position)
standAt(intruder, shop.Position)
assert(not SeedShopService.Buy(intruder, "Carrot", 1))
assert(not SeedShopService.Buy(farmer, "FakeCrop", 1))
assert(not SeedShopService.Buy(farmer, "Carrot", 0))
assert(not SeedShopService.Buy(farmer, "Carrot", -1))
assert(not SeedShopService.Buy(farmer, "Carrot", 0/0))
assert(not SeedShopService.Buy(farmer, "Carrot", 40))
assert(CropService.GetSeeds(farmer) == 0)
assert(PlayerDataService.GetCoins(farmer) == 385)
assert(SeedShopService.Buy(farmer, "Carrot", 2))
assert(CropService.GetSeeds(farmer) == 2)
assert(PlayerDataService.GetCoins(farmer) == 365)
standAt(farmer, shop.Position + Vector3.new(100, 0, 0))
assert(not SeedShopService.Buy(farmer, "Carrot", 1))
assert(PlayerDataService.GetCoins(farmer) == 365)
print("PASS: Carrot seed purchases, insufficient funds, validation, ownership and distance")

local seedRequest = replicatedStorage:FindFirstChild("SeedShopRequest")
local sellRequest = replicatedStorage:FindFirstChild("SellRequest")
assert(seedRequest and sellRequest)
seedRequest.OnServerEvent:Fire(farmer)
assert(CropService.GetSeeds(farmer) == 2 and PlayerDataService.GetCoins(farmer) == 365)
standAt(farmer, shop.Position)
seedRequest.OnServerEvent:Fire(farmer, 999999) -- The client cannot choose price or quantity.
assert(CropService.GetSeeds(farmer) == 3 and PlayerDataService.GetCoins(farmer) == 355)
standAt(farmer, pad.Position)
sellRequest.OnServerEvent:Fire(farmer, "Carrot", "Golden", 1, 999999)
assert(PlayerDataService.GetCoins(farmer) == 385)
assert(not SellService.Sell(farmer, "Carrot", "Golden", 999))
standAt(farmer, pad.Position + Vector3.new(100, 0, 0))
sellRequest.OnServerEvent:Fire(farmer, "Carrot", "Golden", 1)
assert(PlayerDataService.GetCoins(farmer) == 385)
print("PASS: UI remotes keep seed purchases and chosen-stack sales server-authoritative")
