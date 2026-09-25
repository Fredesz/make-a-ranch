assert(not game:GetService("RunService"):IsRunning(), "Stop Play before moving chests")
local moved=0
for _,plot in ipairs(workspace.FarmLayout.Plots:GetChildren()) do
 local storage=plot:FindFirstChild("HarvestStorage")
 if not storage then continue end
 local pasture=plot.Pasture
 local rear=pasture:GetAttribute("RearDirection") or 1
 for i,name in ipairs({"WheatChest","TomatoChest","LettuceChest","CarrotChest"}) do
  local chest=storage:FindFirstChild(name)
  assert(chest and chest:FindFirstChild("Base"),"Missing chest")
  local before={}
  for _,p in ipairs(chest:GetDescendants()) do if p:IsA("BasePart") then before[p]=p.Size end end
  local current=pasture.CFrame:PointToObjectSpace(chest.Base.Position)
  local target=pasture.CFrame:PointToWorldSpace(Vector3.new(22-(i-1)*6.2,current.Y,rear*9))
  chest:PivotTo(chest:GetPivot()+(target-chest.Base.Position))
  for p,size in pairs(before) do assert(p.Size==size,"Chest resized unexpectedly") end
  moved+=1
 end
end
return "Moved "..moved.." chests; all original sizes and orientations preserved."

