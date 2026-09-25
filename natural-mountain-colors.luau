local root=workspace.FarmLayout
local border=root.MountainBorder
local history=game:GetService('ChangeHistoryService')
history:SetWaypoint('Before natural mountain colors')
for _,item in ipairs(border:GetChildren()) do
 if item:IsA('Model') then
  local id=tonumber(item.Name:match('%d+')) or 1
  local greens={Color3.fromRGB(101,126,79),Color3.fromRGB(108,130,84),Color3.fromRGB(95,121,77)}
  local stone={Color3.fromRGB(143,141,132),Color3.fromRGB(151,147,137),Color3.fromRGB(135,136,128)}
  for _,p in ipairs(item:GetDescendants()) do if p:IsA('BasePart') then
   local c=p.Color
   local isRock=p:GetAttribute('MountainRock')
   if isRock==nil then isRock=not(c.G>c.R and c.G>c.B);p:SetAttribute('MountainRock',isRock) end
   if isRock then p.Color=stone[(id-1)%3+1]
   else p.Color=greens[(id-1)%3+1]:Lerp(Color3.fromRGB(74,96,63),math.clamp((.66-c.G)*.65,0,.12)) end
  end end
 elseif item:IsA('BasePart') and item.Name:find('Foothill') then
  item.Color=root.Meadow.Color
 end
end
history:SetWaypoint('Natural greens and stone mountains')
return 'Mountain shapes preserved; natural green slopes, stone gray peaks, matching ground.'

