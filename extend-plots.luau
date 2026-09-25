-- Apply after build-farm.luau in Studio Edit mode.
local root = assert(workspace:FindFirstChild('FarmLayout'), 'FarmLayout missing')
assert(not root:GetAttribute('LongPlots'), 'Long plots already applied')
local history = game:GetService('ChangeHistoryService')
history:SetWaypoint('Before extending plots')
local grass = root.Meadow.Color
for _, plot in ipairs(root.Plots:GetChildren()) do
    local pasture = plot.Pasture
    local oldCenter = pasture.Position.Z
    local newCenter = oldCenter < 0 and -62 or 62
    for _, item in ipairs(plot:GetChildren()) do
        if item.Name == 'AnimalShelter' or item.Name == 'WaterTrough' or item.Name == 'Water' or item.Name == 'PlotSign' then
            item:Destroy()
        elseif item:IsA('BasePart') and item ~= pasture then
            local position = item.Position
            item.Position = Vector3.new(position.X, position.Y, newCenter + (position.Z - oldCenter) * 2)
            if item.Name == 'FenceRail' and item.Size.Z > item.Size.X then
                item.Size = Vector3.new(item.Size.X, item.Size.Y, item.Size.Z * 2)
            end
        end
    end
    -- Add intermediate side posts to preserve the original fence spacing.
    for _, dx in ipairs({-26, 26}) do
        for offset = -40, 40, 16 do
            local post = Instance.new('Part')
            post.Name = 'FencePost'
            post.Anchored = true
            post.Size = Vector3.new(.9, 4, .9)
            post.Position = Vector3.new(pasture.Position.X + dx, 3.3, newCenter + offset)
            post.Material = Enum.Material.Wood
            post.Color = Color3.fromRGB(119, 79, 47)
            post.TopSurface = Enum.SurfaceType.Smooth
            post.BottomSurface = Enum.SurfaceType.Smooth
            post.Parent = plot
        end
    end
    -- Use the meadow as the single visible grass surface, avoiding seams.
    pasture.Size = Vector3.new(52, .3, 96)
    pasture.Position = Vector3.new(pasture.Position.X, .8, newCenter)
    pasture.Color = grass
    pasture.Material = Enum.Material.Grass
    pasture.Transparency = 1
    pasture.CanCollide = false
    plot:SetAttribute('BuildWidth', 52)
    plot:SetAttribute('BuildDepth', 96)
end
root.Meadow.Size = Vector3.new(268, 2, 284)
for _, item in ipairs(root:GetChildren()) do
    if item.Name == 'ConnectingPath' then
        item.Size = Vector3.new(8, .2, 246)
    end
end
root.SpawnPlaza.Position = Vector3.new(0, 1.2, 128)
root.PlayerSpawn.Position = Vector3.new(0, 1.65, 128)
root:SetAttribute('LongPlots', true)
workspace.CurrentCamera.CFrame = CFrame.lookAt(Vector3.new(190, 260, 310), Vector3.new(0, 0, 5))
history:SetWaypoint('Long empty tycoon plots')
return 'Eight 52 x 96 plots; uniform grass; fences only; spawn and paths extended.'
