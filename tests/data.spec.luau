
DataService.Init()
local persistent = join(31)
advance(0)
assert(DataService.GetStatus(persistent) == "Loaded")
assert(BuildService.Place(persistent, "SmallField", -2, -2, 0))
assert(InventoryService.AddCrop(persistent, "Carrot", "Golden", 3))
assert(PlayerDataService.AddCoins(persistent, 25))
standAt(persistent, SeedShopService.GetPad(persistent).Position)
assert(SeedShopService.Buy(persistent, "Carrot", 2))
assert(CropService.GetSeeds(persistent) == CropConfig.Carrot.StartingSeeds + 2)
local before = PlayerDataService.GetData(persistent)
assert(before.Coins == 55 and before.Seeds == 12)
assert(#before.Buildings == 1 and #before.Inventory == 1)
before.Seeds = 0
assert(CropService.GetSeeds(persistent) == 12)
assert(DataService.Save(persistent))
leave(persistent)
local returning = join(31)
advance(0)
assert(DataService.GetStatus(returning) == "Loaded")
local after = PlayerDataService.GetData(returning)
assert(after.Coins == 55 and after.Seeds == 12)
assert(CropService.GetSeeds(returning) == 12)
assert(#after.Inventory == 1 and after.Inventory[1].ItemId == "Carrot"
    and after.Inventory[1].Variant == "Golden" and after.Inventory[1].Quantity == 3)
assert(#after.Buildings == 1 and after.Buildings[1].BuildingId == "SmallField")
local field = nil
for _, child in PlotService.GetSlot(returning).Parent:GetChildren() do
    if child.Name == "CropSlot" and child:GetAttribute("FieldSlot") then field = child end
end
assert(field and PlotService.OwnsSlot(returning, field))
assert(field:GetAttribute("SeedsRemaining") == 12)
standAt(returning, field.Position)
assert(CropService.Plant(returning, field))
assert(CropService.GetSeeds(returning) == 11)
assert(DataService.Save(returning))
leave(returning)
local plantedReturn = join(31)
advance(0)
assert(CropService.GetSeeds(plantedReturn) == 11)
assert(PlayerDataService.GetCoins(plantedReturn) == 55)
assert(PlotService.GetSlot(plantedReturn):GetAttribute("SeedsRemaining") == 11)
print("PASS: DataStore restores coins, inventory, buildings and purchased/consumed seeds")

saved[DataConfig.KeyPrefix .. "33"] = {
    Coins = 42,
    Inventory = {},
    Buildings = {},
}
local legacy = join(33)
advance(0)
assert(DataService.GetStatus(legacy) == "Loaded")
assert(PlayerDataService.GetCoins(legacy) == 42)
assert(CropService.GetSeeds(legacy) == CropConfig.Carrot.StartingSeeds)
assert(DataService.Save(legacy))
assert(saved[DataConfig.KeyPrefix .. "33"].Seeds == CropConfig.Carrot.StartingSeeds)
print("PASS: old saves without Seeds receive the configured starting balance")

saved[DataConfig.KeyPrefix .. "34"] = {
    Coins = 80,
    Seeds = -1,
    Inventory = {},
    Buildings = {},
}
local invalidSeeds = join(34)
advance(0)
assert(DataService.GetStatus(invalidSeeds) == "Unavailable")
assert(not DataService.Save(invalidSeeds))
leave(invalidSeeds)
assert(saved[DataConfig.KeyPrefix .. "34"].Coins == 80)
assert(saved[DataConfig.KeyPrefix .. "34"].Seeds == -1)
print("PASS: invalid saved Seeds cannot overwrite the stored player data")

saved[DataConfig.KeyPrefix .. "32"] = {
    Coins = 777,
    Inventory = {},
    Buildings = {},
}
fakeStore.FailRead = true
local failedLoad = join(32)
advance(0)
assert(DataService.GetStatus(failedLoad) == "Unavailable")
assert(PlayerDataService.IsReady(failedLoad)) -- Session can still be played.
assert(PlayerDataService.GetCoins(failedLoad) == 100)
assert(not DataService.Save(failedLoad))
leave(failedLoad)
assert(saved[DataConfig.KeyPrefix .. "32"].Coins == 777)
fakeStore.FailRead = false
print("PASS: failed DataStore read cannot overwrite saved player data")
