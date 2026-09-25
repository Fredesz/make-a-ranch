-- Moves the greenhouse entrance to the positive local-X side of each plot.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before moving greenhouse entrances")

local function part(parent, name, size, cframe, color, material, transparency)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cframe
	item.Anchored = true
	item.Color = color
	item.Material = material
	item.Transparency = transparency or 0
	item.Parent = parent
	return item
end

for _, plot in ipairs(workspace.FarmLayout.Plots:GetChildren()) do
	local greenhouse = plot:FindFirstChild("Greenhouse")
	if not greenhouse then continue end
	local base = greenhouse.Foundation.CFrame * CFrame.new(0, -0.18, 0)
	local rear = plot.Pasture:GetAttribute("RearDirection") or 1
	for _, item in ipairs(greenhouse:GetChildren()) do
		if item.Name == "SideDoor" or item.Name == "EntranceFrame" or item.Name == "EntranceHeader" then
			item:Destroy()
		elseif item.Name == "SideGlass" and base:PointToObjectSpace(item.Position).X > 0 then
			item:Destroy()
		end
	end
	local glass = Color3.fromHex("DDF7E8")
	local frame = Color3.fromHex("285548")
	local door = Instance.new("Model")
	door.Name = "SideDoor"
	door.Parent = greenhouse
	part(door, "FrontGlass", Vector3.new(24.5, 6.4, 0.14), base * CFrame.new(0, 3.6, -rear * 9.5), glass, Enum.Material.Glass, 0.32)
	for _, z in ipairs({-6.5, 6.5}) do
		part(door, "SideGlass", Vector3.new(0.14, 6.4, 6), base * CFrame.new(12, 3.6, z), glass, Enum.Material.Glass, 0.32)
	end
	for _, z in ipairs({-3.2, 3.2}) do
		part(door, "DoorFrame", Vector3.new(0.42, 7, 0.42), base * CFrame.new(12, 3.5, z), frame, Enum.Material.Metal)
	end
	part(door, "DoorHeader", Vector3.new(0.42, 0.42, 6.8), base * CFrame.new(12, 6.8, 0), frame, Enum.Material.Metal)
	for _, y in ipairs({2.4, 4.6}) do
		part(door, "SideRail", Vector3.new(0.24, 0.24, 12.8), base * CFrame.new(12, y, 0), frame, Enum.Material.Metal)
	end
end

return "Moved greenhouse entrances to the marked side."
