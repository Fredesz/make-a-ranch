local root=workspace.FarmLayout
local history=game:GetService('ChangeHistoryService')
history:SetWaypoint('Before straightening signs')
for _,plot in ipairs(root.Plots:GetChildren()) do
 local sign=plot.PlotSign
 local board=sign.Board
 local post=sign.Post
 local localCenter=root.Meadow.CFrame:PointToObjectSpace(plot.Pasture.Position)
 local towardCenter=localCenter.Z<0 and 1 or -1
 local groundY=root.Meadow.Position.Y+root.Meadow.Size.Y/2
 local x=plot.Pasture.Position.X-12
 local z=plot.Pasture.Position.Z+towardCenter*(plot.Pasture.Size.Z/2+2)
 board.CFrame=CFrame.new(x,groundY+5.3,z)
 board.Size=Vector3.new(10,2.6,.45)
 post.Size=Vector3.new(.65,4.3,.65)
 post.CFrame=CFrame.new(x,groundY+2.15,z)
end
history:SetWaypoint('Straight centered signs clear of fences')
return '8 signs aligned; posts centered; separated from fence posts.'
