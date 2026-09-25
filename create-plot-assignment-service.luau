local ServerScriptService = game:GetService("ServerScriptService")
local source = [==[
local Players = game:GetService("Players")
local plots = workspace:WaitForChild("FarmLayout"):WaitForChild("Plots")
local assigned = {}
local function owner(plot, player)
 plot:SetAttribute("OwnerUserId",player and player.UserId or 0)
 plot:SetAttribute("OwnerName",player and player.Name or "")
 local animals=plot:FindFirstChild("Animals")
 if animals then animals:SetAttribute("OwnerUserId",player and player.UserId or 0) end
 local sign=plot:FindFirstChild("PlotSign")
 if sign then
  for _,label in ipairs(sign:GetDescendants()) do
   if label:IsA("TextLabel") then
    label.Text="Parcela "..tostring(plot:GetAttribute("PlotId"))..(player and "\n"..player.Name or "")
   end
  end
 end
end
local function join(player)
 while player.Parent==Players and not player:GetAttribute("EconomyDataLoaded") do task.wait(0.1) end
 if player.Parent~=Players or assigned[player] then return end
 local list=plots:GetChildren()
 table.sort(list,function(a,b) return a:GetAttribute("PlotId")<b:GetAttribute("PlotId") end)
 local selected
 for _,plot in ipairs(list) do
  if plot:GetAttribute("OwnerUserId")==0 then
   selected=selected or plot
   if plot:GetAttribute("PlotId")==player:GetAttribute("PreferredPlotId") then selected=plot break end
  end
 end
 if not selected then player:SetAttribute("AssignedPlotId",0) return end
 assigned[player]=selected
 owner(selected,player)
 player:SetAttribute("AssignedPlotId",selected:GetAttribute("PlotId"))
 if (player:GetAttribute("PreferredPlotId") or 0)<=0 then
  player:SetAttribute("PreferredPlotId",selected:GetAttribute("PlotId"))
 end
end
for _,plot in ipairs(plots:GetChildren()) do owner(plot,nil) end
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(function(player)
 if assigned[player] then owner(assigned[player],nil) assigned[player]=nil end
end)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(join,player) end
]==]
local script = ServerScriptService:FindFirstChild("PlotAssignmentService") or Instance.new("Script")
script.Name="PlotAssignmentService"
script.Source=source
script.Parent=ServerScriptService
return "Installed preferred plot assignment."
