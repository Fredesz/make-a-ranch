--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildingConfig = require(ReplicatedStorage.Shared.Config.BuildingConfig)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local PlayerDataService = require(script.Parent.Parent.PlayerDataService)
local PlotService = require(script.Parent.PlotService)
local CropService = require(script.Parent.CropService)
local ChickenService = require(script.Parent.ChickenService)

local initialized = false
local BuildService = {}

local function wholeGridCoordinate(value: number): boolean
    return typeof(value) == "number" and value == value and value % 1 == 0
        and math.abs(value) <= 1000
end

local function footprint(size: Vector2, rotation: number): (number, number)
    if rotation == 90 or rotation == 270 then
        return size.Y, size.X
    end
    return size.X, size.Y
end

local function intersects(x: number, z: number, width: number, depth: number,
    otherX: number, otherZ: number, otherWidth: number, otherDepth: number): boolean
    return math.abs(x - otherX) * 2 < width + otherWidth
        and math.abs(z - otherZ) * 2 < depth + otherDepth
end

function BuildService.Place(
    player: Player,
    buildingId: string,
    gridX: number,
    gridZ: number,
    rotation: number
): (boolean, string?)
    local slot = PlotService.GetSlot(player)
    if not slot or not PlotService.OwnsSlot(player, slot) then
        return false, "InvalidPlot"
    end
    local definition = if typeof(buildingId) == "string" then BuildingConfig[buildingId] else nil
    if not definition then return false, "UnknownBuilding" end
    if buildingId == "ChickenCoop" and ChickenService.GetCoop(player) then
        return false, "AlreadyOwned"
    end
    if not wholeGridCoordinate(gridX) or not wholeGridCoordinate(gridZ)
        or typeof(rotation) ~= "number" or rotation ~= rotation
        or rotation % 90 ~= 0 or rotation < 0 or rotation >= 360 then
        return false, "InvalidGridOrRotation"
    end
    local model = slot.Parent
    local ground = model and model:FindFirstChild("Ground")
    if not ground or not ground:IsA("BasePart") then return false, "InvalidPlot" end

    local centerX = ground.Position.X + gridX * PlotConfig.BuildGridSize
    local centerZ = ground.Position.Z + gridZ * PlotConfig.BuildGridSize
    local width, depth = footprint(definition.Footprint, rotation)
    if math.abs(centerX - ground.Position.X) + width / 2 > ground.Size.X / 2
        or math.abs(centerZ - ground.Position.Z) + depth / 2 > ground.Size.Z / 2 then
        return false, "OutsidePlot"
    end
    for _, child in model:GetChildren() do
        if child:IsA("BasePart") and child ~= ground then
            local otherWidth = child:GetAttribute("FootprintX") or child.Size.X
            local otherDepth = child:GetAttribute("FootprintZ") or child.Size.Z
            if intersects(centerX, centerZ, width, depth,
                child.Position.X, child.Position.Z, otherWidth, otherDepth) then
                return false, "Overlapping"
            end
        end
    end
    local bought, reason = PlayerDataService.PurchaseBuilding(player, {
        BuildingId = buildingId,
        GridX = gridX,
        GridZ = gridZ,
        Rotation = rotation,
    }, definition.Price)
    if not bought then return false, reason end

    local part = Instance.new("Part")
    part.Name = buildingId
    part.Anchored = true
    part.Size = Vector3.new(definition.Footprint.X, definition.Height, definition.Footprint.Y)
    part.CFrame = CFrame.new(centerX,
        ground.Position.Y + ground.Size.Y / 2 + definition.Height / 2,
        centerZ) * CFrame.Angles(0, math.rad(rotation), 0)
    part.Color = definition.Color
    part:SetAttribute("OwnerUserId", player.UserId)
    part:SetAttribute("FootprintX", width)
    part:SetAttribute("FootprintZ", depth)
    part.Parent = model
    if buildingId == "SmallField" then
        local fieldSlot = Instance.new("Part")
        fieldSlot.Name = "CropSlot"
        fieldSlot.Anchored = true
        fieldSlot.Size = Vector3.new(4, 0.3, 4)
        fieldSlot.Position = part.Position + Vector3.new(0,
            (part.Size.Y + fieldSlot.Size.Y) / 2, 0)
        fieldSlot.Color = PlotConfig.SoilColor
        fieldSlot:SetAttribute("FieldSlot", true)
        fieldSlot.Parent = model
        assert(CropService.RegisterFieldSlot(player, fieldSlot), "Field slot registration failed")
    elseif buildingId == "ChickenCoop" then
        assert(ChickenService.RegisterCoop(player, part), "Chicken coop registration failed")
    end
    return true, nil
end

function BuildService.Init()
    if initialized then return end
    initialized = true
    PlotService.Init()
    ChickenService.Init()
    local remote = ReplicatedStorage:FindFirstChild("BuildRequest")
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = "BuildRequest"
        remote.Parent = ReplicatedStorage
    end
    remote.OnServerEvent:Connect(function(player: Player, buildingId: string,
        gridX: number, gridZ: number, rotation: number)
        local ok, reason = BuildService.Place(player, buildingId, gridX, gridZ, rotation)
        remote:FireClient(player, ok, reason)
    end)
end

return BuildService
