-- Applies the Safari Candy palette to the current farm and keeps player UI themed.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before applying the palette")

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local StarterPlayer = game:GetService("StarterPlayer")

local COLORS = {
	-- The whole home farm shares the same readable light-green ground.
	grass = Color3.fromHex("A7F05A"),
	plot = Color3.fromHex("A7F05A"),
	sand = Color3.fromHex("F2C66D"),
	fence = Color3.fromHex("C8753A"),
	sign = Color3.fromHex("FFCF4A"),
	coral = Color3.fromHex("FF6B6B"),
	expedition = Color3.fromHex("39B8FF"),
	shop = Color3.fromHex("8B5CFF"),
	mountain = Color3.fromHex("5FBF7A"),
	snow = Color3.fromHex("F6F8FF"),
	panel = Color3.fromHex("233447"),
	primary = Color3.fromHex("FFD84A"),
	ink = Color3.fromHex("233447"),
	white = Color3.fromRGB(255, 255, 255),
}

local function recolorWorld()
	local layout = workspace:WaitForChild("FarmLayout")
	local meadow = layout:FindFirstChild("Meadow")
	if meadow and meadow:IsA("BasePart") then
		meadow.Color = COLORS.grass
	end

	for _, instance in ipairs(layout:GetDescendants()) do
		if instance:IsA("BasePart") then
			local name = instance.Name
			if name == "Pasture" or name:find("Foothill") then
				instance.Color = COLORS.plot
			elseif name == "CentralWalkway" or name == "ConnectingPath" or name == "SpawnPlaza" then
				instance.Color = COLORS.sand
			elseif name == "FenceRail" or name == "FencePost" or name == "GateRail" or name == "GatePost" then
				instance.Color = COLORS.fence
			elseif name == "Roof" or name == "Hay" then
				instance.Color = COLORS.coral
			elseif name == "Post" or name == "SignPost" then
				instance.Color = COLORS.sign
			end
		end
	end

	for _, plot in ipairs(layout:WaitForChild("Plots"):GetChildren()) do
		local sign = plot:FindFirstChild("PlotSign")
		if sign then
			for _, instance in ipairs(sign:GetDescendants()) do
				if instance:IsA("BasePart") then
					instance.Color = COLORS.sign
				elseif instance:IsA("TextLabel") then
					instance.TextColor3 = COLORS.ink
				end
			end
		end
	end

	local border = layout:FindFirstChild("MountainBorder")
	if border then
		for _, mountain in ipairs(border:GetChildren()) do
			if mountain:IsA("Model") then
				local pieces, highest = {}, -math.huge
				for _, piece in ipairs(mountain:GetDescendants()) do
					if piece:IsA("BasePart") then
						table.insert(pieces, piece)
						highest = math.max(highest, piece.Position.Y)
					end
				end
				for _, piece in ipairs(pieces) do
					piece.Color = piece.Position.Y > highest - 8 and COLORS.snow or COLORS.mountain
					piece.Material = Enum.Material.SmoothPlastic
				end
			elseif mountain:IsA("BasePart") and mountain.Name:find("Foothill") then
				mountain.Color = COLORS.mountain
			end
		end
	end

	local expeditionAreas = workspace:FindFirstChild("ExpeditionAreas")
	if expeditionAreas then
		for _, instance in ipairs(expeditionAreas:GetDescendants()) do
			if instance:IsA("BasePart") and instance.Name == "Meadow" then
				instance.Color = COLORS.expedition
			end
		end
	end
end

local playerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local previous = playerScripts:FindFirstChild("SafariCandyTheme")
if previous then previous:Destroy() end

local theme = Instance.new("LocalScript")
theme.Name = "SafariCandyTheme"
theme.Source = [==[
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local colors = {
	panel = Color3.fromHex("233447"), primary = Color3.fromHex("FFD84A"),
	expedition = Color3.fromHex("39B8FF"), shop = Color3.fromHex("8B5CFF"),
	coral = Color3.fromHex("FF6B6B"), ink = Color3.fromHex("233447"), white = Color3.new(1, 1, 1),
}

local function style(item)
	if item:IsA("TextButton") then
		local name = item.Name:lower()
		if name:find("claim") or name:find("test") then
			item.BackgroundColor3 = colors.primary
			item.TextColor3 = colors.ink
		elseif name:find("expedition") or name:find("travel") then
			item.BackgroundColor3 = colors.expedition
			item.TextColor3 = colors.white
		elseif name:find("buy") or name:find("upgrade") or name:find("improve") then
			item.BackgroundColor3 = colors.shop
			item.TextColor3 = colors.white
		elseif name:find("mascota") or name:find("pet") then
			item.BackgroundColor3 = colors.coral
			item.TextColor3 = colors.white
		end
	elseif item:IsA("Frame") and (item.Name == "Panel" or item.Name == "EconomyPanel" or item.Name == "ExpeditionCatalog") then
		item.BackgroundColor3 = colors.panel
	elseif item:IsA("TextLabel") and item.Name == "CoinLabel" then
		item.TextColor3 = colors.primary
	end
end

for _, item in ipairs(gui:GetDescendants()) do style(item) end
gui.DescendantAdded:Connect(style)
]==]
theme.Parent = playerScripts

ChangeHistoryService:SetWaypoint("Safari Candy palette applied")
recolorWorld()
return "Safari Candy palette applied"
