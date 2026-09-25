-- Installs the cartoon seed shop and bait crafting menu.
local client = game:GetService("StarterPlayer").StarterPlayerScripts:WaitForChild("FarmHudClient")
client.Source = [====[
local player = game.Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local remote = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FarmingAction")
local catalog = require(game.ReplicatedStorage:WaitForChild("CropCatalog"))
local crops = catalog.Order
local gui = Instance.new("ScreenGui")
gui.Name = "FarmHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = pg
local ink = Color3.fromHex("233447")
local gold = Color3.fromHex("FFD84A")
local function round(object, radius)
 local corner = Instance.new("UICorner", object)
 corner.CornerRadius = UDim.new(0, radius or 7)
end
local function label(parent, name, text, pos, size, fontSize)
 local t = Instance.new("TextLabel")
 t.Name = name t.Text = text t.Position = pos t.Size = size
 t.BackgroundTransparency = 1 t.TextColor3 = Color3.new(1,1,1)
 t.Font = Enum.Font.GothamBold t.TextSize = fontSize or 14
 t.TextWrapped = true t.Parent = parent
 return t
end
local function button(parent, name, text, pos, size, color)
 local b = Instance.new("TextButton")
 b.Name=name b.Text=text b.Position=pos b.Size=size b.BackgroundColor3=color
 b.BorderSizePixel=0 b.TextColor3=Color3.new(1,1,1) b.Font=Enum.Font.GothamBold
 b.TextSize=14 b.Parent=parent round(b,6)
 return b
end
local bait=button(gui,"CraftBait","Cebos",UDim2.fromOffset(18,172),UDim2.fromOffset(188,38),Color3.fromHex("8B5CFF"))
local seeds=button(gui,"Seeds","Semillas",UDim2.fromOffset(18,218),UDim2.fromOffset(188,38),Color3.fromHex("4D8540"))
local panel=Instance.new("Frame")
panel.Name="FarmPanel" panel.AnchorPoint=Vector2.new(.5,.5) panel.Position=UDim2.fromScale(.5,.5)
panel.Size=UDim2.new(.92,0,.82,0) panel.BackgroundColor3=ink panel.BorderSizePixel=0
panel.Visible=false panel.Parent=gui round(panel,8)
local limit=Instance.new("UISizeConstraint",panel) limit.MaxSize=Vector2.new(640,420)
local title=label(panel,"Title","Semillas",UDim2.fromOffset(18,10),UDim2.new(1,-76,0,30),22)
title.TextXAlignment=Enum.TextXAlignment.Left
local summary=label(panel,"Summary","",UDim2.fromOffset(18,42),UDim2.new(1,-36,0,20),13)
summary.TextXAlignment=Enum.TextXAlignment.Left summary.TextColor3=Color3.fromRGB(187,208,218)
local close=button(panel,"Close","X",UDim2.new(1,-46,0,12),UDim2.fromOffset(34,34),Color3.fromRGB(65,83,77))
close.Activated:Connect(function() panel.Visible=false end)
local list=Instance.new("ScrollingFrame",panel)
list.Name="Cards" list.Position=UDim2.fromOffset(16,74) list.Size=UDim2.new(1,-32,1,-90)
list.BackgroundTransparency=1 list.BorderSizePixel=0 list.ScrollBarThickness=4
list.AutomaticCanvasSize=Enum.AutomaticSize.Y list.CanvasSize=UDim2.new()
local grid=Instance.new("UIGridLayout",list)
grid.CellPadding=UDim2.fromOffset(12,12) grid.SortOrder=Enum.SortOrder.LayoutOrder
local mode="Seeds"
local function resize()
 local width=math.max(1,list.AbsoluteSize.X-6)
 local columns= mode=="Seeds" and (width>=550 and 4 or (width>=280 and 2 or 1)) or 1
 grid.CellSize=UDim2.fromOffset(math.floor((width-12*(columns-1))/columns),mode=="Seeds" and 254 or 310)
end
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
local function part(world,name,size,pos,color,oval)
 local p=Instance.new("Part")
 p.Name=name p.Size=size p.CFrame=CFrame.new(pos) p.Color=color
 p.Anchored=true p.CanCollide=false p.Material=Enum.Material.SmoothPlastic
 if oval then local mesh=Instance.new("SpecialMesh",p) mesh.MeshType=Enum.MeshType.Sphere end
 p.Parent=world return p
end
local function preview(parent,id,isBait)
 local view=Instance.new("ViewportFrame",parent)
 view.Name="Preview" view.Position=UDim2.fromOffset(6,6)
 view.Size=isBait and UDim2.new(.42,-12,0,166) or UDim2.new(1,-12,0,112)
 view.BackgroundTransparency=1 view.Ambient=Color3.fromRGB(220,220,220)
 view.LightColor=Color3.fromRGB(255,250,227) view.LightDirection=Vector3.new(-1,-1,-2)
 local world=Instance.new("WorldModel",view)
 local color=isBait and Color3.fromHex("FF6B6B") or catalog.Crops[id].color
 if isBait then
  part(world,"BaitBall",Vector3.new(1.65,1.5,1.5),Vector3.new(0,0,0),Color3.fromHex("F2C66D"),true)
  for i=1,9 do local a=i*2.4 part(world,"Ingredient",Vector3.new(.26,.28,.18),Vector3.new(math.sin(a)*.63,math.cos(a)*.57,-.64),i%2==0 and Color3.fromHex("75D957") or color,true) end
  part(world,"Leaf",Vector3.new(.7,.2,.4),Vector3.new(.2,.85,0),Color3.fromHex("75D957"),true)
 else
  part(world,"SeedPacket",Vector3.new(1.3,1.75,.3),Vector3.zero,Color3.fromRGB(247,249,237))
  part(world,"TopBand",Vector3.new(1.33,.23,.34),Vector3.new(0,.7,0),color)
  part(world,"BottomBand",Vector3.new(1.33,.18,.34),Vector3.new(0,-.74,0),color)
  if id=="Tomato" then
   part(world,"Tomato",Vector3.new(.8,.75,.28),Vector3.new(0,0,-.25),color,true)
   for i=-1,1 do local leaf=part(world,"Leaf",Vector3.new(.16,.4,.08),Vector3.new(i*.13,.35,-.4),Color3.fromHex("75D957"),true) leaf.CFrame*=CFrame.Angles(0,0,i*.8) end
  elseif id=="Lettuce" then
   for i=1,7 do local a=i*math.pi*2/7 part(world,"Leaf",Vector3.new(.45,.48,.18),Vector3.new(math.sin(a)*.22,math.cos(a)*.2,-.3),color,true) end
   part(world,"Heart",Vector3.new(.45,.48,.2),Vector3.new(0,.05,-.42),Color3.fromHex("A7F05A"),true)
  elseif id=="Carrot" then
   local root=part(world,"Carrot",Vector3.new(.36,.85,.23),Vector3.new(0,-.08,-.3),color,true) root.CFrame*=CFrame.Angles(0,0,-.3)
   for i=-1,1 do local leaf=part(world,"Leaf",Vector3.new(.12,.4,.09),Vector3.new(i*.12,.44,-.35),Color3.fromHex("75D957"),true) leaf.CFrame*=CFrame.Angles(0,0,-i*.4) end
  else
   for x=-1,1 do
    part(world,"Stem",Vector3.new(.04,.85,.08),Vector3.new(x*.22,-.02,-.23),Color3.fromHex("75D957"))
    for y=0,3 do part(world,"Grain",Vector3.new(.19,.22,.15),Vector3.new(x*.22,.1+y*.14,-.33),gold,true) end
   end
  end
 end
 local camera=Instance.new("Camera",view)
 camera.FieldOfView=32 camera.CFrame=CFrame.lookAt(Vector3.new(2,1.15,-5),Vector3.zero)
 view.CurrentCamera=camera
 return view
end
local function card(name,order)
 local frame=Instance.new("Frame",list)
 frame.Name=name frame.LayoutOrder=order frame.BackgroundColor3=Color3.fromRGB(45,64,56)
 frame.BorderSizePixel=0 round(frame,7)
 return frame
end
local rows={}
local lastRequest=0
local function request(action,id)
 if os.clock()-lastRequest<.35 then return end
 lastRequest=os.clock() remote:FireServer(action,id)
end
for i,id in ipairs(crops) do
 local c=catalog.Crops[id]
 local tile=card(id.."SeedCard",i)
 preview(tile,id,false)
 local name=label(tile,"Name",c.name,UDim2.fromOffset(8,121),UDim2.new(1,-16,0,24),17)
 local stock=label(tile,"Stock","",UDim2.fromOffset(8,149),UDim2.new(1,-16,0,18),12)
 local harvest=label(tile,"Harvest","",UDim2.fromOffset(8,171),UDim2.new(1,-16,0,18),12)
 harvest.TextColor3=Color3.fromRGB(187,208,190)
 local buy=button(tile,"PurchaseSeed","",UDim2.fromOffset(8,207),UDim2.new(1,-16,0,36),gold)
 buy.TextColor3=ink
 buy.Activated:Connect(function() request("BuySeed",id) end)
 rows[id]={tile=tile,stock=stock,harvest=harvest,buy=buy}
end
local craft=card("BaitCard",5)
preview(craft,nil,true)
label(craft,"Name","Cebo vegetal",UDim2.new(.44,0,0,12),UDim2.new(.56,-12,0,28),19)
local baitStock=label(craft,"Stock","",UDim2.new(.44,0,0,45),UDim2.new(.56,-12,0,22),14)
baitStock.TextColor3=gold
local ingredients={}
for i,id in ipairs(crops) do
 local t=label(craft,id.."Ingredient","",UDim2.new(.44,0,0,76+(i-1)*24),UDim2.new(.56,-12,0,22),13)
 t.TextXAlignment=Enum.TextXAlignment.Left
 ingredients[id]=t
end
local recipe=label(craft,"Recipe","1 de cada cultivo = 1 cebo",UDim2.fromOffset(12,189),UDim2.new(1,-24,0,28),14)
local make=button(craft,"CraftAction","Fabricar 1 cebo",UDim2.fromOffset(12,236),UDim2.new(1,-24,0,40),gold)
make.TextColor3=ink
local ready=false
make.Activated:Connect(function() if ready then request("Craft") end end)
local function refresh()
 title.Text=mode=="Seeds" and "Semillas" or "Cebos"
 summary.Text=mode=="Seeds" and "Semillas para tu invernadero" or "Taller de cebos"
 for _,id in ipairs(crops) do
  local row=rows[id] local c=catalog.Crops[id]
  row.tile.Visible=mode=="Seeds"
  row.stock.Text="Semillas: "..tostring(player:GetAttribute("Seed"..id) or 0)
  row.harvest.Text="Cosecha: "..tostring(player:GetAttribute("Crop"..id) or 0)
  row.buy.Text="Comprar · "..c.seedPrice
 end
 craft.Visible=mode=="Craft"
 ready=true
 for _,id in ipairs(crops) do
  local count=player:GetAttribute("Crop"..id) or 0
  ingredients[id].Text=catalog.Crops[id].name..": "..count.." / 1"
  ingredients[id].TextColor3=count>=1 and Color3.fromHex("A7F05A") or Color3.fromHex("FF9292")
  if count<1 then ready=false end
 end
 baitStock.Text="Disponibles: "..tostring(player:GetAttribute("Bait") or 0)
 make.Text=ready and "Fabricar 1 cebo" or "Faltan ingredientes"
 make.Active=ready make.AutoButtonColor=ready
 make.BackgroundColor3=ready and gold or Color3.fromRGB(79,93,103)
 make.TextColor3=ready and ink or Color3.fromRGB(209,217,224)
end
local function toggle(nextMode)
 local same=panel.Visible and mode==nextMode
 mode=nextMode panel.Visible=not same list.CanvasPosition=Vector2.zero
 refresh() resize()
 if panel.Visible then
  local pet=pg:FindFirstChild("TestPetGui")
  if pet and pet:FindFirstChild("PetInventoryPanel") then pet.PetInventoryPanel.Visible=false end
  local expedition=pg:FindFirstChild("ExpeditionCatalog")
  if expedition then expedition.Enabled=false end
 end
end
bait.Activated:Connect(function() toggle("Craft") end)
seeds.Activated:Connect(function() toggle("Seeds") end)
player.AttributeChanged:Connect(refresh)
task.spawn(function()
 local pet=pg:WaitForChild("TestPetGui"):WaitForChild("PetInventoryPanel")
 pet:GetPropertyChangedSignal("Visible"):Connect(function() if pet.Visible then panel.Visible=false end end)
 local expedition=pg:WaitForChild("ExpeditionCatalog")
 expedition:GetPropertyChangedSignal("Enabled"):Connect(function() if expedition.Enabled then panel.Visible=false end end)
end)
refresh() resize()
local function align(b,y)b.Position=UDim2.fromOffset(18,y)b.Size=UDim2.fromOffset(188,38)end
task.spawn(function()align(pg:WaitForChild("TestPetGui"):WaitForChild("OpenPetInventoryButton"),80)align(pg:WaitForChild("ExpeditionGui"):WaitForChild("ExpeditionButton"),126)end)
task.spawn(function()
 local coin=pg:WaitForChild("EconomyGui"):WaitForChild("CoinPanel") coin.Size=UDim2.fromOffset(188,52) coin.BackgroundTransparency=1 for _,v in ipairs(coin:GetChildren()) do if v:IsA("UIStroke") then v.Enabled=false end end
 local test=coin:FindFirstChild("ClaimTestCoinsButton") if test then test.Visible=false end
 local number=coin:WaitForChild("CoinLabel") number.Position=UDim2.fromOffset(46,8) number.Size=UDim2.fromOffset(142,36) number.TextColor3=Color3.fromHex("FFD84A") number.TextStrokeColor3=Color3.new(0,0,0) number.TextStrokeTransparency=0 number.TextSize=25
 local old=coin:FindFirstChild("GoldCoinIcon") if old then old:Destroy()end
 local icon=Instance.new("TextLabel",coin) icon.Name="GoldCoinIcon" icon.Position=UDim2.fromOffset(2,8) icon.Size=UDim2.fromOffset(36,36) icon.BackgroundColor3=Color3.fromHex("FFD84A") icon.Text="$" icon.TextColor3=Color3.fromHex("8B5400") icon.Font=Enum.Font.GothamBlack icon.TextSize=25
 Instance.new("UICorner",icon).CornerRadius=UDim.new(1,0) local rim=Instance.new("UIStroke",icon)rim.Color=Color3.fromHex("5A3500")rim.Thickness=2
end)

]====]
print("Cartoon farming menus installed")

