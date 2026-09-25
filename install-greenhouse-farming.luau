-- Builds a four-bed greenhouse in the front half of every farm plot.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before installing the greenhouse")

local ServerScriptService = game:GetService("ServerScriptService")
local plots = workspace:WaitForChild("FarmLayout"):WaitForChild("Plots")

local COLORS = {
	frame = Color3.fromHex("FFCF4A"),
	glass = Color3.fromHex("F6F8FF"),
	bed = Color3.fromHex("C8753A"),
	soil = Color3.fromHex("8F583B"),
	wheat = Color3.fromHex("FFD84A"),
	tomato = Color3.fromHex("FF6B6B"),
	lettuce = Color3.fromHex("75D957"),
	carrot = Color3.fromHex("FF9F43"),
}

local CROPS = {
	{id = "Wheat", name = "Trigo", color = COLORS.wheat, reward = 12},
	{id = "Tomato", name = "Tomates", color = COLORS.tomato, reward = 18},
	{id = "Lettuce", name = "Lechuga", color = COLORS.lettuce, reward = 15},
	{id = "Carrot", name = "Zanahorias", color = COLORS.carrot, reward = 16},
}

local function part(parent, name, size, cframe, color, material, transparency)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cframe
	item.Anchored = true
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.Transparency = transparency or 0
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function createLabel(parent, text)
	local gui = Instance.new("BillboardGui")
	gui.Name = "CropLabel"
	gui.Size = UDim2.fromOffset(118, 30)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromHex("233447")
	label.BackgroundTransparency = 1
	label.TextStrokeColor3 = Color3.fromHex("233447")
	label.TextStrokeTransparency = 0.35
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.Text = text
	label.Parent = gui
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 5)
end

for _, plot in ipairs(plots:GetChildren()) do
	local pasture = plot:FindFirstChild("Pasture")
	if not (pasture and pasture:IsA("BasePart")) then continue end
	local old = plot:FindFirstChild("Greenhouse")
	if old then old:Destroy() end

	local greenhouse = Instance.new("Model")
	greenhouse.Name = "Greenhouse"
	greenhouse.Parent = plot
	local rear = pasture:GetAttribute("RearDirection") or 1
	-- Larger greenhouse shifted to the left/front tycoon area, with an open front entrance.
	local base = pasture.CFrame * CFrame.new(-8, pasture.Size.Y / 2, -rear * 4)

	-- A compact glass structure that leaves room around it for the future tycoon.
	part(greenhouse, "Foundation", Vector3.new(25, 0.3, 20), base * CFrame.new(0, 0.15, 0), COLORS.bed, Enum.Material.WoodPlanks)
	for _, x in ipairs({-12, 12}) do
		for _, z in ipairs({-9.5, 9.5}) do
			part(greenhouse, "FramePost", Vector3.new(0.45, 10, 0.45), base * CFrame.new(x, 5, z), COLORS.frame, Enum.Material.Metal)
		end
	end
	part(greenhouse, "Roof", Vector3.new(25, 0.25, 20), base * CFrame.new(0, 10, 0), COLORS.glass, Enum.Material.Glass, 0.35)
	for _, x in ipairs({-12, 12}) do
		part(greenhouse, "GlassWall", Vector3.new(0.18, 9.5, 19), base * CFrame.new(x, 5, 0), COLORS.glass, Enum.Material.Glass, 0.55)
	end
	part(greenhouse, "BackGlass", Vector3.new(25, 9.5, 0.18), base * CFrame.new(0, 5, rear * 9.5), COLORS.glass, Enum.Material.Glass, 0.55)
	-- The front is deliberately open: the two entrance posts define a clear passage.
	part(greenhouse, "EntranceLeft", Vector3.new(0.45, 7, 0.45), base * CFrame.new(-3, 3.5, -rear * 9.5), COLORS.frame, Enum.Material.Metal)
	part(greenhouse, "EntranceRight", Vector3.new(0.45, 7, 0.45), base * CFrame.new(3, 3.5, -rear * 9.5), COLORS.frame, Enum.Material.Metal)

	local beds = Instance.new("Folder")
	beds.Name = "Beds"
	beds.Parent = greenhouse
	for index, crop in ipairs(CROPS) do
		local row = index <= 2 and 1 or -1
		local column = index % 2 == 1 and -1 or 1
		local bed = part(beds, crop.id .. "Bed", Vector3.new(9, 0.55, 6.6), base * CFrame.new(column * 5.7, 0.55, row * 4.3), COLORS.soil, Enum.Material.Ground)
		bed:SetAttribute("CropId", crop.id)
		bed:SetAttribute("CropName", crop.name)
		bed:SetAttribute("Reward", crop.reward)
		bed:SetAttribute("State", "Empty")
		createLabel(bed, crop.name .. "\nListo para plantar")
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "FarmPrompt"
		prompt.ActionText = "Plantar"
		prompt.ObjectText = crop.name
		prompt.HoldDuration = 0.25
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = bed
	end
end

local serviceSource = [==[
local Players = game:GetService("Players")
local plots = workspace:WaitForChild("FarmLayout"):WaitForChild("Plots")
local growingFor = 12
local cooldown = {}

local cropColors = {
	Wheat = Color3.fromHex("FFD84A"), Tomato = Color3.fromHex("FF6B6B"),
	Lettuce = Color3.fromHex("75D957"), Carrot = Color3.fromHex("FF9F43"),
}

local function labelFor(bed)
	return bed:FindFirstChild("CropLabel") and bed.CropLabel:FindFirstChildOfClass("TextLabel")
end

local function clearPlant(bed)
	local old = bed:FindFirstChild("Plant")
	if old then old:Destroy() end
end

local function showPlant(bed, ripe)
	clearPlant(bed)
	local plant = Instance.new("Part")
	plant.Name = "Plant"
	plant.Shape = Enum.PartType.Ball
	plant.Size = ripe and Vector3.new(1.6, 2.1, 1.6) or Vector3.new(0.75, 0.9, 0.75)
	plant.CFrame = bed.CFrame * CFrame.new(0, bed.Size.Y / 2 + plant.Size.Y / 2, 0)
	plant.Anchored = true
	plant.CanCollide = false
	plant.Material = Enum.Material.SmoothPlastic
	plant.Color = cropColors[bed:GetAttribute("CropId")] or Color3.new(1, 1, 1)
	plant.Parent = bed
end

local function ownsPlot(player, bed)
	local plot = bed:FindFirstAncestorWhichIsA("Model")
	while plot and plot.Parent ~= plots do plot = plot.Parent end
	return plot and plot:GetAttribute("OwnerUserId") == player.UserId
end

local function canUse(player, bed)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and (root.Position - bed.Position).Magnitude <= 12 and ownsPlot(player, bed)
end

local function update(bed, state)
	bed:SetAttribute("State", state)
	local prompt = bed:FindFirstChild("FarmPrompt")
	local label = labelFor(bed)
	local name = bed:GetAttribute("CropName")
	if state == "Empty" then
		clearPlant(bed)
		prompt.ActionText = "Plantar"
		label.Text = name .. "\nListo para plantar"
	elseif state == "Growing" then
		showPlant(bed, false)
		prompt.Enabled = false
		label.Text = name .. "\nCreciendo..."
	elseif state == "Ready" then
		showPlant(bed, true)
		prompt.Enabled = true
		prompt.ActionText = "Cosechar"
		label.Text = name .. "\nListo para cosechar"
	end
end

for _, plot in ipairs(plots:GetChildren()) do
	local greenhouse = plot:FindFirstChild("Greenhouse")
	local beds = greenhouse and greenhouse:FindFirstChild("Beds")
	if not beds then continue end
	for _, bed in ipairs(beds:GetChildren()) do
		local prompt = bed:FindFirstChild("FarmPrompt")
		if not prompt then continue end
		prompt.Triggered:Connect(function(player)
			if not canUse(player, bed) then return end
			local key = tostring(player.UserId) .. ":" .. bed:GetDebugId()
			if cooldown[key] and time() - cooldown[key] < 0.5 then return end
			cooldown[key] = time()
			if bed:GetAttribute("State") == "Empty" then
				update(bed, "Growing")
				task.delay(growingFor, function()
					if bed.Parent and bed:GetAttribute("State") == "Growing" then update(bed, "Ready") end
				end)
			elseif bed:GetAttribute("State") == "Ready" then
				player:SetAttribute("Coins", (player:GetAttribute("Coins") or 0) + bed:GetAttribute("Reward"))
				update(bed, "Empty")
			end
		end)
	end
end
]==]

local service = ServerScriptService:FindFirstChild("GreenhouseFarmService") or Instance.new("Script")
service.Name = "GreenhouseFarmService"
service.Source = serviceSource
service.Parent = ServerScriptService

return "Installed four-crop greenhouses."
