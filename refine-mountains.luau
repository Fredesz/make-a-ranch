local root=workspace.FarmLayout
local border=root.MountainBorder
local function triangle(parent,a,b,c,color)
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
  local p=Instance.new('WedgePart');p.Name='MountainFace';p.Size=data[1];p.CFrame=data[2];p.Anchored=true;p.Material=Enum.Material.SmoothPlastic;p.Color=color;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent
 end
end
for _,m in ipairs(border:GetChildren()) do
 if m:IsA('Model') then
  local cf,size=m:GetBoundingBox()
  local green,cap
  for _,p in ipairs(m:GetChildren()) do if p:IsA('BasePart') then if p.Name:find('Cap') then cap=p.Color else green=p.Color end end end
  for _,p in ipairs(m:GetChildren()) do p:Destroy() end
  local id=tonumber(m.Name:match('%d+')) or 1
  local center=Vector3.new(cf.Position.X,root.Meadow.Position.Y+1,cf.Position.Z)
  local height=60+(id%4)*7
  local radius=43
  local peak=center+Vector3.new(0,height,0)
  for i=0,6 do
   local a=i*math.pi*2/7
   local b=(i+1)*math.pi*2/7
   local v1=center+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius)
   local v2=center+Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius)
   local c1=v1:Lerp(peak,.7)
   local c2=v2:Lerp(peak,.7)
   local shade=green:Lerp(Color3.fromRGB(25,90,90),(i%3)*.055)
   triangle(m,v1,v2,c2,shade);triangle(m,v1,c2,c1,shade)
   triangle(m,c1,c2,peak,cap)
  end
 end
end
game:GetService('Selection'):Set({})
game:GetService('ChangeHistoryService'):SetWaypoint('Clean faceted mountains')
return '28 clean seven-sided mountains'

