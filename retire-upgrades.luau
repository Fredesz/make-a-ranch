-- Retires the first upgrade system while keeping the game playable.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before retiring upgrades")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local economy = ServerScriptService:WaitForChild("MinimalEconomyService")
local source = economy.Source
source = source:gsub("local upgrades = %b{}.-local function getCoinsValue", "local INVENTORY_CAPACITY = 100\n\nlocal function getCoinsValue")
source = source:gsub("%s*dataState%.progress = %{%}.-publishProgress%(player, dataState%)", "\n\t\tplayer:SetAttribute(\"InventoryCapacity\", INVENTORY_CAPACITY)")
source = source:gsub("%s*else\n\t\tlocal key = type%(action%) == \"string\".-publishProgress%(player,state%)\n\tend", "\n\telse\n\t\treturn false\n\tend")
source = source:gsub("local upgradeRemote = remotesFolder:FindFirstChild%(\"BuyProgressUpgrade\"%).-end%)\n", "")
economy.Source = source

local expedition = ServerScriptService:WaitForChild("ExpeditionService")
source = expedition.Source
source = source:gsub("local rules=require%(game%.ReplicatedStorage%.ProgressionRules%)\n", "")
source = source:gsub("%s*if zone==2 and %(p:GetAttribute%(\"ZoneLevel\"%) or 0%)<1 then tell%(p,\"Desbloquea el Prado azul en Mejoras%.\"%) return end", "")
source = source:gsub("%(p:GetAttribute%(\"InventoryCapacity\"%) or 10%)", "100")
source = source:gsub("Inventario lleno%. Amplia los espacios en Mejoras%.", "Inventario lleno.")
source = source:gsub("local chance=rules%.Chance%(definition%.chance,p:GetAttribute%(\"BaitLevel\"%) or 0,p:GetAttribute%(\"LuckLevel\"%) or 0,s%.zone%)", "local chance=math.min(0.95, definition.chance + (s.zone==2 and 0.1 or 0))")
expedition.Source = source

local pets = ServerScriptService:WaitForChild("TestPetService")
pets.Source = pets.Source:gsub("%(player:GetAttribute%(\"InventoryCapacity\"%) or 10%)", "100")

local hud = StarterPlayer.StarterPlayerScripts:WaitForChild("FarmHudClient")
source = hud.Source
source = source:gsub("UDim2.fromOffset%(18,272%)", "UDim2.fromOffset(18,224)")
source = source:gsub("task%.spawn%(function%(%)[%s%S]-local g=pg:WaitForChild%(\"ProgressionGui\"%)[%s%S]-end%)\n", "")
hud.Source = source

local progression = StarterPlayer.StarterPlayerScripts:FindFirstChild("ProgressionClient")
if progression then progression.Disabled = true end

return "Retired upgrades safely; legacy save data remains unused."
