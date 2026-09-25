-- Rebuilds the compact side HUD. Run in Roblox Studio Edit mode.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before refining the HUD")

local StarterPlayer = game:GetService("StarterPlayer")
local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local economy = scripts:WaitForChild("MinimalEconomyClient")
economy.Source = [==[
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local old = player:WaitForChild("PlayerGui"):FindFirstChild("EconomyGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EconomyGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = player.PlayerGui

local panel = Instance.new("Frame")
panel.Name = "CoinPanel"
panel.Position = UDim2.fromOffset(18, 18)
panel.Size = UDim2.fromOffset(188, 52)
panel.BackgroundTransparency = 1
panel.Parent = gui

local coin = Instance.new("TextLabel")
coin.Name = "GoldCoinIcon"
coin.Position = UDim2.fromOffset(0, 8)
coin.Size = UDim2.fromOffset(36, 36)
coin.BackgroundColor3 = Color3.fromHex("FFD84A")
coin.Text = "$"
coin.TextColor3 = Color3.fromHex("8B5400")
coin.Font = Enum.Font.GothamBlack
coin.TextSize = 25
coin.Parent = panel
Instance.new("UICorner", coin).CornerRadius = UDim.new(1, 0)
local rim = Instance.new("UIStroke", coin)
rim.Color = Color3.fromHex("5A3500")
rim.Thickness = 2
local inner = Instance.new("Frame")
inner.Position = UDim2.fromOffset(5, 5)
inner.Size = UDim2.fromOffset(26, 26)
inner.BackgroundTransparency = 1
inner.BorderSizePixel = 0
inner.Parent = coin
local innerRim = Instance.new("UIStroke", inner)
innerRim.Color = Color3.fromHex("FFF2A7")
innerRim.Thickness = 1
Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)

local label = Instance.new("TextLabel")
label.Name = "CoinLabel"
label.Position = UDim2.fromOffset(44, 8)
label.Size = UDim2.fromOffset(142, 36)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.fromHex("FFD84A")
label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
label.TextStrokeTransparency = 0
label.TextSize = 25
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = panel

local function refresh()
 local stats = player:FindFirstChild("leaderstats")
 local coins = stats and stats:FindFirstChild("Coins")
 label.Text = tostring(coins and coins.Value or player:GetAttribute("Coins") or 0)
end
task.spawn(function()
 local stats = player:WaitForChild("leaderstats", 10)
 local coins = stats and stats:WaitForChild("Coins", 10)
 if coins then coins:GetPropertyChangedSignal("Value"):Connect(refresh) end
 refresh()
end)
player:GetAttributeChangedSignal("Coins"):Connect(refresh)
refresh()
]==]

local hud = scripts:WaitForChild("FarmHudClient")
hud.Source = [==[
local player = game.Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local remote = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FarmingAction")
local gui = Instance.new("ScreenGui")
gui.Name = "FarmHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = pg

local function sideButton(name, text, y, color)
 local b = Instance.new("TextButton")
 b.Name = name
 b.Text = text
 b.Position = UDim2.fromOffset(18, y)
 b.Size = UDim2.fromOffset(188, 38)
 b.BackgroundColor3 = color
 b.TextColor3 = Color3.new(1, 1, 1)
 b.Font = Enum.Font.GothamBold
 b.TextSize = 14
 b.BorderSizePixel = 0
 b.Parent = gui
 Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
 return b
end
local bait = sideButton("CraftBait", "Cebos", 178, Color3.fromHex("8B5CFF"))
local seeds = sideButton("Seeds", "Semillas", 224, Color3.fromHex("4D8540"))

local panel = Instance.new("Frame")
panel.Name = "FarmPanel"
panel.AnchorPoint = Vector2.new(.5, .5)
panel.Position = UDim2.fromScale(.5, .5)
panel.Size = UDim2.new(.9, 0, .8, 0)
panel.BackgroundColor3 = Color3.fromHex("233447")
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
local limit = Instance.new("UISizeConstraint", panel)
limit.MaxSize = Vector2.new(490, 440)
local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16, 8)
title.Size = UDim2.new(1, -72, 0, 36)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel
local close = sideButton("Close", "X", 0, Color3.fromHex("8B5CFF"))
close.Parent = panel
close.Position = UDim2.new(1, -46, 0, 10)
close.Size = UDim2.fromOffset(32, 32)
close.Activated:Connect(function() panel.Visible = false end)
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(12, 55)
list.Size = UDim2.new(1, -24, 1, -115)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 10)
local crops = {{"Wheat","Trigo",3},{"Tomato","Tomates",5},{"Lettuce","Lechuga",4},{"Carrot","Zanahorias",4}}
local rows = {}
for i, crop in ipairs(crops) do
 local b = Instance.new("TextButton")
 b.LayoutOrder = i
 b.Size = UDim2.new(1, -6, 0, 58)
 b.BackgroundColor3 = Color3.fromHex("4D8540")
 b.TextColor3 = Color3.new(1, 1, 1)
 b.Font = Enum.Font.GothamBold
 b.TextSize = 14
 b.TextWrapped = true
 b.BorderSizePixel = 0
 b.Parent = list
 Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
 b.Activated:Connect(function() remote:FireServer("BuySeed", crop[1]) end)
 rows[i] = b
end
local recipe = Instance.new("TextLabel")
recipe.LayoutOrder = 5
recipe.Size = UDim2.new(1, -6, 0, 125)
recipe.BackgroundTransparency = 1
recipe.TextColor3 = Color3.new(1,1,1)
recipe.Font = Enum.Font.GothamBold
recipe.TextSize = 15
recipe.TextWrapped = true
recipe.Parent = list
local make = Instance.new("TextButton")
make.LayoutOrder = 6
make.Size = UDim2.new(1, -6, 0, 44)
make.BackgroundColor3 = Color3.fromHex("8B5CFF")
make.TextColor3 = Color3.new(1,1,1)
make.Font = Enum.Font.GothamBold
make.TextSize = 14
make.Text = "Fabricar 1 cebo"
make.BorderSizePixel = 0
make.Parent = list
Instance.new("UICorner", make).CornerRadius = UDim.new(0,6)
make.Activated:Connect(function() remote:FireServer("Craft") end)
local mode = "Seeds"
local function refresh()
 title.Text = mode == "Seeds" and "Semillas" or "Fabricar cebos"
 for i, crop in ipairs(crops) do
  rows[i].Visible = mode == "Seeds"
  rows[i].Text = crop[2].." | "..crop[3].." monedas\nSemillas: "..(player:GetAttribute("Seed"..crop[1]) or 0).." | Cosecha: "..(player:GetAttribute("Crop"..crop[1]) or 0)
 end
 recipe.Visible = mode == "Craft"
 make.Visible = mode == "Craft"
 local lines = {"1 de cada cultivo = 1 cebo", ""}
 local ready = true
 for _, crop in ipairs(crops) do
  local count = player:GetAttribute("Crop"..crop[1]) or 0
  table.insert(lines, crop[2]..": "..count.." / 1")
  if count < 1 then ready = false end
 end
 recipe.Text = table.concat(lines, "\n")
 make.Text = ready and "Fabricar 1 cebo" or "Faltan ingredientes"
 make.Active = ready
 make.AutoButtonColor = ready
end
bait.Activated:Connect(function() mode = "Craft" panel.Visible = true refresh() end)
seeds.Activated:Connect(function() mode = "Seeds" panel.Visible = true refresh() end)
player.AttributeChanged:Connect(refresh)
refresh()

local function align(button, y)
 button.Position = UDim2.fromOffset(18, y)
 button.Size = UDim2.fromOffset(188, 38)
end
task.spawn(function()
 local pet = pg:WaitForChild("TestPetGui"):WaitForChild("OpenPetInventoryButton")
 align(pet, 86)
 local expedition = pg:WaitForChild("ExpeditionGui"):WaitForChild("ExpeditionButton")
 align(expedition, 132)
end)
]==]

return "Installed compact, non-overlapping player HUD."
