-- Run in Roblox Studio's command bar in Edit mode.
-- Creates a minimal, server-authoritative coin economy with a temporary test UI.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local claimCoinsRemote = remotesFolder:FindFirstChild("ClaimTestCoins")
if not claimCoinsRemote then
	claimCoinsRemote = Instance.new("RemoteEvent")
	claimCoinsRemote.Name = "ClaimTestCoins"
	claimCoinsRemote.Parent = remotesFolder
end

local serverSource = [==[
-- MinimalEconomyService
-- The server owns coin balances. Client buttons can only request trusted server rewards.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local claimCoinsRemote = remotesFolder:WaitForChild("ClaimTestCoins")
local coinStore = DataStoreService:GetDataStore("FarmRngTycoon_EconomyProfiles_v1")

local STARTING_COINS = 0
local TEST_CLAIM_REWARD = 10
local TEST_CLAIM_COOLDOWN_SECONDS = 1.5

local lastClaimByPlayer = {}
local dataStateByPlayer = {}
local upgrades = {
 Slots = {attribute="InventoryLevel", max=3, price=200},
 Bait = {attribute="BaitLevel", max=2, price=300},
 Luck = {attribute="LuckLevel", max=5, price=250},
 Zone = {attribute="ZoneLevel", max=1, price=600},
}
local function publishProgress(player, state)
 for key, definition in pairs(upgrades) do
  player:SetAttribute(definition.attribute, state.progress[key])
 end
 player:SetAttribute("InventoryCapacity",10 + state.progress.Slots * 10)
end

local function getCoinsValue(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local coins = leaderstats:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = STARTING_COINS
		coins.Parent = leaderstats
	end

	return coins
end

local function setCoins(player, amount)
	local coins = getCoinsValue(player)
	coins.Value = math.max(0, math.floor(amount))
	player:SetAttribute("Coins", coins.Value)
	return coins.Value
end

local function saveCoins(player)
	local dataState = dataStateByPlayer[player]
	if not dataState or not dataState.loaded or not dataState.canSave then
		return false
	end
	local coins = getCoinsValue(player)
	while dataState.saving do task.wait(0.05) end
	dataState.saving = true
	local success, err = pcall(function()
		coinStore:UpdateAsync("Player_" .. player.UserId, function(oldData)
			local data = type(oldData) == "table" and oldData or {}
			data.version = 1
			data.coins = coins.Value
			data.bait = dataState.bait or 0
			data.progress = table.clone(dataState.progress)
			data.preferredPlotId = player:GetAttribute("PreferredPlotId") or player:GetAttribute("AssignedPlotId") or 0
			return data
		end)
	end)
	dataState.saving = false
	if not success then
		warn("[Economy] Could not save coins for " .. player.Name .. ": " .. tostring(err))
		return false
	end
	dataState.dirty = false
	return true
end

local function addCoins(player, amount, reason)
	if typeof(amount) ~= "number" or amount <= 0 then
		warn("Ignored invalid coin award for " .. player.Name .. ": " .. tostring(amount))
		return 0
	end

	local coins = getCoinsValue(player)
	local newBalance = setCoins(player, coins.Value + amount)
	local dataState = dataStateByPlayer[player]
	if dataState then dataState.dirty = true end
	print(("[Economy] Awarded %d coins to %s for %s. Balance: %d"):format(amount, player.Name, reason or "unknown", newBalance))
	return newBalance
end

local function canClaimTestCoins(player)
	local now = os.clock()
	local lastClaim = lastClaimByPlayer[player] or 0
	if now - lastClaim < TEST_CLAIM_COOLDOWN_SECONDS then
		return false
	end

	lastClaimByPlayer[player] = now
	return true
end

local function onPlayerAdded(player)
	if dataStateByPlayer[player] then return end
	local dataState = {loaded = false, canSave = false, dirty = false}
	dataStateByPlayer[player] = dataState
	setCoins(player, STARTING_COINS)
	player:SetAttribute("EconomyDataLoaded", false)
	local success, data = pcall(function()
		return coinStore:GetAsync("Player_" .. player.UserId)
	end)
	for attempt = 1, 2 do
		if success then break end
		task.wait(attempt)
		success, data = pcall(function() return coinStore:GetAsync("Player_" .. player.UserId) end)
	end
	if player.Parent ~= Players then dataStateByPlayer[player] = nil return end
	if success then
		local savedCoins = type(data) == "table" and tonumber(data.coins) or nil
		setCoins(player, savedCoins or STARTING_COINS)
		dataState.bait = math.max(0, math.floor(type(data) == "table" and tonumber(data.bait) or 0))
		player:SetAttribute("Bait", dataState.bait)
		dataState.canSave = true
		dataState.progress = {}
		for key, definition in pairs(upgrades) do
			local value = type(data) == "table" and type(data.progress) == "table" and tonumber(data.progress[key]) or 0
			dataState.progress[key] = math.clamp(math.floor(value or 0),0,definition.max)
		end
		publishProgress(player, dataState)
		player:SetAttribute("PreferredPlotId",type(data) == "table" and tonumber(data.preferredPlotId) or 0)
	else
		warn("[Economy] Could not load coins for " .. player.Name .. ": " .. tostring(data))
		player:Kick("No se pudo cargar tu progreso. Vuelve a entrar para proteger tus datos.")
		return
	end
	dataState.loaded = true
	player:SetAttribute("EconomyDataLoaded", true)
end

local function onPlayerRemoving(player)
	saveCoins(player)
	lastClaimByPlayer[player] = nil
	dataStateByPlayer[player] = nil
end

local function onClaimTestCoins(player)
	local dataState = dataStateByPlayer[player]
	if not dataState or not dataState.loaded then
		return
	end
	if not canClaimTestCoins(player) then
		return
	end

	addCoins(player, TEST_CLAIM_REWARD, "temporary test button")
end

Players.PlayerAdded:Connect(onPlayerAdded)
local baitTransaction = Instance.new("BindableFunction")
baitTransaction.Name = "BaitTransaction"
baitTransaction.Parent = script
baitTransaction.OnInvoke = function(player, action)
	local state = dataStateByPlayer[player]
	if not state or not state.loaded or not state.canSave then return false end
	if action == "Buy" then
		local coins = getCoinsValue(player)
		if coins.Value < 10 then return false end
		setCoins(player, coins.Value - 10)
		state.bait += 1
	elseif action == "Consume" then
		if state.bait < 1 then return false end
		state.bait -= 1
	elseif action == "Refund" then
		state.bait += 1
	else
		local key = type(action) == "string" and action:match("^Upgrade:(%w+)$")
		local definition = key and upgrades[key]
		if not definition then return false end
		local level = state.progress[key]
		local cost = definition.price * (level + 1)
		if level >= definition.max or getCoinsValue(player).Value < cost then return false end
		setCoins(player,getCoinsValue(player).Value - cost)
		state.progress[key] = level + 1
		publishProgress(player,state)
	end
	state.dirty = true
	player:SetAttribute("Bait", state.bait)
	return true
end
local upgradeRemote = remotesFolder:FindFirstChild("BuyProgressUpgrade") or Instance.new("RemoteEvent")
upgradeRemote.Name = "BuyProgressUpgrade"
upgradeRemote.Parent = remotesFolder
upgradeRemote.OnServerEvent:Connect(function(player,key)
 local state = dataStateByPlayer[player]
 if not state or type(key) ~= "string" or not upgrades[key] then return end
 if os.clock() - (state.lastUpgrade or -math.huge) < 0.6 then return end
 state.lastUpgrade = os.clock()
 local ok = baitTransaction:Invoke(player,"Upgrade:" .. key)
 player:SetAttribute("ProgressMessage",ok and "Mejora comprada." or "Saldo insuficiente, nivel maximo o datos cargando.")
 if ok then task.spawn(saveCoins,player) end
end)
Players.PlayerRemoving:Connect(onPlayerRemoving)
claimCoinsRemote.OnServerEvent:Connect(onClaimTestCoins)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

task.spawn(function()
	while true do
		task.wait(60)
		for player, dataState in pairs(dataStateByPlayer) do
			if dataState.loaded and dataState.canSave then
				task.spawn(saveCoins, player)
			end
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveCoins(player)
	end
end)
]==]

local existingServerScript = ServerScriptService:FindFirstChild("MinimalEconomyService")
if existingServerScript then
	existingServerScript:Destroy()
end

local serverScript = Instance.new("Script")
serverScript.Name = "MinimalEconomyService"
serverScript.Source = serverSource
serverScript.Parent = ServerScriptService

local playerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local clientSource = [==[
-- MinimalEconomyClient
-- Temporary prototype UI for testing the first coin loop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local claimCoinsRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClaimTestCoins")

local existingGui = player:WaitForChild("PlayerGui"):FindFirstChild("EconomyGui")
if existingGui then
	existingGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "EconomyGui"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local panel = Instance.new("Frame")
panel.Name = "CoinPanel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromOffset(18, 18)
panel.Size = UDim2.fromOffset(210, 86)
panel.BackgroundColor3 = Color3.fromRGB(35, 30, 24)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(237, 190, 82)
stroke.Thickness = 2
stroke.Transparency = 0.2
stroke.Parent = panel

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.BackgroundTransparency = 1
coinLabel.Position = UDim2.fromOffset(14, 10)
coinLabel.Size = UDim2.fromOffset(182, 28)
coinLabel.Font = Enum.Font.GothamBold
coinLabel.Text = "Coins: 0"
coinLabel.TextColor3 = Color3.fromRGB(255, 228, 132)
coinLabel.TextSize = 22
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Parent = panel

local claimButton = Instance.new("TextButton")
claimButton.Name = "ClaimTestCoinsButton"
claimButton.Position = UDim2.fromOffset(14, 44)
claimButton.Size = UDim2.fromOffset(182, 30)
claimButton.BackgroundColor3 = Color3.fromRGB(93, 143, 68)
claimButton.BorderSizePixel = 0
claimButton.Font = Enum.Font.GothamBold
claimButton.Text = "+10 Test Coins"
claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
claimButton.TextSize = 16
claimButton.Parent = panel

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = claimButton

local function updateCoins()
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	coinLabel.Text = "Coins: " .. tostring(coins and coins.Value or player:GetAttribute("Coins") or 0)
end

local function watchCoins()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		updateCoins()
		return
	end

	local coins = leaderstats:WaitForChild("Coins", 10)
	if coins then
		coins:GetPropertyChangedSignal("Value"):Connect(updateCoins)
	end

	updateCoins()
end

claimButton.Activated:Connect(function()
	claimCoinsRemote:FireServer()
end)

player:GetAttributeChangedSignal("Coins"):Connect(updateCoins)
task.spawn(watchCoins)
updateCoins()
]==]

local existingClientScript = playerScripts:FindFirstChild("MinimalEconomyClient")
if existingClientScript then
	existingClientScript:Destroy()
end

local clientScript = Instance.new("LocalScript")
clientScript.Name = "MinimalEconomyClient"
clientScript.Source = clientSource
clientScript.Parent = playerScripts

return "Installed persistent coin economy with server validation and autosave."
