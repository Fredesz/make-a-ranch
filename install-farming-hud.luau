-- Apply in Edit mode after the existing game installers. Preserves greenhouse geometry.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play first")
do
 local parent=game.ServerScriptService
 local s=parent:FindFirstChild("MinimalEconomyService") or Instance.new("Script")
 s.Name="MinimalEconomyService"
 s.Source=[====[-- MinimalEconomyService
-- The server owns coin balances. Client buttons can only request trusted server rewards.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local claimCoinsRemote = remotesFolder:WaitForChild("ClaimTestCoins")
local coinStore = DataStoreService:GetDataStore("FarmRngTycoon_EconomyProfiles_v1")

local STARTING_COINS = 0
local TEST_CLAIM_REWARD = 10
local TEST_CLAIM_COOLDOWN_SECONDS = 1.5

local lastClaimByPlayer = {}
local dataStateByPlayer = {}
local upgrades = {
 Slots = {attribute="InventoryLevel", max=3, price=200},
 Bait = {attribute="BaitLevel", max=2, price=300},
 Luck = {attribute="LuckLevel", max=5, price=250},
 Zone = {attribute="ZoneLevel", max=1, price=600},
}
local function publishProgress(player, state)
 for key, definition in pairs(upgrades) do
  player:SetAttribute(definition.attribute, state.progress[key])
 end
 player:SetAttribute("InventoryCapacity",10 + state.progress.Slots * 10)
end

local function getCoinsValue(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local coins = leaderstats:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = STARTING_COINS
		coins.Parent = leaderstats
	end

	return coins
end

local function setCoins(player, amount)
	local coins = getCoinsValue(player)
	coins.Value = math.max(0, math.floor(amount))
	player:SetAttribute("Coins", coins.Value)
	return coins.Value
end

local function saveCoins(player)
	local dataState = dataStateByPlayer[player]
	if not dataState or not dataState.loaded or not dataState.canSave then
		return false
	end
	local coins = getCoinsValue(player)
	while dataState.saving do task.wait(0.05) end
	dataState.saving = true
	local success, err = pcall(function()
		coinStore:UpdateAsync("Player_" .. player.UserId, function(oldData)
			local data = type(oldData) == "table" and oldData or {}
			data.farming = table.clone(dataState.farming or {})
			data.version = 1
			data.coins = coins.Value
			data.bait = dataState.bait or 0
			data.progress = table.clone(dataState.progress)
			data.preferredPlotId = player:GetAttribute("PreferredPlotId") or player:GetAttribute("AssignedPlotId") or 0
			return data
		end)
	end)
	dataState.saving = false
	if not success then
		warn("[Economy] Could not save coins for " .. player.Name .. ": " .. tostring(err))
		return false
	end
	dataState.dirty = false
	return true
end

local function addCoins(player, amount, reason)
	if typeof(amount) ~= "number" or amount <= 0 then
		warn("Ignored invalid coin award for " .. player.Name .. ": " .. tostring(amount))
		return 0
	end

	local coins = getCoinsValue(player)
	local newBalance = setCoins(player, coins.Value + amount)
	local dataState = dataStateByPlayer[player]
	if dataState then dataState.dirty = true end
	print(("[Economy] Awarded %d coins to %s for %s. Balance: %d"):format(amount, player.Name, reason or "unknown", newBalance))
	return newBalance
end

local function canClaimTestCoins(player)
	local now = os.clock()
	local lastClaim = lastClaimByPlayer[player] or 0
	if now - lastClaim < TEST_CLAIM_COOLDOWN_SECONDS then
		return false
	end

	lastClaimByPlayer[player] = now
	return true
end

local function onPlayerAdded(player)
	if dataStateByPlayer[player] then return end
	local dataState = {loaded = false, canSave = false, dirty = false}
	dataStateByPlayer[player] = dataState
	setCoins(player, STARTING_COINS)
	player:SetAttribute("EconomyDataLoaded", false)
	local success, data = pcall(function()
		return coinStore:GetAsync("Player_" .. player.UserId)
	end)
	for attempt = 1, 2 do
		if success then break end
		task.wait(attempt)
		success, data = pcall(function() return coinStore:GetAsync("Player_" .. player.UserId) end)
	end
	if player.Parent ~= Players then dataStateByPlayer[player] = nil return end
	if success then
		local savedCoins = type(data) == "table" and tonumber(data.coins) or nil
		setCoins(player, savedCoins or STARTING_COINS)
		dataState.bait = math.max(0, math.floor(type(data) == "table" and tonumber(data.bait) or 0))
		player:SetAttribute("Bait", dataState.bait)
		dataState.farming = {}
        for _,id in ipairs({"Wheat","Tomato","Lettuce","Carrot"}) do
         for _,prefix in ipairs({"Seed","Crop"}) do
          local key=prefix..id
          local value=type(data)=="table" and type(data.farming)=="table" and tonumber(data.farming[key]) or 0
          dataState.farming[key]=math.clamp(math.floor(value or 0),0,1000000)
          player:SetAttribute(key,dataState.farming[key])
         end
        end
        dataState.canSave = true
		dataState.progress = {}
		for key, definition in pairs(upgrades) do
			local value = type(data) == "table" and type(data.progress) == "table" and tonumber(data.progress[key]) or 0
			dataState.progress[key] = math.clamp(math.floor(value or 0),0,definition.max)
		end
		publishProgress(player, dataState)
		player:SetAttribute("PreferredPlotId",type(data) == "table" and tonumber(data.preferredPlotId) or 0)
	else
		warn("[Economy] Could not load coins for " .. player.Name .. ": " .. tostring(data))
		player:Kick("No se pudo cargar tu progreso. Vuelve a entrar para proteger tus datos.")
		return
	end
	dataState.loaded = true
	player:SetAttribute("EconomyDataLoaded", true)
end

local function onPlayerRemoving(player)
	saveCoins(player)
	lastClaimByPlayer[player] = nil
	dataStateByPlayer[player] = nil
end

local function onClaimTestCoins(player)
	local dataState = dataStateByPlayer[player]
	if not dataState or not dataState.loaded then
		return
	end
	if not canClaimTestCoins(player) then
		return
	end

	addCoins(player, TEST_CLAIM_REWARD, "temporary test button")
end

Players.PlayerAdded:Connect(onPlayerAdded)
local baitTransaction = Instance.new("BindableFunction")
baitTransaction.Name = "BaitTransaction"
baitTransaction.Parent = script
baitTransaction.OnInvoke = function(player, action)
	local state = dataStateByPlayer[player]
	if not state or not state.loaded or not state.canSave then return false end
	if action == "Buy" then return false
	elseif action == "__DisabledBuy" then
		local coins = getCoinsValue(player)
		if coins.Value < 10 then return false end
		setCoins(player, coins.Value - 10)
		state.bait += 1
	elseif action == "Consume" then
		if state.bait < 1 then return false end
		state.bait -= 1
	elseif action == "Refund" then
		state.bait += 1
	else
		local key = type(action) == "string" and action:match("^Upgrade:(%w+)$")
		local definition = key and upgrades[key]
		if not definition then return false end
		local level = state.progress[key]
		local cost = definition.price * (level + 1)
		if level >= definition.max or getCoinsValue(player).Value < cost then return false end
		setCoins(player,getCoinsValue(player).Value - cost)
		state.progress[key] = level + 1
		publishProgress(player,state)
	end
	state.dirty = true
	player:SetAttribute("Bait", state.bait)
	return true
end
local upgradeRemote = remotesFolder:FindFirstChild("BuyProgressUpgrade") or Instance.new("RemoteEvent")
upgradeRemote.Name = "BuyProgressUpgrade"
upgradeRemote.Parent = remotesFolder
upgradeRemote.OnServerEvent:Connect(function(player,key)
 local state = dataStateByPlayer[player]
 if not state or type(key) ~= "string" or not upgrades[key] then return end
 if os.clock() - (state.lastUpgrade or -math.huge) < 0.6 then return end
 state.lastUpgrade = os.clock()
 local ok = baitTransaction:Invoke(player,"Upgrade:" .. key)
 player:SetAttribute("ProgressMessage",ok and "Mejora comprada." or "Saldo insuficiente, nivel maximo o datos cargando.")
 if ok then task.spawn(saveCoins,player) end
end)
Players.PlayerRemoving:Connect(onPlayerRemoving)
claimCoinsRemote.OnServerEvent:Connect(onClaimTestCoins)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

task.spawn(function()
	while true do
		task.wait(60)
		for player, dataState in pairs(dataStateByPlayer) do
			if dataState.loaded and dataState.canSave then
				task.spawn(saveCoins, player)
			end
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveCoins(player)
	end
end)

local prices={Wheat=3,Tomato=5,Lettuce=4,Carrot=4}
local farmTransaction=Instance.new("BindableFunction")
farmTransaction.Name="FarmTransaction"
farmTransaction.Parent=script
farmTransaction.OnInvoke=function(player,action,id)
 local state=dataStateByPlayer[player]
 if not state or not state.loaded or not state.canSave then return false,"Cargando datos..." end
 local bag=state.farming
 if action=="Craft" then
  for crop in pairs(prices) do if bag["Crop"..crop]<1 then return false,"Necesitas una unidad de cada cultivo." end end
  for crop in pairs(prices) do bag["Crop"..crop]-=1 end
  state.bait+=1
  player:SetAttribute("Bait",state.bait)
 elseif not prices[id] then return false,"Semilla desconocida."
 elseif action=="BuySeed" then
  local coins=getCoinsValue(player)
  if coins.Value<prices[id] then return false,"No tienes suficientes monedas." end
  if bag["Seed"..id]>=1000000 then return false,"Inventario lleno." end
  setCoins(player,coins.Value-prices[id])
  bag["Seed"..id]+=1
 elseif action=="Plant" then
  if bag["Seed"..id]<1 then return false,"Compra semillas en el menu Semillas." end
  bag["Seed"..id]-=1
 elseif action=="Harvest" then
  if bag["Crop"..id]>999998 then return false,"Inventario lleno." end
  bag["Crop"..id]+=2
 else return false,"Accion desconocida." end
 for key,value in pairs(bag) do player:SetAttribute(key,value) end
 state.dirty=true
 return true,action=="Craft" and "Cebo fabricado." or (action=="BuySeed" and "Semilla comprada." or "Listo.")
end
local farmRemote=remotesFolder:FindFirstChild("FarmingAction") or Instance.new("RemoteEvent")
farmRemote.Name="FarmingAction"
farmRemote.Parent=remotesFolder
local lastFarm={}
farmRemote.OnServerEvent:Connect(function(player,action,id)
 if action~="Craft" and action~="BuySeed" then return end
 if type(id)~="string" and id~=nil then return end
 if os.clock()-(lastFarm[player] or -math.huge)<0.35 then return end
 lastFarm[player]=os.clock()
 local ok,message=farmTransaction:Invoke(player,action,id)
 player:SetAttribute("FarmingMessage",message)
end)
Players.PlayerRemoving:Connect(function(player) lastFarm[player]=nil end)
]====]
 s.Parent=parent
end
do
 local parent=game.StarterPlayer.StarterPlayerScripts
 local s=parent:FindFirstChild("MinimalEconomyClient") or Instance.new("LocalScript")
 s.Name="MinimalEconomyClient"
 s.Source=[====[-- MinimalEconomyClient
-- Temporary prototype UI for testing the first coin loop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local claimCoinsRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClaimTestCoins")

local existingGui = player:WaitForChild("PlayerGui"):FindFirstChild("EconomyGui")
if existingGui then
	existingGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "EconomyGui"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local panel = Instance.new("Frame")
panel.Name = "CoinPanel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromOffset(18, 18)
panel.Size = UDim2.fromOffset(210, 86)
panel.BackgroundColor3 = Color3.fromRGB(35, 30, 24)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(237, 190, 82)
stroke.Thickness = 2
stroke.Transparency = 0.2
stroke.Parent = panel

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.BackgroundTransparency = 1
coinLabel.Position = UDim2.fromOffset(14, 10)
coinLabel.Size = UDim2.fromOffset(182, 28)
coinLabel.Font = Enum.Font.GothamBold
coinLabel.Text = "Coins: 0"
coinLabel.TextColor3 = Color3.fromRGB(255, 228, 132)
coinLabel.TextSize = 22
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Parent = panel

local claimButton = Instance.new("TextButton")
claimButton.Name = "ClaimTestCoinsButton"
claimButton.Position = UDim2.fromOffset(14, 44)
claimButton.Size = UDim2.fromOffset(182, 30)
claimButton.BackgroundColor3 = Color3.fromRGB(93, 143, 68)
claimButton.BorderSizePixel = 0
claimButton.Font = Enum.Font.GothamBold
claimButton.Text = "+10 Test Coins"
claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
claimButton.TextSize = 16
claimButton.Parent = panel

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = claimButton

local function updateCoins()
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	coinLabel.Text = tostring(coins and coins.Value or player:GetAttribute("Coins") or 0)
end

local function watchCoins()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		updateCoins()
		return
	end

	local coins = leaderstats:WaitForChild("Coins", 10)
	if coins then
		coins:GetPropertyChangedSignal("Value"):Connect(updateCoins)
	end

	updateCoins()
end

claimButton.Activated:Connect(function()
	claimCoinsRemote:FireServer()
end)

player:GetAttributeChangedSignal("Coins"):Connect(updateCoins)
task.spawn(watchCoins)
updateCoins()
]====]
 s.Parent=parent
end
do
 local parent=game.ServerScriptService
 local s=parent:FindFirstChild("ExpeditionService") or Instance.new("Script")
 s.Name="ExpeditionService"
 s.Source=[====[local Players=game:GetService("Players")
local root=workspace:WaitForChild("ExpeditionZone")
local economy=game.ServerScriptService:WaitForChild("MinimalEconomyService"):WaitForChild("BaitTransaction")
local pets=game.ServerScriptService:WaitForChild("TestPetService")
local state={}
local definitions=require(game.ReplicatedStorage.PetDefinitions)
local rng=Random.new()
local rules=require(game.ReplicatedStorage.ProgressionRules)
local remotes=game.ReplicatedStorage:WaitForChild("Remotes")
local hudRemote=remotes:FindFirstChild("ExpeditionHudAction") or Instance.new("RemoteEvent")
hudRemote.Name="ExpeditionHudAction"
hudRemote.Parent=remotes
local function tell(p,text) p:SetAttribute("ExpeditionMessage",text) end
local function near(p,part)
 local c=p.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local r=c and c:FindFirstChild("HumanoidRootPart")
 return r and h and h.Health>0 and (r.Position-part.Position).Magnitude<=12
end
local function move(p,position)
 if p.Character then p.Character:PivotTo(CFrame.new(position)) end
end
local function action(p,name,fromHud)
 local character=p.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health<=0 then return end
 local s=state[p]
 if not s then s={active=false,last=-math.huge,captured={}} state[p]=s end
 local now=os.clock()
 if now-s.last<0.5 then return end
 local part=root:FindFirstChild(name)
 if not fromHud then
  if not part or not near(p,part:IsA("Model") and part.PrimaryPart or part) then return end
 end
 s.last=now
 if name=="BaitShop" then
  tell(p,"Fabrica cebos con tus cultivos en el menu Cebos.")
 elseif name=="Departure" or name=="Departure2" then
  local zone=name=="Departure2" and 2 or 1
  if zone==2 and (p:GetAttribute("ZoneLevel") or 0)<1 then tell(p,"Desbloquea el Prado azul en Mejoras.") return end
  if s.active then return end
  if (p:GetAttribute("Bait") or 0)<1 then tell(p,"Fabrica un cebo antes de salir.") return end
  s.active=true s.captured={} s.zone=zone
  p:SetAttribute("ExpeditionZoneId",zone)
  p:SetAttribute("InExpedition",true)
  move(p,root:GetAttribute(zone==2 and "Arrival2" or "Arrival"))
  tell(p,"Expedicion iniciada.")
 elseif name=="Return" or name=="Return2" then
  if not s.active then return end
  s.active=false
  p:SetAttribute("InExpedition",false)
  move(p,root:GetAttribute("Home"))
  tell(p,"De vuelta en la granja.")
 elseif part and part:IsA("Model") and s.active then
  if (part:GetAttribute("Zone") or 1)~=s.zone then return end
  if s.captured[name] then tell(p,"Ya capturaste esta mascota en esta expedicion.") return end
  local species=part:GetAttribute("Species")
  local definition=definitions[species]
  if not definition then return end
  local grant=pets:FindFirstChild("Capture"..definition.id)
  if not grant then return end
  local total=0
  for _,id in ipairs({"TestChicken","TestCow","GoldenCow"}) do total += p:GetAttribute(id.."Count") or 0 end
  if total >= (p:GetAttribute("InventoryCapacity") or 10) then tell(p,"Inventario lleno. Amplia los espacios en Mejoras.") return end
  if not economy:Invoke(p,"Consume") then tell(p,"No tienes cebo.") return end
  local chance=rules.Chance(definition.chance,p:GetAttribute("BaitLevel") or 0,p:GetAttribute("LuckLevel") or 0,s.zone)
  if rng:NextNumber() >= chance then
   tell(p,"La mascota escapo del cebo. Puedes intentarlo otra vez.") return
  end
  s.captured[name]=true
  if not grant:Invoke(p) then
   s.captured[name]=nil economy:Invoke(p,"Refund")
   tell(p,"Tu inventario aun no esta listo.") return
  end
  tell(p,definition.name.." capturado. Guardado en tu inventario.")
 end
end
hudRemote.OnServerEvent:Connect(function(p,name)
 if name~="BaitShop" and name~="Departure" and name~="Departure2" and name~="Return" then return end
 action(p,name,true)
end)
for _,part in ipairs(root:GetChildren()) do
 local target=part:IsA("Model") and part.PrimaryPart or part
 local q=target:FindFirstChildOfClass("ProximityPrompt")
 if q then q.Triggered:Connect(function(p) action(p,part.Name) end) end
end
local function joined(p)
 p.CharacterAdded:Connect(function()
  if state[p] then state[p].active=false end
  p:SetAttribute("InExpedition",false)
 end)
end
Players.PlayerAdded:Connect(joined)
for _,p in ipairs(Players:GetPlayers()) do joined(p) end
Players.PlayerRemoving:Connect(function(p) state[p]=nil end)
-- Server-only entry point for integration checks; never exposed as a RemoteEvent.
local check=Instance.new("BindableFunction",script)
check.Name="Interact"
check.OnInvoke=action
]====]
 s.Parent=parent
end
do
 local parent=game.StarterPlayer.StarterPlayerScripts
 local s=parent:FindFirstChild("ExpeditionClient") or Instance.new("LocalScript")
 s.Name="ExpeditionClient"
 s.Source=[====[local p=game.Players.LocalPlayer
local gui=Instance.new("ScreenGui",p:WaitForChild("PlayerGui"))
gui.Name="ExpeditionGui"
gui.ResetOnSpawn=false
local rules=require(game.ReplicatedStorage:WaitForChild("ProgressionRules"))
local definitions=require(game.ReplicatedStorage:WaitForChild("PetDefinitions"))
local remote=game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ExpeditionHudAction")
local function button(name,y,color)
 local b=Instance.new("TextButton")
 b.Name=name
 b.Position=UDim2.fromOffset(18,y)
 b.Size=UDim2.fromOffset(210,42)
 b.BackgroundColor3=color
 b.BorderSizePixel=0
 b.TextColor3=Color3.new(1,1,1)
 b.Font=Enum.Font.GothamBold
 b.TextSize=14
 b.Parent=gui
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
 return b
end
local expedition=button("ExpeditionButton",166,Color3.fromRGB(48,110,150))
local buy=button("BuyBaitButton",214,Color3.fromRGB(66,120,73))
buy.Text="Comprar cebo - 10 monedas"
local lastRequest=-math.huge
local function request(name)
 if os.clock()-lastRequest<0.6 then return end
 lastRequest=os.clock()
 remote:FireServer(name)
end
buy.Visible=false
expedition.Activated:Connect(function()
 p.PlayerGui.ExpeditionCatalog.Enabled=true
end)
local catalog=Instance.new("ScreenGui")
catalog.Name="ExpeditionCatalog"
catalog.DisplayOrder=14
catalog.ResetOnSpawn=false
catalog.Enabled=false
catalog.Parent=p.PlayerGui
local panel=Instance.new("Frame",catalog)
panel.Name="Panel"
panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.Position=UDim2.fromScale(0.5,0.5)
panel.Size=UDim2.new(0.92,0,0.82,0)
panel.BackgroundColor3=Color3.fromRGB(30,43,39)
panel.BorderSizePixel=0
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,8)
local constraint=Instance.new("UISizeConstraint",panel)
constraint.MaxSize=Vector2.new(640,420)
local function label(parent,name,y,height,size)
 local t=Instance.new("TextLabel",parent)
 t.Name=name t.Position=UDim2.fromOffset(12,y)
 t.Size=UDim2.new(1,-24,0,height)
 t.BackgroundTransparency=1 t.TextColor3=Color3.new(1,1,1)
 t.Font=Enum.Font.GothamBold t.TextSize=size
 t.TextXAlignment=Enum.TextXAlignment.Left
 t.TextWrapped=true
 return t
end
local title=label(panel,"Title",10,30,22)
title.Text="Expediciones"
local close=button("CloseCatalog",0,Color3.fromRGB(65,83,77))
close.Parent=panel close.Position=UDim2.new(1,-44,0,8)
close.Size=UDim2.fromOffset(34,34) close.Text="X"
close.Activated:Connect(function() catalog.Enabled=false end)
local list=Instance.new("ScrollingFrame",panel)
list.Name="Zones" list.Position=UDim2.fromOffset(12,52)
list.Size=UDim2.new(1,-24,1,-112)
list.BackgroundTransparency=1 list.BorderSizePixel=0 list.ScrollBarThickness=4
list.AutomaticCanvasSize=Enum.AutomaticSize.Y list.CanvasSize=UDim2.new()
local grid=Instance.new("UIGridLayout",list)
grid.CellPadding=UDim2.fromOffset(12,12)
grid.SortOrder=Enum.SortOrder.LayoutOrder
local function resize()
 local width=list.AbsoluteSize.X-6
 local columns=width<390 and 1 or 2
 grid.CellSize=UDim2.fromOffset(math.floor((width-12*(columns-1))/columns),260)
end
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()
local zoneCards={}
for zone=1,2 do
 local card=Instance.new("Frame",list)
 card.Name="Zone"..zone card.LayoutOrder=zone
 card.BackgroundColor3=Color3.fromRGB(45,64,56) card.BorderSizePixel=0
 Instance.new("UICorner",card).CornerRadius=UDim.new(0,7)
 local preview=Instance.new("ViewportFrame",card)
 preview.Name="Preview" preview.Position=UDim2.fromOffset(6,6)
 preview.Size=UDim2.new(1,-12,0,112) preview.BackgroundTransparency=1
 preview.Ambient=Color3.fromRGB(210,210,210)
 local world=Instance.new("WorldModel",preview)
 local function part(size,pos,color,ball)
  local p=Instance.new("Part",world)
  p.Size=size p.Position=pos p.Anchored=true p.Color=color
  if ball then p.Shape=Enum.PartType.Ball end
 end
 part(Vector3.new(16,1,13),Vector3.zero,zone==1 and Color3.fromRGB(91,151,70) or Color3.fromRGB(75,140,148))
 for _,x in ipairs({-6,6}) do
  for _,z in ipairs({-4,2}) do
   part(Vector3.new(0.5,3,0.5),Vector3.new(x,2,z),Color3.fromRGB(112,84,53))
   part(Vector3.new(3,4,3),Vector3.new(x,4,z),zone==1 and Color3.fromRGB(48,113,65) or Color3.fromRGB(79,162,166),true)
  end
 end
 part(Vector3.new(1.5,2,0.3),Vector3.new(0,1.5,-5),Color3.fromRGB(61,131,116))
 local camera=Instance.new("Camera",preview)
 camera.FieldOfView=40
 camera.CFrame=CFrame.lookAt(Vector3.new(18,18,22),Vector3.new(0,1,0))
 preview.CurrentCamera=camera
 label(card,"Name",124,24,18).Text=zone==1 and "Prado salvaje" or "Prado azul"
 label(card,"Bonus",152,22,13).Text=zone==1 and "Captura base" or "Captura: +10 puntos"
 local status=label(card,"Status",178,22,13)
 status.TextColor3=Color3.fromRGB(240,214,144)
 local travel=button("Travel",0,Color3.fromRGB(48,110,150))
 travel.Parent=card travel.Position=UDim2.fromOffset(12,212)
 travel.Size=UDim2.new(1,-24,0,36)
 zoneCards[zone]={status=status,travel=travel}
 travel.Activated:Connect(function()
  if zone==2 and (p:GetAttribute("ZoneLevel") or 0)<1 then return end
  if p:GetAttribute("InExpedition") or (p:GetAttribute("Bait") or 0)<1 then return end
  request(zone==1 and "Departure" or "Departure2")
 end)
end
local homeButton=button("ReturnFromCatalog",0,Color3.fromRGB(58,119,80))
homeButton.Text="Volver a la granja"
homeButton.Parent=panel homeButton.Position=UDim2.new(0,12,1,-48)
homeButton.Size=UDim2.new(1,-24,0,36)
homeButton.Activated:Connect(function() request("Return") end)
local text=Instance.new("TextLabel",gui)
text.AnchorPoint=Vector2.new(0.5,1)
text.Position=UDim2.new(0.5,0,1,-16)
text.Size=UDim2.new(0.9,0,0,56)
text.BackgroundColor3=Color3.fromRGB(29,47,39)
text.BackgroundTransparency=0.1
text.TextColor3=Color3.new(1,1,1)
text.Font=Enum.Font.GothamMedium
text.TextSize=16
text.TextWrapped=true
Instance.new("UICorner",text).CornerRadius=UDim.new(0,6)
local function refresh()
 expedition.Text="Expediciones"
 local away=p:GetAttribute("InExpedition")
 for zone,item in ipairs(zoneCards) do
  local unlocked=zone==1 or (p:GetAttribute("ZoneLevel") or 0)>0
  item.status.Text=not unlocked and "Desbloquear en Mejoras: 600" or (away and p:GetAttribute("ExpeditionZoneId")==zone and "Estas aqui" or "Disponible")
  item.travel.Text=not unlocked and "Bloqueada" or (away and "Vuelve a la granja" or ((p:GetAttribute("Bait") or 0)<1 and "Necesitas cebo" or "Viajar"))
  item.travel.Active=unlocked and not away and (p:GetAttribute("Bait") or 0)>0
  item.travel.AutoButtonColor=item.travel.Active
 end
 homeButton.Visible=away==true
 text.Text="Cebos: "..tostring(p:GetAttribute("Bait") or 0).."  |  "..(p:GetAttribute("InExpedition") and ((p:GetAttribute("ExpeditionZoneId")==2) and "Prado azul" or "Prado salvaje") or "Granja").."\n"..(p:GetAttribute("ExpeditionMessage") or "")
end
for _,key in ipairs({"Bait","InExpedition","ExpeditionMessage","ExpeditionZoneId","ZoneLevel"}) do p:GetAttributeChangedSignal(key):Connect(refresh) end
p:GetAttributeChangedSignal("InExpedition"):Connect(function() catalog.Enabled=false end)
refresh()
task.spawn(function()
 while gui.Parent do
  task.wait(0.5)
  local root=workspace:FindFirstChild("ExpeditionZone")
  if root then
   for _,animal in ipairs(root:GetChildren()) do
    local species=animal:GetAttribute("Species")
    local definition=species and definitions[species]
    if definition and animal:IsA("Model") and animal.PrimaryPart then
     local billboard=animal.PrimaryPart:FindFirstChildOfClass("BillboardGui")
     local label=billboard and billboard:FindFirstChildOfClass("TextLabel")
     if label then
      local chance=rules.Chance(definition.chance,p:GetAttribute("BaitLevel") or 0,p:GetAttribute("LuckLevel") or 0,animal:GetAttribute("Zone") or 1)
      label.Text=definition.name .. "\n" .. definition.rarity .. " | " .. string.format("%.0f%%",chance*100)
      label.TextColor3=definition.color
     end
    end
   end
  end
 end
end)
]====]
 s.Parent=parent
end
do
 local parent=game.ServerScriptService
 local s=parent:FindFirstChild("GreenhouseFarmService") or Instance.new("Script")
 s.Name="GreenhouseFarmService"
 s.Source=[====[
local plots=workspace.FarmLayout.Plots
local transaction=game.ServerScriptService:WaitForChild("MinimalEconomyService"):WaitForChild("FarmTransaction")
local colors={Wheat=Color3.fromHex("FFD84A"),Tomato=Color3.fromHex("FF6B6B"),Lettuce=Color3.fromHex("75D957"),Carrot=Color3.fromHex("FF9F43")}
for _,plot in ipairs(plots:GetChildren()) do
 local g=plot:FindFirstChild("Greenhouse")
 if not g then continue end
 for _,bed in ipairs(g.Beds:GetChildren()) do
  local prompt=bed.FarmPrompt
  local crop=bed:GetAttribute("Crop") or bed:GetAttribute("CropId")
  local name=bed:GetAttribute("Name") or bed:GetAttribute("CropName")
  local generation=0
  local owner=0
  local function set(state)
   bed:SetAttribute("State",state)
   prompt.Enabled=state~="Growing"
   prompt.ActionText=state=="Ready" and "Cosechar" or "Plantar"
   bed.CropLabel.TextLabel.Text=name.."\n"..(state=="Ready" and "Listo para cosechar" or state=="Growing" and "Creciendo..." or "Listo para plantar")
   local old=bed:FindFirstChild("Plant")
   if old then old:Destroy() end
   if state~="Empty" then
    local plant=Instance.new("Part")
    plant.Name="Plant" plant.Shape=Enum.PartType.Ball
    plant.Size=state=="Ready" and Vector3.new(1.6,2.1,1.6) or Vector3.new(.6,.7,.6)
    plant.CFrame=bed.CFrame*CFrame.new(0,bed.Size.Y/2+plant.Size.Y/2,0)
    plant.Anchored=true plant.CanCollide=false plant.Color=colors[crop] plant.Parent=bed
   end
  end
  set("Empty")
  plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
   generation+=1 owner=0 set("Empty")
  end)
  prompt.Triggered:Connect(function(player)
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   local human=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
   if not root or not human or human.Health<=0 or plot:GetAttribute("OwnerUserId")~=player.UserId or (root.Position-bed.Position).Magnitude>12 then return end
   local state=bed:GetAttribute("State")
   if state=="Empty" then
    local ok,message=transaction:Invoke(player,"Plant",crop)
    player:SetAttribute("FarmingMessage",message)
    if not ok then return end
    owner=player.UserId generation+=1
    local token=generation set("Growing")
    task.delay(12,function() if bed.Parent and token==generation and plot:GetAttribute("OwnerUserId")==owner then set("Ready") end end)
   elseif state=="Ready" and owner==player.UserId then
    local ok,message=transaction:Invoke(player,"Harvest",crop)
    player:SetAttribute("FarmingMessage",ok and "Cosechaste 2 unidades de "..name.."." or message)
    if ok then set("Empty") end
   end
  end)
 end
end
]====]
 s.Parent=parent
end
do
 local parent=game.StarterPlayer.StarterPlayerScripts
 local s=parent:FindFirstChild("FarmHudClient") or Instance.new("LocalScript")
 s.Name="FarmHudClient"
 s.Source=[====[
local player=game.Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local remote=game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FarmingAction")
local gui=Instance.new("ScreenGui")
gui.Name="FarmHud" gui.ResetOnSpawn=false gui.DisplayOrder=20 gui.Parent=pg
local purple=Color3.fromHex("8B5CFF")
local dark=Color3.fromHex("233447")
local function button(parent,name,text,pos,size,color)
 local b=Instance.new("TextButton") b.Name=name b.Text=text b.Position=pos b.Size=size
 b.BackgroundColor3=color b.TextColor3=Color3.new(1,1,1) b.Font=Enum.Font.GothamBold b.TextSize=14
 b.BorderSizePixel=0 b.Parent=parent
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
 return b
end
local craft=button(gui,"CraftBait","Cebos",UDim2.fromOffset(18,176),UDim2.fromOffset(210,42),purple)
local seeds=button(gui,"Seeds","Semillas",UDim2.fromOffset(18,272),UDim2.fromOffset(210,42),Color3.fromHex("4D8540"))
local panel=Instance.new("Frame") panel.Name="ShopPanel" panel.AnchorPoint=Vector2.new(.5,.5)
panel.Position=UDim2.fromScale(.5,.5) panel.Size=UDim2.new(.9,0,.8,0) panel.BackgroundColor3=dark panel.Visible=false panel.Parent=gui
local max=Instance.new("UISizeConstraint",panel) max.MaxSize=Vector2.new(490,440)
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,8)
local function label(parent,name,pos,size)
 local t=Instance.new("TextLabel") t.Name=name t.Position=pos t.Size=size t.BackgroundTransparency=1
 t.TextColor3=Color3.new(1,1,1) t.Font=Enum.Font.GothamBold t.TextSize=15 t.TextWrapped=true t.Parent=parent return t
end
local title=label(panel,"Title",UDim2.fromOffset(16,8),UDim2.new(1,-72,0,36))
title.TextXAlignment=Enum.TextXAlignment.Left title.TextSize=22
button(panel,"Close","X",UDim2.new(1,-46,0,10),UDim2.fromOffset(32,32),purple).Activated:Connect(function() panel.Visible=false end)
local list=Instance.new("ScrollingFrame",panel) list.Position=UDim2.fromOffset(12,55) list.Size=UDim2.new(1,-24,1,-115)
list.BackgroundTransparency=1 list.BorderSizePixel=0 list.ScrollBarThickness=4 list.AutomaticCanvasSize=Enum.AutomaticSize.Y list.CanvasSize=UDim2.new()
local layout=Instance.new("UIListLayout",list) layout.Padding=UDim.new(0,10) layout.SortOrder=Enum.SortOrder.LayoutOrder
local specs={{"Wheat","Trigo",3},{"Tomato","Tomates",5},{"Lettuce","Lechuga",4},{"Carrot","Zanahorias",4}}
local rows={}
for i,d in ipairs(specs) do
 local b=button(list,d[1],"",UDim2.new(),UDim2.new(1,-6,0,58),Color3.fromHex("4D8540"))
 b.LayoutOrder=i b.TextWrapped=true
 b.Activated:Connect(function() remote:FireServer("BuySeed",d[1]) end)
 rows[i]=b
end
local recipe=label(list,"Recipe",UDim2.new(),UDim2.new(1,-6,0,125))
recipe.LayoutOrder=5
local make=button(list,"Make","Fabricar 1 cebo",UDim2.new(),UDim2.new(1,-6,0,44),purple) make.LayoutOrder=6
make.Activated:Connect(function() remote:FireServer("Craft") end)
local message=label(panel,"Message",UDim2.new(0,12,1,-52),UDim2.new(1,-24,0,44))
local toast=label(gui,"FarmMessage",UDim2.fromOffset(18,320),UDim2.fromOffset(210,64))
toast.TextSize=13 toast.TextStrokeTransparency=.3
local mode="Seeds"
local function refresh()
 title.Text=mode=="Seeds" and "Semillas" or "Fabricar cebos"
 for i,d in ipairs(specs) do
  rows[i].Visible=mode=="Seeds"
  rows[i].Text=d[2].." | "..d[3].." monedas\nSemillas: "..(player:GetAttribute("Seed"..d[1]) or 0).." | Cosecha: "..(player:GetAttribute("Crop"..d[1]) or 0)
 end
 recipe.Visible=mode=="Craft" make.Visible=mode=="Craft"
 local lines={"1 de cada cultivo = 1 cebo",""}
 local ready=true
 for _,d in ipairs(specs) do
  local count=player:GetAttribute("Crop"..d[1]) or 0
  table.insert(lines,d[2]..": "..count.." / 1")
  if count<1 then ready=false end
 end
 recipe.Text=table.concat(lines,"\n")
 make.Text=ready and "Fabricar 1 cebo" or "Faltan ingredientes"
 make.Active=ready make.AutoButtonColor=ready
 message.Text=player:GetAttribute("FarmingMessage") or ""
 toast.Text=message.Text
end
craft.Activated:Connect(function() mode="Craft" panel.Visible=not panel.Visible or title.Text~="Fabricar cebos" refresh() end)
seeds.Activated:Connect(function() mode="Seeds" panel.Visible=not panel.Visible or title.Text~="Semillas" refresh() end)
player.AttributeChanged:Connect(refresh)
refresh()
task.spawn(function()
 local economy=pg:WaitForChild("EconomyGui"):WaitForChild("CoinPanel")
 economy.Size=UDim2.fromOffset(210,50) economy.BackgroundTransparency=1
 for _,v in ipairs(economy:GetChildren()) do if v:IsA("UIStroke") then v.Enabled=false end end
 economy:WaitForChild("ClaimTestCoinsButton").Visible=false
 local number=economy:WaitForChild("CoinLabel")
 number.Position=UDim2.fromOffset(46,8) number.Size=UDim2.fromOffset(164,34)
 number.TextColor3=Color3.fromHex("FFD84A") number.TextStrokeColor3=Color3.new() number.TextStrokeTransparency=0 number.TextSize=25
 local icon=label(economy,"CoinIcon",UDim2.fromOffset(0,6),UDim2.fromOffset(40,36))
icon.Text="$" icon.TextSize=24 icon.Font=Enum.Font.GothamBlack
 icon.Size=UDim2.fromOffset(32,32) icon.Position=UDim2.fromOffset(3,8)
 icon.BackgroundTransparency=0 icon.BackgroundColor3=Color3.fromHex("FFD84A")
 icon.TextColor3=Color3.fromHex("9C5F08")
 Instance.new("UICorner",icon).CornerRadius=UDim.new(1,0)
 local rim=Instance.new("UIStroke",icon) rim.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 rim.Color=Color3.fromHex("9C5F08") rim.Thickness=2
end)
local function resize(b,y)
 b.Size=UDim2.fromOffset(210,42) b.Position=UDim2.fromOffset(18,y)
end
task.spawn(function()
 local g=pg:WaitForChild("ExpeditionGui")
 resize(g:WaitForChild("ExpeditionButton"),128)
 g:WaitForChild("BuyBaitButton").Visible=false
end)
task.spawn(function()
 local g=pg:WaitForChild("ProgressionGui")
 resize(g:WaitForChild("Open"),224)
end)
task.spawn(function()
 while true do
  local found
  for _,g in ipairs(pg:GetChildren()) do
   if g:IsA("ScreenGui") then
    for _,b in ipairs(g:GetChildren()) do
     if b:IsA("TextButton") and b.Text=="Mascotas" then resize(b,80) found=true end
    end
   end
  end
  if found then break end
  task.wait(.1)
 end
end)
]====]
 s.Parent=parent
end
