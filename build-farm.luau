-- Run in Roblox Studio's command bar in Edit mode.
-- Creates the first map blockout; existing scenery is preserved.
assert(not workspace:FindFirstChild('FarmLayout'), 'FarmLayout already exists')
local ChangeHistoryService = game:GetService('ChangeHistoryService')
ChangeHistoryService:SetWaypoint('Before farm layout')
local root = Instance.new('Model')
root.Name = 'FarmLayout'
local grass = Color3.fromRGB(111, 156, 73)
local wood = Color3.fromRGB(119, 79, 47)
local cream = Color3.fromRGB(242, 220, 170)
local function part(parent, name, size, position, color, material)
    local p = Instance.new('Part')
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end
local function label(p, text)
    local gui = Instance.new('SurfaceGui')
    gui.Face = Enum.NormalId.Front
    gui.CanvasSize = Vector2.new(640, 160)
    gui.Parent = p
    local t = Instance.new('TextLabel')
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundTransparency = 1
    t.Text = text
    t.TextColor3 = cream
    t.Font = Enum.Font.GothamBold
    t.TextScaled = true
    t.Parent = gui
end
part(root, 'Meadow', Vector3.new(268, 2, 188), Vector3.new(0, 0, 0), grass, Enum.Material.Grass)
part(root, 'CentralWalkway', Vector3.new(250, .2, 16), Vector3.new(0, 1.12, 0), cream, Enum.Material.Sand)
for _, x in ipairs({-125, -62, 0, 62, 125}) do
    part(root, 'ConnectingPath', Vector3.new(8, .2, 150), Vector3.new(x, 1.12, 12), cream, Enum.Material.Sand)
end
part(root, 'SpawnPlaza', Vector3.new(250, .3, 24), Vector3.new(0, 1.2, 80), cream, Enum.Material.Sandstone)
local plots = Instance.new('Folder')
plots.Name = 'Plots'
plots.Parent = root
for row = 1, 2 do
    for column = 1, 4 do
        local id = (row - 1) * 4 + column
        local x = (column - 2.5) * 62
        local z = row == 1 and -38 or 38
        local entrance = row == 1 and 1 or -1
        local plot = Instance.new('Model')
        plot.Name = string.format('Plot%02d', id)
        plot:SetAttribute('PlotId', id)
        plot:SetAttribute('OwnerUserId', 0)
        plot.Parent = plots
        part(plot, 'Pasture', Vector3.new(52, .3, 48), Vector3.new(x, 1.25, z), Color3.fromRGB(136, 178, 86), Enum.Material.Grass)
        local function fence(cx, cz, length, side)
            for _, h in ipairs({2.6, 4.4}) do
                part(plot, 'FenceRail', side and Vector3.new(.55, .55, length) or Vector3.new(length, .55, .55), Vector3.new(cx, h, cz), cream, Enum.Material.Wood)
            end
            local count = math.ceil(length / 8)
            for i = 0, count do
                local offset = -length / 2 + length * i / count
                part(plot, 'FencePost', Vector3.new(.9, 4, .9), Vector3.new(cx + (side and 0 or offset), 3.3, cz + (side and offset or 0)), wood, Enum.Material.Wood)
            end
        end
        fence(x - 26, z, 48, true)
        fence(x + 26, z, 48, true)
        fence(x, z - entrance * 24, 52, false)
        fence(x - 16, z + entrance * 24, 20, false)
        fence(x + 16, z + entrance * 24, 20, false)
        local shelterZ = z - entrance * 14
        local shelter = Instance.new('Model')
        shelter.Name = 'AnimalShelter'
        shelter.Parent = plot
        part(shelter, 'Floor', Vector3.new(28, .4, 16), Vector3.new(x, 1.6, shelterZ), wood, Enum.Material.WoodPlanks)
        for _, dx in ipairs({-13, 13}) do
            for _, dz in ipairs({-7, 7}) do
                part(shelter, 'Support', Vector3.new(1, 10, 1), Vector3.new(x + dx, 6.6, shelterZ + dz), wood, Enum.Material.Wood)
            end
        end
        part(shelter, 'BackWall', Vector3.new(27, 6, .6), Vector3.new(x, 4.6, shelterZ - entrance * 7), wood, Enum.Material.WoodPlanks)
        part(shelter, 'Roof', Vector3.new(31, 1, 19), Vector3.new(x, 12, shelterZ), Color3.fromRGB(151, 66, 49), Enum.Material.WoodPlanks)
        part(shelter, 'Hay', Vector3.new(6, 2.2, 4), Vector3.new(x - 8, 2.9, shelterZ), Color3.fromRGB(222, 181, 74), Enum.Material.Grass)
        part(plot, 'WaterTrough', Vector3.new(8, 1.4, 3.5), Vector3.new(x + 17, 2, z), wood, Enum.Material.Wood)
        part(plot, 'Water', Vector3.new(7, .12, 2.5), Vector3.new(x + 17, 2.76, z), Color3.fromRGB(93, 181, 213), Enum.Material.Glass)
        local animals = Instance.new('Folder')
        animals.Name = 'Animals'
        animals.Parent = plot
        local sign = part(plot, 'PlotSign', Vector3.new(11, 2.5, .5), Vector3.new(x - 16, 6, z + entrance * 24), wood, Enum.Material.Wood)
        if entrance == 1 then sign.Orientation = Vector3.new(0, 180, 0) end
        label(sign, 'PARCELA ' .. id)
    end
end
local spawn = Instance.new('SpawnLocation')
spawn.Name = 'PlayerSpawn'
spawn.Size = Vector3.new(14, .5, 14)
spawn.CFrame = CFrame.new(0, 1.65, 80)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Material = Enum.Material.SmoothPlastic
spawn.Color = Color3.fromRGB(111, 177, 185)
spawn.Parent = root
root.Parent = workspace
local oldSpawn = workspace:FindFirstChild('SpawnLocation')
if oldSpawn and oldSpawn:IsA('SpawnLocation') then
    oldSpawn.Enabled = false
    oldSpawn.Transparency = 1
    oldSpawn.CanCollide = false
end
workspace.CurrentCamera.CFrame = CFrame.lookAt(Vector3.new(180, 190, 230), Vector3.new(0, 0, 5))
ChangeHistoryService:SetWaypoint('Farm layout created')
return 'Created 8 plots, 8 shelters and front player spawn.'
