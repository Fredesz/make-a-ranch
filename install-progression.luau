-- Run after the other installers, in Edit mode.
local source=[==[
local p=game.Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuyProgressUpgrade")
local travel=game.ReplicatedStorage.Remotes:WaitForChild("ExpeditionHudAction")
local gui=Instance.new("ScreenGui",p:WaitForChild("PlayerGui"))
gui.Name="ProgressionGui"
gui.DisplayOrder=12
gui.ResetOnSpawn=false
local function button(parent,name,text,position,size)
 local b=Instance.new("TextButton")
 b.Name=name b.Text=text b.Position=position b.Size=size
 b.BackgroundColor3=Color3.fromRGB(52,104,124)
 b.TextColor3=Color3.new(1,1,1)
 b.Font=Enum.Font.GothamBold b.TextSize=14 b.BorderSizePixel=0
 b.Parent=parent
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
 return b
end
local open=button(gui,"Open","Mejoras",UDim2.fromOffset(18,262),UDim2.fromOffset(210,42))
local panel=Instance.new("Frame",gui)
panel.Name="Panel" panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.Position=UDim2.fromScale(0.5,0.5) panel.Size=UDim2.new(0.9,0,0.82,0)
panel.BackgroundColor3=Color3.fromRGB(30,43,39) panel.BorderSizePixel=0 panel.Visible=false
local limits=Instance.new("UISizeConstraint",panel)
limits.MaxSize=Vector2.new(530,450)
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,8)
local title=Instance.new("TextLabel",panel)
title.Text="Mejoras de la granja" title.Font=Enum.Font.GothamBold title.TextSize=20
title.TextColor3=Color3.new(1,1,1) title.BackgroundTransparency=1
title.Position=UDim2.fromOffset(12,10) title.Size=UDim2.new(1,-65,0,28)
local close=button(panel,"Close","X",UDim2.new(1,-44,0,8),UDim2.fromOffset(34,34))
local scroll=Instance.new("ScrollingFrame",panel)
scroll.Name="Upgrades" scroll.Position=UDim2.fromOffset(12,50) scroll.Size=UDim2.new(1,-24,1,-100)
scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0 scroll.ScrollBarThickness=4
scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.CanvasSize=UDim2.new()
local layout=Instance.new("UIListLayout",scroll) layout.Padding=UDim.new(0,10)
local specs={
 {key="Slots",attr="InventoryLevel",name="Espacios",price=200,max=3},
 {key="Bait",attr="BaitLevel",name="Calidad del cebo",price=300,max=2},
 {key="Luck",attr="LuckLevel",name="Suerte",price=250,max=5},
 {key="Zone",attr="ZoneLevel",name="Prado azul",price=600,max=1},
}
local rows={}
for _,spec in ipairs(specs) do
 local b=button(scroll,spec.key,"",UDim2.new(),UDim2.new(1,-6,0,58))
 b.TextWrapped=true
 rows[spec.key]=b
 b.Activated:Connect(function() remote:FireServer(spec.key) end)
end
local visit=button(scroll,"VisitBlue","Viajar al Prado azul",UDim2.new(),UDim2.new(1,-6,0,42))
visit.Activated:Connect(function()
 travel:FireServer("Departure2")
 panel.Visible=false
end)
local message=Instance.new("TextLabel",panel)
message.Name="Message" message.Position=UDim2.new(0,12,1,-44) message.Size=UDim2.new(1,-24,0,36)
message.BackgroundTransparency=1 message.TextColor3=Color3.fromRGB(239,215,139)
message.Font=Enum.Font.Gotham message.TextSize=13 message.TextWrapped=true
local function refresh()
 for _,spec in ipairs(specs) do
  local level=p:GetAttribute(spec.attr) or 0
  local value=spec.key=="Slots" and tostring(10+level*10).." espacios" or (spec.key=="Bait" and "Bono de cebo +"..tostring(level*25).."%" or (spec.key=="Luck" and "Captura +"..tostring(level*2).." puntos" or "Captura +10 puntos"))
  rows[spec.key].Text=spec.name.." | "..value.."\n"..(level>=spec.max and "Nivel maximo" or "Mejorar: "..tostring(spec.price*(level+1)).." monedas")
  rows[spec.key].Active=level<spec.max
  rows[spec.key].AutoButtonColor=level<spec.max
 end
 visit.Visible=(p:GetAttribute("ZoneLevel") or 0)>0
 visit.Text=p:GetAttribute("InExpedition") and "Vuelve a la granja para cambiar de zona" or "Viajar al Prado azul"
 visit.Active=not p:GetAttribute("InExpedition")
 message.Text=p:GetAttribute("ProgressMessage") or ""
end
open.Activated:Connect(function() panel.Visible=not panel.Visible refresh() end)
close.Activated:Connect(function() panel.Visible=false end)
for _,spec in ipairs(specs) do p:GetAttributeChangedSignal(spec.attr):Connect(refresh) end
p:GetAttributeChangedSignal("ProgressMessage"):Connect(refresh)
p:GetAttributeChangedSignal("InExpedition"):Connect(refresh)
refresh()
]==]
local s=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ProgressionClient") or Instance.new("LocalScript")
s.Name="ProgressionClient" s.Source=source s.Parent=game.StarterPlayer.StarterPlayerScripts
return "Installed progression UI."

