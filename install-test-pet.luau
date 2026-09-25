-- Run once in the Studio command bar in Edit mode, after install-minimal-economy.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before installing")
local replicated = game:GetService("ReplicatedStorage")
local server = game:GetService("ServerScriptService")
assert(server:FindFirstChild("MinimalEconomyService"), "Install minimal economy first")
local remotes = replicated:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("TestPetAction") or Instance.new("RemoteEvent")
remote.Name = "TestPetAction"
remote.Parent = remotes
local cowRemote = remotes:FindFirstChild("CowPetAction") or Instance.new("RemoteEvent")
cowRemote.Name = "CowPetAction"
cowRemote.Parent = remotes

local definitions = replicated:FindFirstChild("PetDefinitions") or Instance.new("ModuleScript")
definitions.Name = "PetDefinitions"
definitions.Source = [==[return {
 Chicken = {name="Pollito", rarity="Comun", rate=1, chance=0.8, color=Color3.fromRGB(158,195,159), id="TestChicken", remote="TestPetAction", store="FarmRngTycoon_PetProfiles_v1", farmX=0, height=0.85, attributes={"OwnsTestPet","TestPetEquipped","TestPetInFarm","TestPetFarmPosition","PetDataLoaded"}},
 Cow = {name="Vaca", rarity="Rara", rate=5, chance=0.35, color=Color3.fromRGB(88,187,240), id="TestCow", remote="CowPetAction", store="FarmRngTycoon_CowProfiles_v1", farmX=5, height=1.1, attributes={"OwnsCow","CowEquipped","CowInFarm","CowFarmPosition","CowDataLoaded"}},
 GoldenCow = {name="Vaca dorada", rarity="Legendaria", rate=20, chance=0.1, color=Color3.fromRGB(255,203,67), id="GoldenCow", remote="GoldenCowAction", store="FarmRngTycoon_GoldenCowProfiles_v1", farmX=10, height=1.1, attributes={"OwnsGoldenCow","GoldenCowEquipped","GoldenCowInFarm","GoldenCowFarmPosition","GoldenCowDataLoaded"}},
}]==]
definitions.Parent = replicated
local legendaryRemote = remotes:FindFirstChild("GoldenCowAction") or Instance.new("RemoteEvent")
legendaryRemote.Name = "GoldenCowAction"
legendaryRemote.Parent = remotes

local serverSource = [==[
local function startPet(config)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild(config.remote)
local petStore = DataStoreService:GetDataStore(config.store)
local PET_ID = config.id
local states = {}
local plots = workspace:WaitForChild("FarmLayout"):WaitForChild("Plots")
local function ownedPasture(player)
	for _, plot in ipairs(plots:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot:FindFirstChild("Pasture", true)
		end
	end
	return nil
end
local function restoreFarmPosition(player)
	local state = states[player]
	if not state or not state.inFarm then return false end
	local pasture = ownedPasture(player)
	if not pasture then return false end
	local rear = pasture:GetAttribute("RearDirection") or 1
	local position = pasture.CFrame:PointToWorldSpace(Vector3.new(config.farmX - 5, pasture.Size.Y / 2 + config.height, rear * pasture.Size.Z * 0.3))
	player:SetAttribute(config.attributes[4], position)
	return true
end
local function setup(player)
	if states[player] then return end
	local state = {owned = false, equipped = false, inFarm = false, loaded = false, lastAction = -math.huge, nextReward = 0}
	states[player] = state
	local success, data = pcall(function()
		return petStore:GetAsync("Player_" .. player.UserId)
	end)
	for attempt = 1, 2 do
		if success then break end
		task.wait(attempt)
		success, data = pcall(function() return petStore:GetAsync("Player_" .. player.UserId) end)
	end
	if success and type(data) == "table" then
		state.owned = type(data.pets) == "table" and data.pets[PET_ID] == true
		state.count = math.max(state.owned and 1 or 0, math.floor(tonumber(data.count) or 0))
		if state.owned and data.activeState == "Equipped" then
			state.equipped = true
		elseif state.owned and data.activeState == "Farm" then
			state.inFarm = true
			state.nextReward = os.clock() + 1
		end
	elseif not success then
		warn("[Pets] Could not load pet profile for " .. player.Name .. ": " .. tostring(data))
	end
	if not success then
		player:SetAttribute(config.attributes[5], false)
		return
	end
	if player.Parent ~= Players then states[player] = nil return end
	state.loaded = true
	state.count = state.count or 0
	player:SetAttribute(PET_ID .. "Count", state.count)
	player:SetAttribute(config.attributes[1], state.owned)
	player:SetAttribute(config.attributes[2], state.equipped)
	player:SetAttribute(config.attributes[3], state.inFarm)
	player:SetAttribute(config.attributes[5], true)
	if state.inFarm then
		task.spawn(function()
			for _ = 1, 100 do
				if not states[player] or restoreFarmPosition(player) then return end
				task.wait(0.1)
			end
			warn("[Pets] Could not restore farm position for " .. player.Name)
		end)
	else
		player:SetAttribute(config.attributes[4], nil)
	end
end
local function save(player)
	local state = states[player]
	if not state or not state.loaded then return end
	while state.saving do task.wait(0.05) end
	state.saving = true
	local activeState = state.equipped and "Equipped" or (state.inFarm and "Farm" or "Inventory")
	local success, err = pcall(function()
		petStore:UpdateAsync("Player_" .. player.UserId, function(oldData)
			local data = type(oldData) == "table" and oldData or {}
			data.version = 1
			data.pets = type(data.pets) == "table" and data.pets or {}
			data.pets[PET_ID] = state.owned
			data.count = state.count
			data.activeState = activeState
			return data
		end)
	end)
	if not success then
		warn("[Pets] Could not save pet profile for " .. player.Name .. ": " .. tostring(err))
	end
	state.saving = false
end
local grant = Instance.new("BindableFunction")
grant.Name = "Capture" .. PET_ID
grant.Parent = script
grant.OnInvoke = function(player)
	local state = states[player]
	if not state or not state.loaded then return false end
	local total=0
	for _, id in ipairs({"TestChicken","TestCow","GoldenCow"}) do total += player:GetAttribute(id .. "Count") or 0 end
	if not player:GetAttribute("EconomyDataLoaded") or total >= (player:GetAttribute("InventoryCapacity") or 10) then return false end
	state.count += 1
	state.owned = true
	player:SetAttribute(PET_ID .. "Count", state.count)
	player:SetAttribute(config.attributes[1], true)
	task.spawn(save, player)
	return true
end
Players.PlayerAdded:Connect(function(player) task.spawn(setup, player) end)
Players.PlayerRemoving:Connect(function(player)
	save(player)
	states[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setup, player) end
remote.OnServerEvent:Connect(function(player, action)
	local state = states[player]
	if not state or not state.loaded or typeof(action) ~= "string" then return end
	if action ~= "Obtain" and action ~= "Equip" and action ~= "Unequip" and action ~= "Farm" then return end
	local now = os.clock()
	if now - state.lastAction < 0.3 then return end
	state.lastAction = now
	if action == "Obtain" then
		return -- Pets are now acquired through expeditions.
	elseif action == "LegacyObtainDisabled" then
		if state.owned then return end
		state.owned = true
		state.count = 1
		player:SetAttribute(PET_ID .. "Count", state.count)
	elseif action == "Equip" and state.owned and not state.equipped then
		state.equipped = true
		state.inFarm = false
		player:SetAttribute(config.attributes[4], nil)
	elseif action == "Farm" and state.owned and not state.inFarm then
		local pasture = ownedPasture(player)
		if not pasture then return end
		state.equipped = false
		state.inFarm = true
		state.nextReward = now + 1
		restoreFarmPosition(player)
	elseif action == "Unequip" then
		state.equipped = false
		state.inFarm = false
		player:SetAttribute(config.attributes[4], nil)
	end
	player:SetAttribute(config.attributes[1], state.owned)
	player:SetAttribute(config.attributes[2], state.equipped)
	player:SetAttribute(config.attributes[3], state.inFarm)
	task.spawn(save, player)
end)
task.spawn(function()
	while true do
		task.wait(0.1)
		local now = os.clock()
		for player, state in pairs(states) do
			if state.inFarm and player:GetAttribute(config.attributes[4]) == nil then
				restoreFarmPosition(player)
			end
			local producing = player:GetAttribute("EconomyDataLoaded") == true
				and (state.equipped or (state.inFarm and ownedPasture(player) ~= nil))
			if producing and now >= state.nextReward then
				state.nextReward = now + 1
				local stats = player:FindFirstChild("leaderstats")
				local coins = stats and stats:FindFirstChild("Coins")
				if coins and coins:IsA("IntValue") then
					coins.Value += config.rate
					player:SetAttribute("Coins", coins.Value)
				end
			end
		end
	end
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		save(player)
	end
end)
task.spawn(function()
	while true do
		task.wait(60)
		for player, state in pairs(states) do
			if state.loaded and not state.saving then task.spawn(save,player) end
		end
	end
end)
end
local definitions = require(game.ReplicatedStorage:WaitForChild("PetDefinitions"))
for _, species in ipairs({"Chicken", "Cow", "GoldenCow"}) do startPet(definitions[species]) end
]==]

local clientSource = [==[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TestPetAction")
local cowRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CowPetAction")
local selectedPet = "Chicken"
local definitions = require(game.ReplicatedStorage:WaitForChild("PetDefinitions"))
local speciesOrder = {"Chicken", "Cow", "GoldenCow"}
local attributeIndex = {OwnsTestPet=1,TestPetEquipped=2,TestPetInFarm=3,TestPetFarmPosition=4,PetDataLoaded=5}
local function petAttribute(owner, name, species)
 return owner:GetAttribute(definitions[species or selectedPet].attributes[attributeIndex[name]])
end
local function requestAction(action)
 game.ReplicatedStorage.Remotes[definitions[selectedPet].remote]:FireServer(action)
end
local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("TestPetGui")
if oldGui then oldGui:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "TestPetGui"
gui.DisplayOrder = 10
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function styleButton(button, color)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
end

local openButton = Instance.new("TextButton")
openButton.Name = "OpenPetInventoryButton"
openButton.Position = UDim2.fromOffset(18, 116)
openButton.Size = UDim2.fromOffset(154, 42)
openButton.Text = "Mascotas"
styleButton(openButton, Color3.fromRGB(50, 105, 75))
openButton.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "PetInventoryPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.9, 0, 0, 420)
panel.BackgroundColor3 = Color3.fromRGB(32, 39, 36)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
local corner = Instance.new("UICorner", panel)
corner.CornerRadius = UDim.new(0, 8)
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(280, 420)
sizeConstraint.MaxSize = Vector2.new(640, 420)
sizeConstraint.Parent = panel

local function label(parent, name, position, size, textSize)
	local text = Instance.new("TextLabel")
	text.Name = name
	text.Position = position
	text.Size = size
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = textSize
	text.TextColor3 = Color3.fromRGB(245, 245, 245)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Parent = parent
	return text
end

local title = label(panel, "Title", UDim2.fromOffset(18, 12), UDim2.new(1, -76, 0, 28), 22)
title.Text = "Inventario de mascotas"
title.TextScaled = true
local titleLimit = Instance.new("UITextSizeConstraint", title)
titleLimit.MaxTextSize = 22
titleLimit.MinTextSize = 12
local count = label(panel, "PetCount", UDim2.fromOffset(20, 42), UDim2.new(1, -40, 0, 20), 13)
count.TextColor3 = Color3.fromRGB(175, 190, 181)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.Size = UDim2.fromOffset(34, 34)
closeButton.Text = "X"
styleButton(closeButton, Color3.fromRGB(76, 82, 79))
closeButton.Parent = panel

local card = Instance.new("Frame")
card.Name = "TestChickenCard"
card.Position = UDim2.fromOffset(16, 112)
card.Size = UDim2.new(1, -32, 0, 290)
card.BackgroundColor3 = Color3.fromRGB(45, 54, 50)
card.BorderSizePixel = 0
card.Parent = panel
card.Visible = false
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)

local preview = Instance.new("ViewportFrame")
preview.Name = "PetPreview"
preview.Position = UDim2.fromOffset(12, 8)
preview.Size = UDim2.new(1, -24, 0, 120)
preview.BackgroundTransparency = 1
preview.Ambient = Color3.fromRGB(220, 220, 220)
preview.LightColor = Color3.fromRGB(255, 248, 225)
preview.LightDirection = Vector3.new(-1, -1, -2)
preview.Parent = card
local previewWorld = Instance.new("WorldModel", preview)
local previewCamera = Instance.new("Camera", preview)
previewCamera.FieldOfView = 32
previewCamera.CFrame = CFrame.lookAt(Vector3.new(3, 2, -6), Vector3.new(0, 0.3, 0))
preview.CurrentCamera = previewCamera

local petName = label(card, "PetName", UDim2.fromOffset(16, 132), UDim2.new(1, -32, 0, 25), 19)
petName.Text = "Pollito"
local status = label(card, "Status", UDim2.fromOffset(16, 162), UDim2.new(1, -32, 0, 21), 14)
local production = label(card, "Production", UDim2.fromOffset(16, 186), UDim2.new(1, -32, 0, 21), 14)
production.TextScaled = true
local productionLimit = Instance.new("UITextSizeConstraint", production)
productionLimit.MaxTextSize = 14
productionLimit.MinTextSize = 10
production.TextColor3 = Color3.fromRGB(255, 218, 105)

local actions = Instance.new("Frame")
actions.Name = "Actions"
actions.Position = UDim2.fromOffset(14, 232)
actions.Size = UDim2.new(1, -28, 0, 42)
actions.BackgroundTransparency = 1
actions.Parent = card
local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionLayout.Padding = UDim.new(0, 8)
actionLayout.Parent = actions

local obtainButton = Instance.new("TextButton")
obtainButton.Name = "ObtainButton"
obtainButton.Size = UDim2.new(1, 0, 1, 0)
obtainButton.Text = "Obtener gratis"
styleButton(obtainButton, Color3.fromRGB(65, 134, 86))
obtainButton.Parent = actions
local equipButton = Instance.new("TextButton")
equipButton.Name = "EquipButton"
equipButton.Size = UDim2.new(0.5, -4, 1, 0)
styleButton(equipButton, Color3.fromRGB(65, 134, 86))
equipButton.Parent = actions
local farmButton = Instance.new("TextButton")
farmButton.Name = "FarmButton"
farmButton.Size = UDim2.new(0.5, -4, 1, 0)
styleButton(farmButton, Color3.fromRGB(55, 111, 150))
farmButton.Parent = actions

local function refresh()
	local owned = petAttribute(player, "OwnsTestPet")
	local equipped = petAttribute(player, "TestPetEquipped")
	local inFarm = petAttribute(player, "TestPetInFarm")
	local hasPlot = (player:GetAttribute("AssignedPlotId") or 0) > 0
	local producing = equipped or inFarm
	local total = 0
 for _, definition in pairs(definitions) do total += player:GetAttribute(definition.id .. "Count") or 0 end
 count.Text = tostring(total) .. " / " .. tostring(player:GetAttribute("InventoryCapacity") or 10) .. " mascotas"
 petName.Text = definitions[selectedPet].name .. " - " .. definitions[selectedPet].rarity
 petName.TextColor3 = definitions[selectedPet].color
	status.Text = inFarm and "Estado: En la granja" or (equipped and "Estado: Equipada" or (owned and "Estado: En inventario" or "Estado: No obtenida"))
	production.Text = string.format("+%d monedas/s | Captura %d%%", producing and definitions[selectedPet].rate or 0, definitions[selectedPet].chance * 100)
	obtainButton.Visible = not owned
 obtainButton.Text = "En expediciones"
 obtainButton.Active = false
 obtainButton.AutoButtonColor = false
	equipButton.Visible = owned == true
	farmButton.Visible = owned == true
	equipButton.Text = equipped and "Desequipar" or "Equipar"
	farmButton.Text = inFarm and "Retirar" or (hasPlot and "A la granja" or "Sin parcela")
	farmButton.Active = inFarm or hasPlot
	farmButton.AutoButtonColor = farmButton.Active
end
local showCollection
openButton.Activated:Connect(function()
 panel.Visible = true
 if showCollection then showCollection() end
end)
closeButton.Activated:Connect(function() panel.Visible = false end)
obtainButton.Activated:Connect(function() requestAction("Obtain") end)
equipButton.Activated:Connect(function()
	requestAction(petAttribute(player, "TestPetEquipped") and "Unequip" or "Equip")
end)
farmButton.Activated:Connect(function()
	requestAction(petAttribute(player, "TestPetInFarm") and "Unequip" or "Farm")
end)
player:GetAttributeChangedSignal("OwnsTestPet"):Connect(refresh)
player:GetAttributeChangedSignal("TestPetEquipped"):Connect(refresh)
player:GetAttributeChangedSignal("TestPetInFarm"):Connect(refresh)
player:GetAttributeChangedSignal("AssignedPlotId"):Connect(refresh)
player:GetAttributeChangedSignal("InventoryCapacity"):Connect(refresh)
player:GetAttributeChangedSignal("TestChickenCount"):Connect(refresh)
player:GetAttributeChangedSignal("TestCowCount"):Connect(refresh)
refresh()

-- Each client renders companions from server-replicated equipment state.
local models = {}
local function makePet(parent, species)
	local model = Instance.new("Model")
	model.Name = "TestPetVisual"
	local function part(name, size, offset, color, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = CFrame.new(offset)
		p.Color = color
		p.Shape = shape or Enum.PartType.Ball
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = model
		return p
	end
	if species == "Cow" or species == "GoldenCow" then
  local white = species == "GoldenCow" and Color3.fromRGB(255,211,82) or Color3.fromRGB(244, 244, 237)
  local black = species == "GoldenCow" and Color3.fromRGB(155,93,30) or Color3.fromRGB(31, 34, 37)
  local pink = Color3.fromRGB(235, 157, 173)
  -- Sphere meshes preserve ellipsoid proportions for the muzzle, ears and coat.
  local function oval(name, size, position, color, tilt)
   local p = part(name, size, position, color, Enum.PartType.Block)
   local mesh = Instance.new("SpecialMesh")
   mesh.MeshType = Enum.MeshType.Sphere
   mesh.Parent = p
   if tilt then p.CFrame *= CFrame.Angles(0, 0, tilt) end
   return p
  end
  model.PrimaryPart = oval("Body", Vector3.new(1.65, 1.35, 2.35), Vector3.new(0, 0.05, 0.15), white)
  oval("Neck", Vector3.new(1, 1.05, 1), Vector3.new(0, 0.35, -0.82), white)
  oval("Head", Vector3.new(1.27, 1.2, 1.05), Vector3.new(0, 0.72, -1.18), white)
  oval("Muzzle", Vector3.new(1.12, 0.58, 0.62), Vector3.new(0, 0.4, -1.68), pink)
  oval("ForeheadPatch", Vector3.new(0.48, 0.42, 0.12), Vector3.new(-0.23, 1.04, -1.59), black, -0.25)
  for _, side in ipairs({-1, 1}) do
   oval("Ear", Vector3.new(0.7, 0.3, 0.38), Vector3.new(side * 0.75, 1.03, -1.12), black, side * 0.25)
   oval("InnerEar", Vector3.new(0.42, 0.15, 0.12), Vector3.new(side * 0.79, 1.06, -1.3), pink, side * 0.25)
   oval("HornBase", Vector3.new(0.19, 0.34, 0.19), Vector3.new(side * 0.39, 1.34, -1.05), Color3.fromRGB(226, 210, 171), -side * 0.25)
   oval("HornTip", Vector3.new(0.12, 0.24, 0.12), Vector3.new(side * 0.43, 1.51, -1.05), Color3.fromRGB(244, 229, 192), -side * 0.3)
   oval("Eye", Vector3.new(0.19, 0.25, 0.13), Vector3.new(side * 0.38, 0.84, -1.64), black)
   oval("EyeGlint", Vector3.new(0.06, 0.075, 0.035), Vector3.new(side * 0.38 - 0.025, 0.9, -1.706), white)
   oval("Nostril", Vector3.new(0.13, 0.09, 0.04), Vector3.new(side * 0.27, 0.46, -1.983), Color3.fromRGB(119, 67, 81), side * 0.2)
   for _, z in ipairs({-0.57, 0.87}) do
    oval("Leg", Vector3.new(0.36, 0.72, 0.39), Vector3.new(side * 0.55, -0.56, z), white)
    oval("Hoof", Vector3.new(0.4, 0.28, 0.44), Vector3.new(side * 0.55, -0.92, z - 0.02), black)
   end
   oval("CoatPatch", Vector3.new(0.3, 0.72, 0.95), Vector3.new(side * 0.68, 0.16, side * 0.34 + 0.15), black, side * 0.2)
   oval("CoatPatchSmall", Vector3.new(0.27, 0.38, 0.48), Vector3.new(side * 0.7, -0.05, -side * 0.45 + 0.15), black)
  end
  oval("BackPatch", Vector3.new(0.65, 0.2, 0.8), Vector3.new(0.18, 0.64, 0.44), black)
  oval("Tail", Vector3.new(0.13, 0.85, 0.14), Vector3.new(0.06, -0.05, 1.32), white, -0.15)
  oval("TailTuft", Vector3.new(0.24, 0.29, 0.25), Vector3.new(0.12, -0.45, 1.32), black)
  model.Parent = parent or workspace
  return model
 end
 local yellow = Color3.fromRGB(255, 222, 72)
	model.PrimaryPart = part("Body", Vector3.new(1.5, 1.4, 1.4), Vector3.zero, yellow)
	part("Head", Vector3.new(1.1, 1.1, 1.1), Vector3.new(0, 0.8, -0.3), yellow)
	part("Beak", Vector3.new(0.4, 0.25, 0.4), Vector3.new(0, 0.65, -0.9), Color3.fromRGB(255, 135, 36), Enum.PartType.Block)
	for _, x in ipairs({-0.32, 0.32}) do
		part("Eye", Vector3.new(0.14, 0.18, 0.14), Vector3.new(x, 0.95, -0.76), Color3.fromRGB(25, 25, 25))
		part("Foot", Vector3.new(0.3, 0.18, 0.45), Vector3.new(x, -0.72, -0.15), Color3.fromRGB(255, 135, 36), Enum.PartType.Block)
	end
	model.Parent = parent or workspace
	return model
end
local previewPet = makePet(previewWorld, selectedPet)
local collection = Instance.new("ScrollingFrame")
collection.Name = "PetCollection"
collection.Position = UDim2.fromOffset(16, 76)
collection.Size = UDim2.new(1, -32, 1, -130)
collection.BackgroundTransparency = 1
collection.BorderSizePixel = 0
collection.ScrollBarThickness = 4
collection.AutomaticCanvasSize = Enum.AutomaticSize.Y
collection.CanvasSize = UDim2.new()
collection.Parent = panel
local grid = Instance.new("UIGridLayout", collection)
grid.CellPadding = UDim2.fromOffset(12, 12)
grid.SortOrder = Enum.SortOrder.LayoutOrder
local function resizeGrid()
 local width = collection.AbsoluteSize.X - 6
 local columns = width >= 550 and 3 or 2
 grid.CellSize = UDim2.fromOffset(math.floor((width - 12 * (columns - 1)) / columns), 196)
end
collection:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeGrid)
resizeGrid()
local back = Instance.new("TextButton")
back.Name = "BackToCollection"
back.Position = UDim2.fromOffset(16, 72)
back.Size = UDim2.fromOffset(120, 32)
back.Text = "< Mascotas"
styleButton(back, Color3.fromRGB(65, 105, 105))
back.Visible = false
back.Parent = panel
local catalog = Instance.new("TextButton")
catalog.Name = "CollectionFilter"
catalog.AnchorPoint = Vector2.new(0, 1)
catalog.Position = UDim2.new(0, 16, 1, -12)
catalog.Size = UDim2.new(1, -32, 0, 32)
catalog.Text = "Ver mascotas disponibles"
styleButton(catalog, Color3.fromRGB(55, 90, 110))
catalog.Parent = panel
local empty = label(panel, "EmptyCollection", UDim2.fromOffset(20, 82), UDim2.new(1, -40, 0, 32), 15)
empty.Text = "Todavia no tienes mascotas"
local tiles = {}
local showAvailable = false
local function refreshCollection()
 local visibleCount = 0
 for species, item in pairs(tiles) do
  item.tile.PetName.Text = definitions[species].name .. " x" .. tostring(player:GetAttribute(definitions[species].id .. "Count") or 0)
  local owned = petAttribute(player, "OwnsTestPet", species) == true
  local equipped = petAttribute(player, "TestPetEquipped", species)
  local farm = petAttribute(player, "TestPetInFarm", species)
  item.tile.Visible = showAvailable and not owned or (not showAvailable and owned)
  if item.tile.Visible then visibleCount += 1 end
  item.state.Text = not owned and "No obtenida" or (equipped and "Equipada" or (farm and "En granja" or "En inventario"))
  item.rate.Text = definitions[species].rarity .. " | +" .. tostring((owned and (equipped or farm)) and definitions[species].rate or 0) .. "/s"
 item.rate.TextColor3 = definitions[species].color
 end
 empty.Visible = collection.Visible and visibleCount == 0
 empty.Text = showAvailable and "Ya tienes todas las mascotas" or "Todavia no tienes mascotas"
end
showCollection = function()
 card.Visible = false
 back.Visible = false
 collection.Visible = true
 catalog.Visible = true
 refreshCollection()
end
back.Activated:Connect(showCollection)
catalog.Activated:Connect(function()
 showAvailable = not showAvailable
 catalog.Text = showAvailable and "Ver mis mascotas" or "Ver mascotas disponibles"
 refreshCollection()
end)
local function selectPet(species)
 selectedPet = species
 previewPet:Destroy()
 previewPet = makePet(previewWorld, species)
 previewCamera.CFrame = CFrame.lookAt(species ~= "Chicken" and Vector3.new(4, 2.5, -8) or Vector3.new(3, 2, -6), Vector3.new(0, 0.3, 0))
 refresh()
 card.Visible = true
 back.Visible = true
 collection.Visible = false
 catalog.Visible = false
 empty.Visible = false
end
for index, species in ipairs(speciesOrder) do
 local tile = Instance.new("TextButton")
 tile.Name = species .. "Card"
 tile.Text = ""
 tile.LayoutOrder = index
 styleButton(tile, Color3.fromRGB(48, 66, 60))
 tile.Parent = collection
 local portrait = preview:Clone()
 portrait:ClearAllChildren()
 portrait.Name = "Portrait"
 portrait.Position = UDim2.fromOffset(4, 4)
 portrait.Size = UDim2.new(1, -8, 0, 112)
 portrait.Parent = tile
 local world = Instance.new("WorldModel", portrait)
 local camera = Instance.new("Camera", portrait)
 camera.FieldOfView = 32
 camera.CFrame = CFrame.lookAt(species ~= "Chicken" and Vector3.new(4, 2.5, -8) or Vector3.new(3, 2, -6), Vector3.new(0, 0.3, 0))
 portrait.CurrentCamera = camera
 local model = makePet(world, species)
 local name = label(tile, "PetName", UDim2.fromOffset(8, 119), UDim2.new(1, -16, 0, 22), 17)
 name.Text = definitions[species].name
 name.TextScaled = true
 local limit = Instance.new("UITextSizeConstraint",name)
 limit.MaxTextSize = 17
 local state = label(tile, "State", UDim2.fromOffset(8, 144), UDim2.new(1, -16, 0, 20), 12)
 local rate = label(tile, "Rate", UDim2.fromOffset(8, 168), UDim2.new(1, -16, 0, 20), 12)
 rate.TextColor3 = Color3.fromRGB(255, 218, 105)
 tiles[species] = {tile = tile, state = state, rate = rate, model = model}
 tile.Activated:Connect(function() selectPet(species) end)
end
for _, attribute in ipairs({"TestChickenCount", "TestCowCount", "OwnsTestPet", "TestPetEquipped", "TestPetInFarm", "OwnsCow", "CowEquipped", "CowInFarm"}) do
 player:GetAttributeChangedSignal(attribute):Connect(refreshCollection)
end
showCollection()
for _, definition in pairs(definitions) do
 for _, attribute in ipairs(definition.attributes) do
  player:GetAttributeChangedSignal(attribute):Connect(refresh)
  player:GetAttributeChangedSignal(attribute):Connect(refreshCollection)
 end
 player:GetAttributeChangedSignal(definition.id .. "Count"):Connect(refresh)
 player:GetAttributeChangedSignal(definition.id .. "Count"):Connect(refreshCollection)
end
RunService.RenderStepped:Connect(function(dt)
	if panel.Visible then
		if collection.Visible then
			for _, item in pairs(tiles) do
				if item.tile.Visible then
					item.model:PivotTo(CFrame.Angles(0, math.sin(os.clock() * 0.8) * 0.3, 0))
				end
			end
		end
		previewPet:PivotTo(CFrame.new(0, math.sin(os.clock() * 3) * 0.06, 0)
			* CFrame.Angles(0, math.sin(os.clock() * 0.8) * 0.3, 0))
	end
	for _, other in ipairs(Players:GetPlayers()) do
		for index, species in ipairs(speciesOrder) do
  local key = tostring(other.UserId) .. species
  local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		local farmPosition = petAttribute(other, "TestPetInFarm", species) and petAttribute(other, "TestPetFarmPosition", species)
		local target
		if farmPosition then
			target = CFrame.new(farmPosition) * CFrame.Angles(0, math.sin(os.clock()) * 0.15, 0)
		elseif petAttribute(other, "TestPetEquipped", species) and root then
			target = root.CFrame * CFrame.new(index == 1 and 2.5 or (index == 2 and -3 or -5.5), -1.7 + math.sin(os.clock() * 5) * 0.12, 2)
		end
		if target then
			if not models[key] then
				models[key] = makePet(nil, species)
				models[key]:PivotTo(target)
			end
			models[key]:PivotTo(models[key]:GetPivot():Lerp(target, 1 - math.exp(-12 * dt)))
		elseif models[key] then
			models[key]:Destroy()
			models[key] = nil
		end
	end
end
end)
Players.PlayerRemoving:Connect(function(other)
	for _, species in ipairs(speciesOrder) do
 local key = tostring(other.UserId) .. species
 if models[key] then models[key]:Destroy() models[key] = nil end
 end
end)
]==]

local function install(parent, class, name, source)
	local existing = parent:FindFirstChild(name)
	if existing then
		assert(existing.ClassName == class, "Unexpected instance: " .. name)
		existing.Source = source
	else
		local script = Instance.new(class)
		script.Name = name
		script.Source = source
		script.Parent = parent
	end
end
install(server, "Script", "TestPetService", serverSource)
install(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), "LocalScript", "TestPetClient", clientSource)
return "Installed persistent test pet: equipped and farm states both produce coins."
