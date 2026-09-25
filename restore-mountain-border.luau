local root=workspace.FarmLayout
local old=root:FindFirstChild("MountainBorder")
assert(old,"MountainBorder missing")
local history=game:GetService("ChangeHistoryService")
history:SetWaypoint("Before restoring mountain border")
old:Destroy()

local ground=root.Meadow
local groundTop=ground.Position.Y+ground.Size.Y/2
local grassColor=ground.Color
local border=Instance.new("Model")
border.Name="MountainBorder"
border.Parent=root

local function block(name,size,localPosition,color,material,transparent)
	local part=Instance.new("Part")
	part.Name=name
	part.Size=size
	part.CFrame=ground.CFrame*CFrame.new(localPosition)
	part.Anchored=true
	part.CanCollide=not transparent
	part.Color=color
	part.Material=material
	part.Transparency=transparent and 1 or 0
	part.TopSurface=Enum.SurfaceType.Smooth
	part.BottomSurface=Enum.SurfaceType.Smooth
	part.Parent=border
	return part
end

local function makeFace(parent,a,b,c,color,material)
	local ab,ac,bc=b-a,c-a,c-b
	if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
	elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
	ab,ac,bc=b-a,c-a,c-b
	local right=ac:Cross(ab).Unit
	local up=bc:Cross(right).Unit
	local back=bc.Unit
	local height=math.abs(ab:Dot(up))
	for _,data in ipairs({
		{Vector3.new(.12,height,math.abs(ab:Dot(back))),CFrame.fromMatrix((a+b)/2,right,up,back)},
		{Vector3.new(.12,height,math.abs(ac:Dot(back))),CFrame.fromMatrix((a+c)/2,-right,up,-back)}
	}) do
		local face=Instance.new("WedgePart")
		face.Name="MountainFace"
		face.Size=data[1]
		face.CFrame=data[2]
		face.Anchored=true
		face.Material=material
		face.Color=color
		face.TopSurface=Enum.SurfaceType.Smooth
		face.BottomSurface=Enum.SurfaceType.Smooth
		face.Parent=parent
	end
end

block("NorthFoothill",Vector3.new(448,2,86),Vector3.new(0,0,-185),grassColor,Enum.Material.Grass)
block("SouthFoothill",Vector3.new(448,2,86),Vector3.new(0,0,185),grassColor,Enum.Material.Grass)
block("WestFoothill",Vector3.new(90,2,284),Vector3.new(-179,0,0),grassColor,Enum.Material.Grass)
block("EastFoothill",Vector3.new(90,2,284),Vector3.new(179,0,0),grassColor,Enum.Material.Grass)

local greenShades={Color3.fromRGB(81,114,70),Color3.fromRGB(89,122,76),Color3.fromRGB(75,105,65)}
local rockShades={Color3.fromRGB(143,141,132),Color3.fromRGB(151,147,137),Color3.fromRGB(135,136,128)}
local id=0
for side=1,4 do
	for i=0,6 do
		id+=1
		local axis=-174+i*58
		local localX=(side==1 and -178) or (side==2 and 178) or axis
		local localZ=(side==3 and -186) or (side==4 and 186) or axis
		local mountain=Instance.new("Model")
		mountain.Name=string.format("Mountain%02d",id)
		mountain.Parent=border
		local height=60+(id%4)*7
		local radius=43
		local center=ground.CFrame:PointToWorldSpace(Vector3.new(localX,ground.Size.Y/2,localZ))
		local peak=center+Vector3.new(0,height,0)
		local green=greenShades[(id-1)%#greenShades+1]
		local rock=rockShades[(id-1)%#rockShades+1]
		for edge=0,6 do
			local a=edge*math.pi*2/7
			local b=(edge+1)*math.pi*2/7
			local v1=center+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius)
			local v2=center+Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius)
			local c1=v1:Lerp(peak,.7)
			local c2=v2:Lerp(peak,.7)
			makeFace(mountain,v1,v2,c2,green,Enum.Material.Grass)
			makeFace(mountain,v1,c2,c1,green,Enum.Material.Grass)
			makeFace(mountain,c1,c2,peak,rock,Enum.Material.Slate)
		end
	end
end

block("WestBoundary",Vector3.new(2,220,310),Vector3.new(-144,110,0),grassColor,Enum.Material.SmoothPlastic,true)
block("EastBoundary",Vector3.new(2,220,310),Vector3.new(144,110,0),grassColor,Enum.Material.SmoothPlastic,true)
block("NorthBoundary",Vector3.new(290,220,2),Vector3.new(0,110,-152),grassColor,Enum.Material.SmoothPlastic,true)
block("SouthBoundary",Vector3.new(290,220,2),Vector3.new(0,110,152),grassColor,Enum.Material.SmoothPlastic,true)

history:SetWaypoint("Restored grassy mountain border")
return {mountains=id,foothills=4,boundaries=4}
