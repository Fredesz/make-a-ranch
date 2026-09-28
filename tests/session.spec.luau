
local first = join(1) -- Covers players already present during initialization.
assert(ranchPlots:FindFirstChild("Plot_1") == firstPlot)
local editSlot = firstPlot:FindFirstChild("CropSlot")
assert(editSlot and firstPlot:FindFirstChild("SeedShop") and firstPlot:FindFirstChild("SellPad"))
PlayerDataService.Init()
PlotService.Init()
local second = join(2)
local slot = PlotService.GetSlot(first)
assert(slot == editSlot)
assert(slot and PlotService.OwnsSlot(first, slot))
assert(not PlotService.OwnsSlot(second, slot))
assert(slot ~= PlotService.GetSlot(second))
assert(PlotService.GetSlot(second).Parent:GetAttribute("PlotIndex") == 2)
assert(slot.Parent:GetAttribute("OwnerUserId") == first.UserId)
assert(slot.Parent:FindFirstChild("OwnerSign"):FindFirstChild("OwnerText").Text == "Parcela 1\nFarmer1")
PlotService.Init()
PlayerDataService.Init()
assert(PlotService.GetSlot(first) == slot)
assert(PlayerDataService.GetCoins(first) == 100)
assert(PlayerDataService.AddCoins(first, 50))
assert(PlayerDataService.RemoveCoins(first, 30))
assert(not PlayerDataService.RemoveCoins(first, 121))
assert(PlayerDataService.GetCoins(first) == 120)
for _, amount in {-1, 0.5, math.huge, 0/0} do
    assert(not PlayerDataService.AddCoins(first, amount))
    assert(not PlayerDataService.RemoveCoins(first, amount))
end
local copy = PlayerDataService.GetData(first)
copy.Coins = -1
assert(PlayerDataService.GetCoins(first) == 120)
assert(PlayerDataService.GetCoins(second) == 100)
leave(first)
assert(PlayerDataService.GetData(first) == nil)
assert(PlotService.GetSlot(first) == nil)
assert(not slot:IsDescendantOf(workspace))
local vacant = ranchPlots:FindFirstChild("Plot_1")
assert(vacant and vacant:FindFirstChild("CropSlot") and vacant:FindFirstChild("SeedShop"))
assert(vacant:GetAttribute("OwnerUserId") == nil)
assert(vacant:FindFirstChild("OwnerSign"):FindFirstChild("OwnerText").Text == "Parcela 1\nDisponible")
assert(not PlayerDataService.AddCoins(first, 1))
local third = join(3)
assert(PlotService.GetSlot(third).Position.X == slot.Position.X)
assert(PlayerDataService.GetCoins(third) == 100)
print("PASS: session data, coin validation, plot ownership, cleanup and slot reuse")
local occupants = { second, third }
for index = 3, 8 do table.insert(occupants, join(100 + index)) end
local unique = {}
for _, player in occupants do
    local model = PlotService.GetSlot(player).Parent
    assert(not unique[model])
    unique[model] = true
end
local overflow = join(999)
assert(overflow.KickMessage and not PlotService.GetSlot(overflow))
assert(#ranchPlots:GetChildren() == 8)
for _, player in Players:GetPlayers() do leave(player) end
assert(#ranchPlots:GetChildren() == 8)
for _, plot in ranchPlots:GetChildren() do assert(plot:GetAttribute("OwnerUserId") == nil) end
print("PASS: eight unique plots, full-server protection and all plots released")
