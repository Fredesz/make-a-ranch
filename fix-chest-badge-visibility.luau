local module = game.ReplicatedStorage:WaitForChild("HarvestChestVisuals")
local source = module.Source
local old = "for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do"
local replacement = "for _, face in ipairs({Enum.NormalId.Front}) do"
local start, finish = source:find(old, 1, true)
if start then source = source:sub(1,start-1)..replacement..source:sub(finish+1) end
source = source:gsub("surface%.AlwaysOnTop = true", "surface.AlwaysOnTop = false\n\t\tsurface.MaxDistance = 60")
module.Source = source
local count = 0
for _, plot in ipairs(workspace.FarmLayout.Plots:GetChildren()) do
 local storage = plot:FindFirstChild("HarvestStorage")
 if storage then
  for _, chest in ipairs(storage:GetChildren()) do
   local badge = chest:FindFirstChild("CropBadge")
   if badge then
    for _, surface in ipairs(badge:GetChildren()) do
     if surface:IsA("SurfaceGui") and surface.Name == "CropPicture" then
      if surface.Face ~= Enum.NormalId.Front then
       surface:Destroy()
      else
       surface.AlwaysOnTop = false
       surface.MaxDistance = 60
       count += 1
      end
     end
    end
   end
  end
 end
end
return "Updated front-only badges: "..count
