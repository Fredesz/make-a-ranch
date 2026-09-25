local root=workspace.FarmLayout
local border=root.MountainBorder
local history=game:GetService('ChangeHistoryService')
history:SetWaypoint('Before texturing mountain foothills')
local grassColor=root.Meadow.Color
local updated=0
for _,part in ipairs(border:GetChildren()) do
 if part:IsA('BasePart') and part.Name:find('Foothill') then
  part.Material=Enum.Material.Grass
  part.Color=grassColor
  part.TopSurface=Enum.SurfaceType.Smooth
  part.BottomSurface=Enum.SurfaceType.Smooth
  updated+=1
 end
end
history:SetWaypoint('Grass-textured mountain foothills')
return {updated=updated,material='Grass',color=tostring(grassColor)}
