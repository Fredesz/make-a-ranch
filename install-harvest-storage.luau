assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
do local parent=game.ReplicatedStorage local s=parent:FindFirstChild("CropCatalog") or Instance.new("ModuleScript") s.Name="CropCatalog" s.Source=[====[local Catalog = {}
Catalog.Crops = {
 Wheat={name="Trigo",seedPrice=3,color=Color3.fromHex("FFD84A")},
 Tomato={name="Tomates",seedPrice=5,color=Color3.fromHex("FF6B6B")},
 Lettuce={name="Lechuga",seedPrice=4,color=Color3.fromHex("75D957")},
 Carrot={name="Zanahorias",seedPrice=4,color=Color3.fromHex("FF9F43")},
}
Catalog.Order={"Wheat","Tomato","Lettuce","Carrot"}
-- Variants are inventory identities. No random special harvests are enabled yet.
Catalog.Variants={Normal={name="Normal"},Gold={name="Oro"},Fire={name="Fuego"}}
function Catalog.Key(crop,variant)
 if not Catalog.Crops[crop] or not Catalog.Variants[variant] then return nil end
 return variant=="Normal" and "Crop"..crop or "Crop"..crop.."_"..variant
end
return Catalog
]====] s.Parent=parent end
do local parent=game.ServerScriptService local s=parent:FindFirstChild("MinimalEconomyService") or Instance.new("Script") s.Name="MinimalEconomyService" s.Source=[====[local CropCatalog=require(game:GetService("ReplicatedStorage"):WaitForChild("CropCatalog"))
-- MinimalEconomyService
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
        -- Preserve extensible crop variants alongside the original normal-crop keys.
        if type(data)=="table" and type(data.farming)=="table" then
         for key,value in pairs(data.farming) do
          if type(key)=="string" and key:match("^Crop%w+_%w+$") and type(value)=="number" and value==value and value<math.huge then
           dataState.farming[key]=math.clamp(math.floor(value),0,1000000)
           player:SetAttribute(key,dataState.farming[key])
          end
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
		return false
	end
	state.dirty = true
	player:SetAttribute("Bait", state.bait)
	return true
end
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

local prices={}
for id,crop in pairs(CropCatalog.Crops) do prices[id]=crop.seedPrice end
local function queueFarmSave(player,state)
 if state.farmSaveQueued then return end
 state.farmSaveQueued=true
 task.delay(3,function()
  state.farmSaveQueued=false
  if dataStateByPlayer[player]==state and player.Parent==Players then
   for attempt=1,3 do
    if saveCoins(player) then return end
    task.wait(attempt*2)
   end
   player:SetAttribute("FarmingMessage","Guardado pendiente; se reintentara automaticamente.")
  end
 end)
end
local farmTransaction=Instance.new("BindableFunction")
farmTransaction.Name="FarmTransaction"
farmTransaction.Parent=script
farmTransaction.OnInvoke=function(player,action,id,variant)
 local state=dataStateByPlayer[player]
 if not state or not state.loaded or not state.canSave then return false,"Cargando datos..." end
 local bag=state.farming
 variant=variant or "Normal"
 local cropKey=id and CropCatalog.Key(id,variant)
 if action=="Harvest" and not cropKey then return false,"Variante desconocida." end
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
  if (bag[cropKey] or 0)>999998 then return false,"Inventario lleno." end
  bag[cropKey]=(bag[cropKey] or 0)+2
 else return false,"Accion desconocida." end
 for key,value in pairs(bag) do player:SetAttribute(key,value) end
 state.dirty=true
 queueFarmSave(player,state)
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
]====] s.Parent=parent end

local Catalog=require(game.ReplicatedStorage.CropCatalog)
local plots=workspace.FarmLayout.Plots
local function part(parent,name,size,cf,color,material)
 local p=Instance.new("Part")
 p.Name=name p.Size=size p.CFrame=cf p.Anchored=true p.Color=color
 p.Material=material or Enum.Material.WoodPlanks p.Parent=parent
 return p
end
for _,plot in ipairs(plots:GetChildren()) do
 local old=plot:FindFirstChild("HarvestStorage")
 if old then old:Destroy() end
 local storage=Instance.new("Model") storage.Name="HarvestStorage" storage.Parent=plot
 local pasture=plot.Pasture
 local rear=pasture:GetAttribute("RearDirection") or 1
 -- Two-by-two cluster in the free front area, clear of the greenhouse and plot entrance.
 for i,crop in ipairs(Catalog.Order) do
  local x=9+((i-1)%2)*8
  local z=-rear*(23+math.floor((i-1)/2)*8)
  local base=pasture.CFrame*CFrame.new(x,pasture.Size.Y/2,z)
  local chest=Instance.new("Model") chest.Name=crop.."Chest" chest:SetAttribute("CropId",crop) chest.Parent=storage
  local wood=Color3.fromHex("8E4D30") local metal=Color3.fromHex("535657")
  local root=part(chest,"Base",Vector3.new(5.4,.35,3.6),base*CFrame.new(0,.35,0),wood)
  chest.PrimaryPart=root
  for _,side in ipairs({-1,1}) do
   part(chest,"Side",Vector3.new(.3,2.3,3.6),base*CFrame.new(side*2.55,1.5,0),wood)
   part(chest,"Wall",Vector3.new(5.4,2.3,.3),base*CFrame.new(0,1.5,side*1.65),wood)
   for _,y in ipairs({.6,2.5}) do
    part(chest,"Band",Vector3.new(5.65,.24,.23),base*CFrame.new(0,y,side*1.83),metal,Enum.Material.Metal)
   end
   for _,x2 in ipairs({-2.2,2.2}) do
    part(chest,"Corner",Vector3.new(.28,2.6,.24),base*CFrame.new(x2,1.5,side*1.83),metal,Enum.Material.Metal)
    for _,y in ipairs({.7,2.3}) do
     local rivet=part(chest,"Rivet",Vector3.new(.17,.17,.12),base*CFrame.new(x2,y,side*1.99),Color3.fromHex("A5A5A1"),Enum.Material.Metal)
     rivet.Shape=Enum.PartType.Ball
    end
   end
  end
  local lid=Instance.new("Model") lid.Name="Lid" lid.Parent=chest
  local hinge=part(lid,"Hinge",Vector3.new(.1,.1,.1),base*CFrame.new(0,2.7,1.7),metal)
  hinge.Transparency=1 hinge.CanCollide=false lid.PrimaryPart=hinge
  part(lid,"WoodLid",Vector3.new(5.5,.5,3.7),base*CFrame.new(0,2.75,0),wood)
  for _,x2 in ipairs({-2.2,2.2}) do
   part(lid,"LidBand",Vector3.new(.32,.62,3.8),base*CFrame.new(x2,2.78,0),metal,Enum.Material.Metal)
  end
  part(chest,"Lock",Vector3.new(.6,.75,.25),base*CFrame.new(0,2.25,-1.9),Color3.fromHex("CEAB59"),Enum.Material.Metal)
  part(chest,"CropBadge",Vector3.new(1.2,.7,.15),base*CFrame.new(0,1.25,-1.86),Catalog.Crops[crop].color,Enum.Material.SmoothPlastic)
  local gui=Instance.new("BillboardGui") gui.Name="Contents" gui.Size=UDim2.fromOffset(185,85) gui.StudsOffsetWorldSpace=Vector3.new(0,4,0) gui.MaxDistance=26 gui.Parent=root
  local label=Instance.new("TextLabel") label.Name="Summary" label.Size=UDim2.fromScale(1,1) label.BackgroundColor3=Color3.fromHex("233447") label.BackgroundTransparency=.2 label.TextColor3=Color3.new(1,1,1) label.Font=Enum.Font.GothamBold label.TextSize=14 label.Text=Catalog.Crops[crop].name label.Parent=gui
  Instance.new("UICorner",label).CornerRadius=UDim.new(0,6)
  local prompt=Instance.new("ProximityPrompt") prompt.Name="Inspect" prompt.ActionText="Ver almacen" prompt.ObjectText=Catalog.Crops[crop].name prompt.HoldDuration=.2 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Parent=root
 end
end
do local parent=game.ServerScriptService local s=parent:FindFirstChild("HarvestStorageService") or Instance.new("Script") s.Name="HarvestStorageService" s.Source=[====[
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Catalog=require(game.ReplicatedStorage.CropCatalog)
for _,plot in ipairs(workspace.FarmLayout.Plots:GetChildren()) do
 local storage=plot:FindFirstChild("HarvestStorage")
 if not storage then continue end
 local connection
 local function refresh()
  local owner=Players:GetPlayerByUserId(plot:GetAttribute("OwnerUserId") or 0)
  for _,chest in ipairs(storage:GetChildren()) do
   local crop=chest:GetAttribute("CropId")
   local lines={Catalog.Crops[crop].name}
   if not owner then table.insert(lines,"Sin propietario")
   elseif not owner:GetAttribute("EconomyDataLoaded") then table.insert(lines,"Cargando...")
   else
    table.insert(lines,"Normal: "..tostring(owner:GetAttribute(Catalog.Key(crop,"Normal")) or 0))
    if chest:GetAttribute("Open") then
     for variant,definition in pairs(Catalog.Variants) do
      if variant~="Normal" then
       local count=owner:GetAttribute(Catalog.Key(crop,variant)) or 0
       if count>0 then table.insert(lines,definition.name..": "..count) end
      end
     end
    end
   end
   chest.Base.Contents.Summary.Text=table.concat(lines,"\n")
  end
 end
 local closers={}
 local function bind()
  if connection then connection:Disconnect() connection=nil end
  for _,close in ipairs(closers) do close() end
  local owner=Players:GetPlayerByUserId(plot:GetAttribute("OwnerUserId") or 0)
  if owner then connection=owner.AttributeChanged:Connect(refresh) end
  refresh()
 end
 for _,chest in ipairs(storage:GetChildren()) do
  local lid=chest.Lid local closed=lid:GetPivot() local busy=false
  local angle=Instance.new("NumberValue")
  angle.Parent=chest
  angle.Changed:Connect(function(value) lid:PivotTo(closed*CFrame.Angles(value,0,0)) end)
  local prompt=chest.Base.Inspect
  table.insert(closers,function() angle.Value=0 chest:SetAttribute("Open",false) end)
  prompt.Triggered:Connect(function(player)
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   local human=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
   if busy or plot:GetAttribute("OwnerUserId")~=player.UserId or not root or not human or human.Health<=0 or (root.Position-chest.Base.Position).Magnitude>12 then return end
   busy=true
   local open=not chest:GetAttribute("Open") chest:SetAttribute("Open",open)
   prompt.ActionText=open and "Cerrar almacen" or "Ver almacen"
   refresh()
   local tween=TweenService:Create(angle,TweenInfo.new(.3),{Value=open and -math.pi*.55 or 0})
   tween:Play() tween.Completed:Wait() busy=false
  end)
 end
 plot:GetAttributeChangedSignal("OwnerUserId"):Connect(bind)
 bind()
end
]====] s.Parent=parent end

