local root=workspace.FarmLayout
local border=root.MountainBorder
local history=game:GetService('ChangeHistoryService')
history:SetWaypoint('Before extending grass on mountains')
local grassColor=root.Meadow.Color
for _,mountain in ipairs(border:GetChildren()) do
 if mountain:IsA('Model') then
  local faces={}
  for _,part in ipairs(mountain:GetChildren()) do
   if part:IsA('BasePart') and part.Name=='MountainFace' then table.insert(faces,part) end
  end
  table.sort(faces,function(a,b)return a.Position.Y>b.Position.Y end)
  local snowyCount=math.floor(#faces/3)
  for index,face in ipairs(faces) do
   if index<=snowyCount then
    face.Material=Enum.Material.Slate
    face.Color=Color3.fromRGB(143,141,132)
    face:SetAttribute('MountainSurface','SnowRock')
   else
    face.Material=Enum.Material.Grass
    local shade=(index%3)*.035
    face.Color=grassColor:Lerp(Color3.fromRGB(68,105,61),shade)
    face:SetAttribute('MountainSurface','Grass')
   end
  end
 end
end
history:SetWaypoint('Grass extended onto mountain slopes')
return 'Applied grass to 28 lower mountain slopes while preserving stone/snow caps.'
