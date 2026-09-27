
DataService.Init()
local persistent = join(31)
advance(0)
assert(DataService.GetStatus(persistent) == "Loaded")
assert(BuildService.Place(persistent, "SmallField", -2, -2, 0))
assert(InventoryService.AddCrop(persistent, "Carrot", "Golden", 3))
assert(PlayerDataService.AddCoins(persistent, 25))
local before = PlayerDataService.GetData(persistent)
assert(before.Coins == 75)
assert(#before.Buildings == 1 and #before.Inventory == 1)
assert(DataService.Save(persistent))
leave(persistent)
local returning = join(31)
advance(0)
assert(DataService.GetStatus(returning) == "Loaded")
local after = PlayerDataService.GetData(returning)
assert(after.Coins == 75)
assert(#after.Inventory == 1 and after.Inventory[1].ItemId == "Carrot"
    and after.Inventory[1].Variant == "Golden" and after.Inventory[1].Quantity == 3)
assert(#after.Buildings == 1 and after.Buildings[1].BuildingId == "SmallField")
local field = nil
for _, child in PlotService.GetSlot(returning).Parent:GetChildren() do
    if child.Name == "CropSlot" and child:GetAttribute("FieldSlot") then field = child end
end
assert(field and PlotService.OwnsSlot(returning, field))
standAt(returning, field.Position)
assert(CropService.Plant(returning, field))
print("PASS: DataStore save/load restores coins, variant inventory, field placement and planting")

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
