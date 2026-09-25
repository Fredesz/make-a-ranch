local root=workspace.FarmLayout
assert(not root:FindFirstChild('MountainBorder'),'Border already exists')
local source=workspace:FindFirstChild('LowPolyMountains')
assert(source,'Generated mountain missing')
local history=game:GetService('ChangeHistoryService')
history:SetWaypoint('Before colorful mountain border')
local template=Instance.new('Model')
template.Name='MountainTemplate'
for _,v in ipairs(source:GetDescendants()) do
 if v:IsA('BasePart') and string.find(v.Name,'PeakCenter',1,true) then
  local p=v:Clone();p.Anchored=true;p.Parent=template
 end
end
assert(#template:GetChildren()>0,'No mountain geometry')
local border=Instance.new('Model');border.Name='MountainBorder';border.Parent=root
local ground=root.Meadow
local groundTop=ground.Position.Y+ground.Size.Y/2
local palette={
 {Color3.fromRGB(48,177,130),Color3.fromRGB(177,105,237)},
 {Color3.fromRGB(46,169,153),Color3.fromRGB(255,158,99)},
 {Color3.fromRGB(85,183,99),Color3.fromRGB(255,209,100)},
 {Color3.fromRGB(59,181,148),Color3.fromRGB(225,128,205)}
}
local function block(name,size,pos,color,transparent)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=ground.CFrame*CFrame.new(pos);p.Anchored=true;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 if transparent then p.Transparency=1 end
 p.Parent=border;return p
end
local green=Color3.fromRGB(83,174,101)
block('NorthFoothill',Vector3.new(448,2,86),Vector3.new(0,0,-185),green)
block('SouthFoothill',Vector3.new(448,2,86),Vector3.new(0,0,185),green)
block('WestFoothill',Vector3.new(90,2,284),Vector3.new(-179,0,0),green)
block('EastFoothill',Vector3.new(90,2,284),Vector3.new(179,0,0),green)
local n=0
for side=1,4 do
 for i=0,6 do
  n+=1
  local a=-174+i*58
  local x=(side==1 and -178) or (side==2 and 178) or a
  local z=(side==3 and -186) or (side==4 and 186) or a
  local m=template:Clone();m.Name=string.format('Mountain%02d',n);m.Parent=border
  local cf,size=m:GetBoundingBox()
  m:ScaleTo((58+(n%3)*5)/size.Y)
  local cf2,s2=m:GetBoundingBox()
  local target=Vector3.new(ground.Position.X+x,groundTop+s2.Y/2-1,ground.Position.Z+z)
  m:PivotTo(CFrame.new(target-cf2.Position)*m:GetPivot())
  local colors=palette[(n-1)%#palette+1]
  for _,p in ipairs(m:GetDescendants()) do if p:IsA('BasePart') then
   if string.find(p.Name,'Cap',1,true) then p.Color=colors[2] else
    local idx=tonumber(string.match(p.Name,'(%d+)$')) or 1
    p.Color=idx%2==0 and colors[1] or colors[1]:Lerp(Color3.fromRGB(20,100,94),.14)
   end
   p.Material=Enum.Material.SmoothPlastic
  end end
 end
end
-- Invisible continuous collision boundary sits inside the mountain bases.
block('WestBoundary',Vector3.new(2,220,310),Vector3.new(-144,110,0),green,true)
block('EastBoundary',Vector3.new(2,220,310),Vector3.new(144,110,0),green,true)
block('NorthBoundary',Vector3.new(290,220,2),Vector3.new(0,110,-152),green,true)
block('SouthBoundary',Vector3.new(290,220,2),Vector3.new(0,110,152),green,true)
template:Destroy()
source.Parent=game:GetService('ServerStorage')
source.Name='MountainDesignTemplate'
history:SetWaypoint('Colorful enclosed mountain map')
return {mountains=n,parts=#border:GetDescendants()}

