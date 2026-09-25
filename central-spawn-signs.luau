local root = assert(workspace:FindFirstChild('FarmLayout'))
local history = game:GetService('ChangeHistoryService')
history:SetWaypoint('Before grass spawn and plot signs')
local meadow = root.Meadow
for _, item in ipairs(root:GetChildren()) do
    if item.Name == 'ConnectingPath' or item.Name == 'CentralWalkway' or item.Name == 'SpawnPlaza' then item:Destroy() end
end
local spawn = root.PlayerSpawn
spawn.Size = Vector3.new(10, .2, 10)
spawn.CFrame = meadow.CFrame * CFrame.new(0, meadow.Size.Y / 2 - .1, 0)
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Anchored = true
spawn.Neutral = true
spawn.Enabled = true
spawn.Duration = 0
for _, child in ipairs(spawn:GetChildren()) do if child:IsA('Decal') or child:IsA('Texture') then child:Destroy() end end
for _, plot in ipairs(root.Plots:GetChildren()) do
    local previous = plot:FindFirstChild('PlotSign')
    if previous then previous:Destroy() end
    local pasture = plot.Pasture
    local center = meadow.CFrame:PointToObjectSpace(pasture.Position)
    local facing = center.Z < 0 and 1 or -1
    local sign = Instance.new('Model')
    sign.Name = 'PlotSign'
    sign.Parent = plot
    local function piece(name, size, offset)
        local p = Instance.new('Part')
        p.Name = name
        p.Size = size
        p.CFrame = meadow.CFrame * CFrame.new(center.X - 12, meadow.Size.Y / 2 + offset, center.Z + facing * (pasture.Size.Z / 2))
        p.Anchored = true
        p.Material = Enum.Material.Wood
        p.Color = Color3.fromRGB(105, 72, 46)
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Parent = sign
        return p
    end
    piece('Post', Vector3.new(.65, 5.5, .65), 2.75)
    local board = piece('Board', Vector3.new(10, 2.6, .45), 5.3)
    for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
        local gui = Instance.new('SurfaceGui')
        gui.Name = 'Number'
        gui.Face = face
        gui.CanvasSize = Vector2.new(600, 156)
        gui.Parent = board
        local text = Instance.new('TextLabel')
        text.Size = UDim2.fromScale(.92, .8)
        text.Position = UDim2.fromScale(.04, .1)
        text.BackgroundTransparency = 1
        text.Font = Enum.Font.GothamBold
        text.TextColor3 = Color3.fromRGB(255, 240, 205)
        text.TextScaled = true
        text.Text = 'Parcela ' .. plot:GetAttribute('PlotId')
        text.Parent = gui
    end
end
history:SetWaypoint('Central hidden spawn and numbered plots')
return 'Paths removed; spawn centered and hidden; eight double-sided signs created.'
