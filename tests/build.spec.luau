
BuildService.Init()
local builder = join(20)
advance(0)
assert(PlayerDataService.GetCoins(builder) == 100)
assert(not BuildService.Place(builder, "FakeBuilding", -2, -2, 0))
assert(not BuildService.Place(builder, "Barn", 1.5, -2, 0))
assert(not BuildService.Place(builder, "Barn", -2, -2, 45))
assert(not BuildService.Place(builder, "Barn", 100, 100, 0))
assert(not BuildService.Place(builder, "Barn", 0, 0, 0)) -- Soil.
assert(not BuildService.Place(builder, "Barn", -2, 0, 0)) -- Seed shop.
assert(not BuildService.Place(builder, "Barn", 2, 0, 0)) -- Sell pad.
assert(PlayerDataService.GetCoins(builder) == 100)
assert(BuildService.Place(builder, "Barn", -2, -2, 90))
assert(PlayerDataService.GetCoins(builder) == 20)
assert(not BuildService.Place(builder, "Barn", -2, -2, 90))
assert(not BuildService.Place(builder, "Barn", 2, 2, 0)) -- Insufficient coins.
assert(#PlayerDataService.GetBuildings(builder) == 1)
local barn = PlotService.GetSlot(builder).Parent:FindFirstChild("Barn")
assert(barn and barn:GetAttribute("OwnerUserId") == builder.UserId)
assert(barn:GetAttribute("FootprintX") == BuildingConfig.Barn.Footprint.Y)
local dataCopy = PlayerDataService.GetData(builder)
dataCopy.Buildings[1].GridX = 999
assert(PlayerDataService.GetBuildings(builder)[1].GridX == -2)
assert(PlayerDataService.AddCoins(builder, 80))
assert(BuildService.Place(builder, "Barn", 2, 2, 0))
assert(#PlayerDataService.GetBuildings(builder) == 2)
local intruderBuilder = join(21)
advance(0)
assert(#PlayerDataService.GetBuildings(intruderBuilder) == 0)
assert(not BuildService.Place({ UserId = -1 }, "Barn", -2, -2, 0))
print("PASS: grid placement, rotation, bounds, overlap, money, ownership and building snapshots")

local fieldOwner = join(22)
advance(0)
assert(BuildService.Place(fieldOwner, "SmallField", -2, -2, 0))
assert(PlayerDataService.GetCoins(fieldOwner) == 50)
local original = PlotService.GetSlot(fieldOwner)
local addedSlot = nil
for _, child in original.Parent:GetChildren() do
    if child.Name == "CropSlot" and child:GetAttribute("FieldSlot") == true then
        addedSlot = child
    end
end
assert(addedSlot and addedSlot ~= original)
assert(PlotService.OwnsSlot(fieldOwner, addedSlot))
assert(addedSlot:FindFirstChild("CropInteraction"))
standAt(fieldOwner, original.Position)
assert(CropService.Plant(fieldOwner, original))
standAt(fieldOwner, addedSlot.Position)
assert(CropService.Plant(fieldOwner, addedSlot))
assert(CropService.GetSeeds(fieldOwner) == CropConfig.Carrot.StartingSeeds - 2)
assert(not CropService.Plant(builder, addedSlot))
advance(CropConfig.Carrot.GrowthTime)
standAt(fieldOwner, original.Position)
assert(CropService.Harvest(fieldOwner, original))
standAt(fieldOwner, addedSlot.Position)
assert(CropService.Harvest(fieldOwner, addedSlot))
local fieldInventory = InventoryService.GetInventory(fieldOwner)
assert(#fieldInventory == 1 and fieldInventory[1].Quantity == 2)
assert(not BuildService.Place(fieldOwner, "Barn", -2, -2, 0))
print("PASS: placed Small Field adds a second shared-seed planting slot and preserves the crop lifecycle")
