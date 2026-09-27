--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local BuildingConfig = require(ReplicatedStorage.Shared.Config.BuildingConfig)
local selectedBuilding = "Barn"
local remote = ReplicatedStorage:WaitForChild("BuildRequest") :: RemoteEvent

local preview = Instance.new("Part")
preview.Name = "BarnPreview"
preview.Anchored = true
preview.CanCollide = false
preview.CanTouch = false
preview.CanQuery = false
preview.Transparency = 0.55
preview.Size = Vector3.new(BuildingConfig.Barn.Footprint.X,
    BuildingConfig.Barn.Height, BuildingConfig.Barn.Footprint.Y)
preview.Parent = workspace

local active = false
local valid = false
local rotation = 0
local gridX = 0
local gridZ = 0

local function overlaps(x: number, z: number, width: number, depth: number,
    other: BasePart): boolean
    local otherWidth = other:GetAttribute("FootprintX") or other.Size.X
    local otherDepth = other:GetAttribute("FootprintZ") or other.Size.Z
    return math.abs(x - other.Position.X) * 2 < width + otherWidth
        and math.abs(z - other.Position.Z) * 2 < depth + otherDepth
end

RunService.RenderStepped:Connect(function()
    preview.Transparency = if active then 0.55 else 1
    if not active then return end
    local definition = BuildingConfig[selectedBuilding]
    local folder = workspace:FindFirstChild("RanchPlots")
    local plot = if folder then folder:FindFirstChild("Plot_" .. player.UserId) else nil
    local ground = if plot then plot:FindFirstChild("Ground") else nil
    if not ground or not ground:IsA("BasePart") then return end
    gridX = math.floor((mouse.Hit.Position.X - ground.Position.X) / PlotConfig.BuildGridSize + 0.5)
    gridZ = math.floor((mouse.Hit.Position.Z - ground.Position.Z) / PlotConfig.BuildGridSize + 0.5)
    local x = ground.Position.X + gridX * PlotConfig.BuildGridSize
    local z = ground.Position.Z + gridZ * PlotConfig.BuildGridSize
    local width = if rotation == 90 or rotation == 270 then definition.Footprint.Y else definition.Footprint.X
    local depth = if rotation == 90 or rotation == 270 then definition.Footprint.X else definition.Footprint.Y
    valid = math.abs(x - ground.Position.X) + width / 2 <= ground.Size.X / 2
        and math.abs(z - ground.Position.Z) + depth / 2 <= ground.Size.Z / 2
    if valid then
        for _, child in plot:GetChildren() do
            if child:IsA("BasePart") and child ~= ground
                and overlaps(x, z, width, depth, child) then
                valid = false
                break
            end
        end
    end
    preview.CFrame = CFrame.new(x,
        ground.Position.Y + ground.Size.Y / 2 + definition.Height / 2,
        z) * CFrame.Angles(0, math.rad(rotation), 0)
    preview.Color = if valid then Color3.fromRGB(80, 220, 100) else Color3.fromRGB(230, 75, 75)
    preview.Size = Vector3.new(definition.Footprint.X, definition.Height, definition.Footprint.Y)
end)

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.B then
        selectedBuilding = "Barn"
        active = not active
    elseif input.KeyCode == Enum.KeyCode.F then
        selectedBuilding = "SmallField"
        active = not active
    elseif input.KeyCode == Enum.KeyCode.R and active then
        rotation = (rotation + 90) % 360
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and active and valid then
        remote:FireServer(selectedBuilding, gridX, gridZ, rotation)
    end
end)

remote.OnClientEvent:Connect(function(ok: boolean, reason: string?)
    if ok then
        active = false
    else
        warn("Build rejected:", reason)
    end
end)
