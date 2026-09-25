-- Creates a straight rear paddock and stable swinging gate in every farm plot.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before installing")

local plots = workspace:WaitForChild("FarmLayout"):WaitForChild("Plots")
local DARK_WOOD = Color3.fromRGB(100, 70, 52)
local LIGHT_WOOD = Color3.fromRGB(190, 171, 142)

for _, plot in ipairs(plots:GetChildren()) do
	local pasture = plot:FindFirstChild("Pasture", true)
	assert(pasture and pasture:IsA("BasePart"), "Missing pasture: " .. plot.Name)
	local sign = plot:FindFirstChild("PlotSign")
	local signPart = sign and sign:FindFirstChildWhichIsA("BasePart", true)
	assert(signPart, "Missing entrance sign: " .. plot.Name)

	local entranceZ = pasture.CFrame:PointToObjectSpace(signPart.Position).Z
	local rearDirection = entranceZ > 0 and -1 or 1
	local dividerZ = rearDirection * pasture.Size.Z * 0.16
	pasture:SetAttribute("RearDirection", rearDirection)
	pasture:SetAttribute("PaddockDividerZ", dividerZ)

	local old = plot:FindFirstChild("PaddockDivider")
	if old then old:Destroy() end

	local divider = Instance.new("Model")
	divider.Name = "PaddockDivider"
	divider:SetAttribute("RearDirection", rearDirection)
	divider:SetAttribute("Open", false)
	divider.Parent = plot
	local ground = pasture.CFrame * CFrame.new(0, pasture.Size.Y / 2, 0)

	local function makePart(parent, name, size, localOffset, color)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = ground * CFrame.new(localOffset)
		part.Anchored = true
		part.Material = Enum.Material.Wood
		part.Color = color
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = parent
		return part
	end

	local gateWidth = 9
	local halfWidth = pasture.Size.X / 2
	local sideLength = halfWidth - gateWidth / 2
	local postSpacing = 7.5
	for _, side in ipairs({-1, 1}) do
		local centerX = side * (gateWidth / 2 + sideLength / 2)
		local postCount = math.ceil(sideLength / postSpacing)
		for index = 0, postCount do
			local x = side * (gateWidth / 2 + sideLength * index / postCount)
			makePart(divider, "FencePost", Vector3.new(0.7, 3.7, 0.7), Vector3.new(x, 1.85, dividerZ), DARK_WOOD)
		end
		for _, y in ipairs({1.1, 2.65}) do
			makePart(divider, "FenceRail", Vector3.new(sideLength, 0.38, 0.38), Vector3.new(centerX, y, dividerZ), LIGHT_WOOD)
		end
	end

	local gate = Instance.new("Model")
	gate.Name = "Gate"
	gate.Parent = divider
	local hinge = makePart(gate, "Hinge", Vector3.new(0.2, 0.2, 0.2), Vector3.new(-gateWidth / 2, 0, dividerZ), DARK_WOOD)
	hinge.Transparency = 1
	hinge.CanCollide = false
	hinge.CanTouch = false
	hinge.CanQuery = false
	gate.PrimaryPart = hinge
	local hingeCFrame = hinge.CFrame
	local function gatePart(name, size, offset, color)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = hingeCFrame * CFrame.new(offset)
		part.Anchored = true
		part.Material = Enum.Material.Wood
		part.Color = color
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = gate
		return part
	end
	for _, y in ipairs({1.05, 2.6}) do
		gatePart("GateRail", Vector3.new(gateWidth - 0.55, 0.4, 0.42), Vector3.new((gateWidth - 0.55) / 2, y, 0), DARK_WOOD)
	end
	for x = 0.55, gateWidth - 0.55, 1.75 do
		gatePart("GatePicket", Vector3.new(0.42, 2.5, 0.42), Vector3.new(x, 1.6, 0), LIGHT_WOOD)
	end

	local control = makePart(divider, "GateControl", Vector3.new(0.4, 0.5, 0.55), Vector3.new(gateWidth / 2, 2.05, dividerZ - rearDirection * 0.35), Color3.fromRGB(68, 73, 70))
	control.Material = Enum.Material.Metal
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ToggleGate"
	prompt.ActionText = "Abrir puerta"
	prompt.ObjectText = "Corral trasero"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = control
end

local source = [==[
local TweenService = game:GetService("TweenService")
local plots = workspace:WaitForChild("FarmLayout"):WaitForChild("Plots")

for _, plot in ipairs(plots:GetChildren()) do
	local divider = plot:WaitForChild("PaddockDivider")
	local gate = divider:WaitForChild("Gate")
	local control = divider:WaitForChild("GateControl")
	local prompt = control:WaitForChild("ToggleGate")
	local closed = gate.PrimaryPart.CFrame
	local angle = Instance.new("NumberValue")
	angle.Value = 0
	angle.Parent = gate
	local busy = false

	angle.Changed:Connect(function(value)
		gate:PivotTo(closed * CFrame.Angles(0, value, 0))
	end)
	prompt.Triggered:Connect(function(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if busy or not root or not humanoid or humanoid.Health <= 0 then return end
		if (root.Position - control.Position).Magnitude > 12 then return end
		busy = true
		local open = not divider:GetAttribute("Open")
		local target = open and -divider:GetAttribute("RearDirection") * math.pi / 2 or 0
		local tween = TweenService:Create(angle, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {Value = target})
		tween:Play()
		tween.Completed:Wait()
		divider:SetAttribute("Open", open)
		prompt.ActionText = open and "Cerrar puerta" or "Abrir puerta"
		busy = false
	end)
end
]==]

local service = game.ServerScriptService:FindFirstChild("PaddockGateService") or Instance.new("Script")
service.Name = "PaddockGateService"
service.Source = source
service.Parent = game.ServerScriptService
return "Installed aligned rear paddocks with stable gates."
