assert(not game:GetService("RunService"):IsRunning(), "Stop Play first")
for _,plot in ipairs(workspace.FarmLayout.Plots:GetChildren()) do
 local g=plot:FindFirstChild("Greenhouse")
 if not g then continue end
 local base=g.Foundation.CFrame*CFrame.new(0,-0.18,0)
 local rear=plot.Pasture:GetAttribute("RearDirection") or 1
 for _,p in ipairs(g:GetChildren()) do
  if p.Name=="RoofRidgeFrame" or p.Name=="FrontSupport" or p.Name=="RefinedFrames" then p:Destroy() end
 end
 local frames=Instance.new("Model")
 frames.Name="RefinedFrames"
 frames.Parent=g
 local function beam(a,b,width)
  local start=base:PointToWorldSpace(a)
  local finish=base:PointToWorldSpace(b)
  local p=Instance.new("Part")
  p.Name="Frame"
  p.Size=Vector3.new(width,width,(finish-start).Magnitude)
  p.CFrame=CFrame.lookAt((start+finish)/2,finish)
  p.Color=Color3.fromHex("285548")
  p.Material=Enum.Material.Metal
  p.Anchored=true
  p.Parent=frames
 end
 for _,x in ipairs({-12,-6,0,6,12}) do
  for _,side in ipairs({-1,1}) do
   beam(Vector3.new(x,7,side*10),Vector3.new(x,12,0),0.24)
  end
 end
 for _,x in ipairs({-12,12}) do
  for _,z in ipairs({-4.75,0,4.75}) do
   beam(Vector3.new(x,0.35,z),Vector3.new(x,7,z),0.22)
  end
  for _,y in ipairs({0.5,3.3}) do
   beam(Vector3.new(x,y,-9.5),Vector3.new(x,y,9.5),0.22)
  end
 end
 for _,x in ipairs({-8,-4,0,4,8}) do
  beam(Vector3.new(x,0.35,rear*9.5),Vector3.new(x,7,rear*9.5),0.22)
 end
 beam(Vector3.new(-12,3.3,rear*9.5),Vector3.new(12,3.3,rear*9.5),0.22)
 for _,side in ipairs({-1,1}) do
  beam(Vector3.new(side*7.6,0.35,-rear*9.5),Vector3.new(side*7.6,7,-rear*9.5),0.22)
  beam(Vector3.new(side*3.2,3.3,-rear*9.5),Vector3.new(side*12,3.3,-rear*9.5),0.22)
 end
 for _,bed in ipairs(g.Beds:GetChildren()) do
  local gui=bed:FindFirstChild("CropLabel")
  if gui then
   gui.AlwaysOnTop=false
   gui.MaxDistance=35
   for _,label in ipairs(gui:GetDescendants()) do
    if label:IsA("TextLabel") then
     label.BackgroundTransparency=1
     label.TextStrokeColor3=Color3.fromHex("233447")
     label.TextStrokeTransparency=0.35
    end
   end
  end
 end
end
return "Roof rafters, connected wall frames and transparent crop labels applied."

