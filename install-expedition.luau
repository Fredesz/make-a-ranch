-- Install after the economy and pet installers, in Edit mode.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play first")
local root = workspace:FindFirstChild("ExpeditionZone")
if root then root:Destroy() end
root = Instance.new("Folder", workspace)
root.Name = "ExpeditionZone"
local function block(name, size, position, color, material)
 local p = Instance.new("Part")
 p.Name = name
 p.Size = size
 p.Position = position
 p.Anchored = true
 p.Color = color
 p.Material = material or Enum.Material.Wood
 p.Parent = root
 return p
end
local function prompt(p, text, object, duration)
 local q = Instance.new("ProximityPrompt")
 q.ActionText = text
 q.ObjectText = object
 q.HoldDuration = duration or 0.3
 q.MaxActivationDistance = 10
 q.RequiresLineOfSight = false
 q.Parent = p
 return q
end
local function sign(p, text)
 local gui = Instance.new("BillboardGui", p)
 gui.Size = UDim2.fromOffset(170, 50)
 gui.MaxDistance = 55
 gui.StudsOffset = Vector3.new(0, 3, 0)
 gui.AlwaysOnTop = false
 local label = Instance.new("TextLabel", gui)
 label.Size = UDim2.fromScale(1,1)
 label.BackgroundColor3 = Color3.fromRGB(28,48,36)
 label.BackgroundTransparency = 0.12
 label.TextColor3 = Color3.new(1,1,1)
 label.TextSize = 14
 label.Font = Enum.Font.GothamBold
 label.TextWrapped = false
 label.TextScaled = true
 local limit = Instance.new("UITextSizeConstraint", label)
 limit.MaxTextSize = 14
 limit.MinTextSize = 10
 label.Text = text
 Instance.new("UICorner",label).CornerRadius = UDim.new(0,6)
end
local spawn = workspace:FindFirstChild("FarmLayout") and workspace.FarmLayout:FindFirstChild("PlayerSpawn")
local home = spawn and spawn.Position or Vector3.new(0,2,0)
root:SetAttribute("Home", home + Vector3.new(0,4,0))
local center = Vector3.new(0,100,900)
block("Meadow",Vector3.new(100,3,90),center,Color3.fromRGB(91,151,70),Enum.Material.Grass)
root:SetAttribute("Arrival",center+Vector3.new(0,5,-32))
local exitPart = block("Return",Vector3.new(4,5,1),center+Vector3.new(0,4,-38),Color3.fromRGB(61,131,116))
prompt(exitPart,"Volver a la granja","Regreso")
sign(exitPart,"VOLVER")
for _, offset in ipairs({Vector3.new(-50,4,0),Vector3.new(50,4,0),Vector3.new(0,4,45),Vector3.new(0,4,-45)}) do
 block("Boundary",Vector3.new(offset.X==0 and 100 or 2,8,offset.X==0 and 2 or 90),center+offset,Color3.fromRGB(106,119,98),Enum.Material.Rock)
end
for i=1,8 do
 local x = i<=4 and -38 or 38
 local z = (i-1)%4 * 18 - 27
 block("Trunk",Vector3.new(2,8,2),center+Vector3.new(x,5,z),Color3.fromRGB(112,84,53))
 local leaves=block("Leaves",Vector3.new(11,12,11),center+Vector3.new(x,12,z),Color3.fromRGB(48,113,65),Enum.Material.Grass)
 leaves.Shape=Enum.PartType.Ball
end
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
local definitions = require(game.ReplicatedStorage.PetDefinitions)
for i, species in ipairs({"Chicken","Cow","GoldenCow"}) do
 local animal = makePet(root,species)
 animal.Name = "Wild"..species
 animal:SetAttribute("Species",species)
 animal:PivotTo(CFrame.new(center+Vector3.new((i-2)*22,2.6,0)))
 prompt(animal.PrimaryPart,"Capturar: 1 cebo",definitions[species].name .. " - " .. definitions[species].rarity,1.5)
 sign(animal.PrimaryPart,definitions[species].name .. "\n" .. definitions[species].rarity .. " | " .. tostring(definitions[species].chance*100) .. "%")
end
local originals = root:GetChildren()
local zoneOffset = Vector3.new(180,0,0)
for _, original in ipairs(originals) do
 local copy = original:Clone()
 copy.Name = original.Name .. "2"
 copy:SetAttribute("Zone",2)
 if copy:IsA("Model") then
  copy:PivotTo(copy:GetPivot() + zoneOffset)
 elseif copy:IsA("BasePart") then
  copy.Position += zoneOffset
  if original.Name == "Meadow" then copy.Color=Color3.fromRGB(75,140,148) end
  if original.Name == "Leaves" then copy.Color=Color3.fromRGB(79,162,166) end
 end
 copy.Parent=root
end
root:SetAttribute("Arrival2", root:GetAttribute("Arrival")+zoneOffset)
local rules = game.ReplicatedStorage:FindFirstChild("ProgressionRules") or Instance.new("ModuleScript")
rules.Name="ProgressionRules"
rules.Source=[==[
local Rules={}
function Rules.Chance(base, baitLevel, luckLevel, zone)
 return math.min(0.95,base * (1+0.25*baitLevel) + 0.02*luckLevel + (zone==2 and 0.1 or 0))
end
return Rules
]==]
rules.Parent=game.ReplicatedStorage
local serverSource = [==[
local Players=game:GetService("Players")
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
  tell(p,economy:Invoke(p,"Buy") and "Compraste 1 cebo." or "Necesitas 10 monedas y tus datos cargados.")
 elseif name=="Departure" or name=="Departure2" then
  local zone=name=="Departure2" and 2 or 1
  if zone==2 and (p:GetAttribute("ZoneLevel") or 0)<1 then tell(p,"Desbloquea el Prado azul en Mejoras.") return end
  if s.active then return end
  if (p:GetAttribute("Bait") or 0)<1 then tell(p,"Compra un cebo antes de salir.") return end
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
]==]
local clientSource = [==[
local p=game.Players.LocalPlayer
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
buy.Activated:Connect(function() request("BaitShop") end)
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
]==]
local function install(parent,class,name,source)
 local s=parent:FindFirstChild(name) or Instance.new(class)
 s.Name=name s.Source=source s.Parent=parent
end
install(game.ServerScriptService,"Script","ExpeditionService",serverSource)
install(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ExpeditionClient",clientSource)
return "Installed bait shop, expedition meadow, and capture loop."
