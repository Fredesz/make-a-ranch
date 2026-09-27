
CropService.Init()
CropService.Init()
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
    assert(not CropService.Harvest(intruder, soil))
    local ok, harvestedId = CropService.Harvest(farmer, soil)
    assert(ok and harvestedId == "Carrot")
    assert(soil:GetAttribute("CropState") == "Empty")
    assert(soil:FindFirstChild("Carrot") == nil)
    assert(not CropService.Harvest(farmer, soil))
end
local planted, reason = CropService.Plant(farmer, soil)
assert(not planted and reason == "NoSeeds")
assert(PlayerDataService.GetCoins(farmer) == 100)

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
assert(newSlot:GetAttribute("CropState") == "Empty")
assert(newSlot:FindFirstChild("Carrot") == nil)
assert(CropService.GetSeeds(newcomer) == CropConfig.Carrot.StartingSeeds)
local fleeting = join(14)
leave(fleeting)
advance(0)
assert(CropService.GetSeeds(fleeting) == nil)
print("PASS: 10 crop cycles, stages, prompts, ownership, distance, seeds, early/double harvest and stale timers")
