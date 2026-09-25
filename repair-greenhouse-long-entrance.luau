-- Repairs the greenhouse shell and places the entrance on its long wall.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before repairing greenhouses")

local FRAME = Color3.fromHex("285548")
local GLASS = Color3.fromHex("DDF7E8")

local function part(parent, name, size, cframe, color, material, transparency)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cframe
	item.Anchored = true
	item.Color = color
	item.Material = material
	item.Transparency = transparency or 0
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

for _, plot in ipairs(workspace.FarmLayout.Plots:GetChildren()) do
	local greenhouse = plot:FindFirstChild("Greenhouse")
	if not greenhouse then continue end
	local base = greenhouse.Foundation.CFrame * CFrame.new(0, -0.18, 0)
	local rear = plot.Pasture:GetAttribute("RearDirection") or 1

	for _, name in ipairs({"SideDoor", "LongSideEntrance"}) do
		local old = greenhouse:FindFirstChild(name)
		if old then old:Destroy() end
	end
	for _, item in ipairs(greenhouse:GetChildren()) do
		if item.Name == "SideGlass" and base:PointToObjectSpace(item.Position).X > 0 then
			item:Destroy()
		end
	end

	-- Restore the short wall that was opened by the previous entrance.
	part(greenhouse, "SideGlass", Vector3.new(0.14, 6.4, 19), base * CFrame.new(12, 3.6, 0), GLASS, Enum.Material.Glass, 0.32)

	local entrance = Instance.new("Model")
	entrance.Name = "LongSideEntrance"
	entrance.Parent = greenhouse
	local frontZ = -rear * 9.5
	local panelWidth = 9.15
	for _, side in ipairs({-1, 1}) do
		part(entrance, "FrontGlass", Vector3.new(panelWidth, 6.4, 0.14), base * CFrame.new(side * 7.825, 3.6, frontZ), GLASS, Enum.Material.Glass, 0.32)
		part(entrance, "WallPost", Vector3.new(0.3, 6.7, 0.3), base * CFrame.new(side * 7.8, 3.5, frontZ), FRAME, Enum.Material.Metal)
		for _, y in ipairs({2.4, 4.7}) do
			part(entrance, "WallRail", Vector3.new(panelWidth, 0.24, 0.24), base * CFrame.new(side * 7.825, y, frontZ), FRAME, Enum.Material.Metal)
		end
	end
	for _, x in ipairs({-3.25, 3.25}) do
		part(entrance, "DoorFrame", Vector3.new(0.42, 7, 0.42), base * CFrame.new(x, 3.5, frontZ), FRAME, Enum.Material.Metal)
	end
	part(entrance, "DoorHeader", Vector3.new(6.9, 0.42, 0.42), base * CFrame.new(0, 6.8, frontZ), FRAME, Enum.Material.Metal)
	entrance:SetAttribute("EntranceWall", "Long")
end

return "Repaired greenhouses with centered entrances on the long wall."
