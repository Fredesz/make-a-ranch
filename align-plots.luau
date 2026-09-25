local root=workspace.FarmLayout
local function fence(plot,x,z,length,side)
 local function p(name,size,pos,color)
  local a=Instance.new('Part'); a.Name=name; a.Size=size; a.Position=pos; a.Anchored=true; a.Material=Enum.Material.Wood; a.Color=color; a.TopSurface=Enum.SurfaceType.Smooth; a.BottomSurface=Enum.SurfaceType.Smooth; a.Parent=plot
 end
 for _,h in ipairs({2.6,4.4}) do p('FenceRail',side and Vector3.new(.55,.55,length) or Vector3.new(length,.55,.55),Vector3.new(x,h,z),Color3.fromRGB(242,220,170)) end
 local n=math.ceil(length/8)
 for i=0,n do local d=-length/2+length*i/n; p('FencePost',Vector3.new(.9,4,.9),Vector3.new(x+(side and 0 or d),3.3,z+(side and d or 0)),Color3.fromRGB(119,79,47)) end
end
for _,plot in ipairs(root.Plots:GetChildren()) do
 local id=plot:GetAttribute('PlotId'); local col=(id-1)%4+1; local x=(col-2.5)*62; local z=id<=4 and -62 or 62; local e=id<=4 and 1 or -1
 for _,v in ipairs(plot:GetChildren()) do if v.Name=='FenceRail' or v.Name=='FencePost' then v:Destroy() end end
 plot.Pasture.CFrame=CFrame.new(x,.8,z)
 fence(plot,x-26,z,96,true); fence(plot,x+26,z,96,true); fence(plot,x,z-e*48,52,false); fence(plot,x-16,z+e*48,20,false); fence(plot,x+16,z+e*48,20,false)
end
root.Meadow.CFrame=CFrame.new(0,0,0)
root.CentralWalkway.CFrame=CFrame.new(0,1.12,0)
local xs={-125,-62,0,62,125}; local i=0
for _,v in ipairs(root:GetChildren()) do if v.Name=='ConnectingPath' then i+=1; v.CFrame=CFrame.new(xs[i],1.12,12) end end
root.SpawnPlaza.CFrame=CFrame.new(0,1.2,128)
root.PlayerSpawn.CFrame=CFrame.new(0,1.65,128)
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(150,240,265),Vector3.new(0,0,10))
game:GetService('ChangeHistoryService'):SetWaypoint('Aligned long plots')
return 'Layout aligned'
