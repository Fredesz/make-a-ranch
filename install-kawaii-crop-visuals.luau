assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
local module=game.ReplicatedStorage:FindFirstChild("CropVisuals") or Instance.new("ModuleScript")
module.Name="CropVisuals" module.Source=[====[local CropVisuals = {}

local COLORS = {
 green=Color3.fromHex("58B947"), lightGreen=Color3.fromHex("8DDD54"),
 darkGreen=Color3.fromHex("318A45"), wheat=Color3.fromHex("F5C84C"),
 paleWheat=Color3.fromHex("FFE38A"), tomato=Color3.fromHex("F0524F"),
 tomatoGreen=Color3.fromHex("72A940"), carrot=Color3.fromHex("F58A35"),
 soil=Color3.fromHex("8F583B"), stake=Color3.fromHex("8A603B"),
}

local function part(parent,name,size,cf,color,shape)
 local p=Instance.new("Part")
 p.Name=name p.Size=size p.CFrame=cf p.Anchored=true
 p.CanCollide=false p.CanTouch=false p.CanQuery=false
 p.Material=Enum.Material.SmoothPlastic p.Color=color
 p.Shape=shape or Enum.PartType.Block p.Parent=parent
 return p
end

local function oval(parent,name,size,cf,color)
 local p=part(parent,name,size,cf,color)
 local mesh=Instance.new("SpecialMesh")
 mesh.MeshType=Enum.MeshType.Sphere mesh.Parent=p
 return p
end

local function variantColor(color,variant)
 if variant=="Gold" then return color:Lerp(Color3.fromHex("FFD33D"),.7) end
 if variant=="Fire" then return color:Lerp(Color3.fromHex("FF5A36"),.55) end
 return color
end

local function wheat(parent,cf,scale,variant)
 local stemColor=variantColor(COLORS.wheat,variant)
 for stemIndex,x in ipairs({-.18,0,.18}) do
  local height=({2.05,2.45,1.85})[stemIndex]*scale
  part(parent,"Stem",Vector3.new(.09,height,.09),cf*CFrame.new(x,height/2,0),stemColor)
  oval(parent,"Leaf",Vector3.new(.12,.65*scale,.22),cf*CFrame.new(x+(stemIndex-2)*.1,height*.45,0)*CFrame.Angles(0,0,(stemIndex-2)*.42),COLORS.lightGreen)
  if scale>.75 then
   for grain=1,5 do
    local side=grain%2==0 and -.09 or .09
    oval(parent,"Grain",Vector3.new(.15,.25,.13),cf*CFrame.new(x+side,height+(grain-3)*.16,0),variantColor(COLORS.paleWheat,variant))
   end
   part(parent,"Awn",Vector3.new(.035,.38,.035),cf*CFrame.new(x,height+.5,0),stemColor)
  end
 end
end

local function tomato(parent,cf,scale,variant)
 part(parent,"Stake",Vector3.new(.16,2.8,.16),cf*CFrame.new(0,1.4,0),COLORS.stake,Enum.PartType.Cylinder).CFrame*=CFrame.Angles(0,0,math.pi/2)
 part(parent,"Vine",Vector3.new(.18,2.35*scale,.18),cf*CFrame.new(0,1.15*scale,.06),COLORS.darkGreen)
 for _,side in ipairs({-1,1}) do
  part(parent,"Branch",Vector3.new(.75*scale,.12,.12),cf*CFrame.new(side*.3,1.15*scale,.06)*CFrame.Angles(0,0,side*.2),COLORS.darkGreen)
  oval(parent,"Leaf",Vector3.new(.55,.18,.38),cf*CFrame.new(side*.62*scale,1.28*scale,.05)*CFrame.Angles(0,side*.5,side*.15),COLORS.green)
 end
 if scale>.75 then
  for _,o in ipairs({Vector3.new(-.35,1.45,-.05),Vector3.new(.38,.95,.02),Vector3.new(.1,1.8,.05)}) do
   oval(parent,"Tomato",Vector3.new(.48,.44,.48),cf*CFrame.new(o),variantColor(COLORS.tomato,variant))
  end
 end
end

local function lettuce(parent,cf,scale,variant)
 local leafColor=variantColor(COLORS.green,variant)
 for i=1,8 do
  local angle=(i-1)*math.pi/4
  local distance=.38*scale
  oval(parent,"OuterLeaf",Vector3.new(.52*scale,.24*scale,.92*scale),cf*CFrame.new(math.cos(angle)*distance,.18*scale,math.sin(angle)*distance)*CFrame.Angles(.2,angle-math.pi/2,0),leafColor)
 end
 for i=1,5 do
  local angle=(i-1)*math.pi*2/5
  oval(parent,"HeartLeaf",Vector3.new(.5*scale,.5*scale,.62*scale),cf*CFrame.new(math.cos(angle)*.17,.42*scale,math.sin(angle)*.17)*CFrame.Angles(0,angle,0),variantColor(COLORS.lightGreen,variant))
 end
end

local function carrot(parent,cf,scale,variant)
 local root=oval(parent,"Root",Vector3.new(.48*scale,1.25*scale,.48*scale),cf*CFrame.new(0,.38*scale,0),variantColor(COLORS.carrot,variant))
 root.CFrame*=CFrame.Angles(0,0,.05)
 for i=-1,1 do
  oval(parent,"TopLeaf",Vector3.new(.16,.8*scale,.28),cf*CFrame.new(i*.17,.95*scale,0)*CFrame.Angles(0,0,i*.3),i==0 and COLORS.lightGreen or COLORS.darkGreen)
 end
end

local builders={Wheat=wheat,Tomato=tomato,Lettuce=lettuce,Carrot=carrot}
local offsets={Vector3.new(-2.25,0,-1.45),Vector3.new(2.25,0,-1.45),Vector3.new(-2.25,0,1.45),Vector3.new(2.25,0,1.45)}

function CropVisuals.Clear(bed)
 local old=bed:FindFirstChild("Plants")
 if old then old:Destroy() end
 local legacy=bed:FindFirstChild("Plant")
 if legacy then legacy:Destroy() end
end

function CropVisuals.Build(bed,crop,state,variant)
 CropVisuals.Clear(bed)
 local builder=builders[crop]
 if not builder or state=="Empty" then return end
 local plants=Instance.new("Model")
 plants.Name="Plants" plants:SetAttribute("CropId",crop)
 plants:SetAttribute("Variant",variant or "Normal") plants.Parent=bed
 local scale=state=="Ready" and 1 or .58
 for i,offset in ipairs(offsets) do
  local plant=Instance.new("Model")
  plant.Name=crop..i plant.Parent=plants
  local cf=bed.CFrame*CFrame.new(offset.X,bed.Size.Y/2,offset.Z)
  builder(plant,cf,scale,variant or "Normal")
 end
end

return CropVisuals
]====] module.Parent=game.ReplicatedStorage
local service=game.ServerScriptService:FindFirstChild("GreenhouseFarmService") or Instance.new("Script")
service.Name="GreenhouseFarmService" service.Source=[====[local Players=game:GetService("Players")
local plots=workspace.FarmLayout.Plots
local transaction=game.ServerScriptService:WaitForChild("MinimalEconomyService"):WaitForChild("FarmTransaction")
local visuals=require(game.ReplicatedStorage:WaitForChild("CropVisuals"))

for _,plot in ipairs(plots:GetChildren()) do
 local greenhouse=plot:FindFirstChild("Greenhouse")
 if not greenhouse then continue end
 for _,bed in ipairs(greenhouse.Beds:GetChildren()) do
  local prompt=bed.FarmPrompt
  local crop=bed:GetAttribute("Crop") or bed:GetAttribute("CropId")
  local name=bed:GetAttribute("Name") or bed:GetAttribute("CropName")
  local generation=0
  local owner=0
  local function setState(state,variant)
   bed:SetAttribute("State",state)
   bed:SetAttribute("CropVariant",variant or "Normal")
   prompt.Enabled=state~="Growing"
   prompt.ActionText=state=="Ready" and "Cosechar" or "Plantar"
   bed.CropLabel.TextLabel.Text=name.."\n"..(state=="Ready" and "Listo para cosechar" or state=="Growing" and "Creciendo..." or "Listo para plantar")
   visuals.Build(bed,crop,state,variant or "Normal")
  end
  setState("Empty")
  plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
   generation+=1 owner=0 setState("Empty")
  end)
  prompt.Triggered:Connect(function(player)
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   local human=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
   if not root or not human or human.Health<=0 or plot:GetAttribute("OwnerUserId")~=player.UserId or (root.Position-bed.Position).Magnitude>12 then return end
   local state=bed:GetAttribute("State")
   if state=="Empty" then
    local variant="Normal"
    local ok,message=transaction:Invoke(player,"Plant",crop)
    player:SetAttribute("FarmingMessage",message)
    if not ok then return end
    owner=player.UserId generation+=1
    local token=generation setState("Growing",variant)
    task.delay(12,function()
     if bed.Parent and token==generation and plot:GetAttribute("OwnerUserId")==owner then setState("Ready",variant) end
    end)
   elseif state=="Ready" and owner==player.UserId then
    local variant=bed:GetAttribute("CropVariant") or "Normal"
    local ok,message=transaction:Invoke(player,"Harvest",crop,variant)
    player:SetAttribute("FarmingMessage",ok and "Cosechaste 2 unidades de "..name.."." or message)
    if ok then setState("Empty") end
   end
  end)
 end
end
]====] service.Parent=game.ServerScriptService
return "Installed kawaii four-plant crop visuals."
