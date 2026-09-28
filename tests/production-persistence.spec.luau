
local producer = join(40)
advance(0)
assert(DataService.GetStatus(producer) == "Loaded")
assert(PlayerDataService.AddCoins(producer, 100))
assert(BuildService.Place(producer, "SmallField", -2, -2, 0))
assert(BuildService.Place(producer, "ChickenCoop", 2, 2, 0))
local main = PlotService.GetSlot(producer)
local field = nil
for _, child in main.Parent:GetChildren() do
    if child.Name == "CropSlot" and child:GetAttribute("FieldSlot") then field = child end
end
assert(field and field:GetAttribute("SlotId") == "Field_-2_-2")
local coop = ChickenService.GetCoop(producer)
assert(coop)
local firstEggAt = ChickenService.GetReadyAt(producer)
queueDraw(1) -- Golden is fixed at planting and survives reconnects.
standAt(producer, main.Position)
assert(CropService.Plant(producer, main))
queueDraw(6) -- Normal on the added field.
standAt(producer, field.Position)
assert(CropService.Plant(producer, field))
assert(CropService.GetSeeds(producer) == CropConfig.Carrot.StartingSeeds - 2)
local liveData = PlayerDataService.GetData(producer)
assert(#liveData.ActiveCrops == 2 and liveData.EggReadyAt == firstEggAt)
liveData.ActiveCrops[1].ReadyAt = 0
assert(PlayerDataService.GetData(producer).ActiveCrops[1].ReadyAt ~= 0)
advance(10)
assert(DataService.Save(producer))
local stored = saved[DataConfig.KeyPrefix .. "40"]
assert(#stored.ActiveCrops == 2 and stored.EggReadyAt == firstEggAt)
leave(producer)
advance(8) -- Time spent offline counts toward growth and egg production.

local returning = join(40)
advance(0)
local restoredMain = PlotService.GetSlot(returning)
local restoredCoop = ChickenService.GetCoop(returning)
assert(restoredMain:GetAttribute("CropState") == "Growing")
assert(restoredMain:GetAttribute("GrowthStage") == 2)
assert(restoredMain:GetAttribute("SeedsRemaining") == CropConfig.Carrot.StartingSeeds - 2)
assert(restoredCoop and not restoredCoop:FindFirstChild("Egg"))
assert(ChickenService.GetReadyAt(returning) == firstEggAt)
advance(2)
assert(restoredCoop:FindFirstChild("Egg"))
advance(10)
assert(restoredMain:GetAttribute("CropState") == "Ready")
assert(restoredMain:GetAttribute("Variant") == "Golden")
standAt(returning, restoredMain.Position)
assert(CropService.Harvest(returning, restoredMain))
assert(not CropService.Harvest(returning, restoredMain))
standAt(returning, restoredCoop.Position)
assert(ChickenService.Collect(returning, restoredCoop))
assert(not ChickenService.Collect(returning, restoredCoop))
assert(DataService.Save(returning))
assert(#saved[DataConfig.KeyPrefix .. "40"].ActiveCrops == 1)
local nextEggAt = ChickenService.GetReadyAt(returning)
leave(returning)
advance(25)

local finalReturn = join(40)
advance(0)
local finalMain = PlotService.GetSlot(finalReturn)
local finalCoop = ChickenService.GetCoop(finalReturn)
local finalField = nil
for _, child in finalMain.Parent:GetChildren() do
    if child.Name == "CropSlot" and child:GetAttribute("FieldSlot") then finalField = child end
end
assert(finalField and finalField:GetAttribute("CropState") == "Ready")
assert(finalField:GetAttribute("Variant") == "Normal")
assert(ChickenService.GetReadyAt(finalReturn) == nextEggAt)
assert(finalCoop and finalCoop:FindFirstChild("Egg"))
standAt(finalReturn, finalField.Position)
assert(CropService.Harvest(finalReturn, finalField))
standAt(finalReturn, finalCoop.Position)
assert(ChickenService.Collect(finalReturn, finalCoop))
local inventory = InventoryService.GetInventory(finalReturn)
local counts = {}
for _, entry in inventory do counts[entry.ItemId .. "/" .. entry.Variant] = entry.Quantity end
assert(counts["Carrot/Golden"] == 1 and counts["Carrot/Normal"] == 1)
assert(counts["Egg/Normal"] == 2)
assert(CropService.GetSeeds(finalReturn) == CropConfig.Carrot.StartingSeeds - 2)
assert(DataService.Save(finalReturn))
assert(#saved[DataConfig.KeyPrefix .. "40"].ActiveCrops == 0)
print("PASS: active crops and egg timer survive reconnects without duplicate rewards")
