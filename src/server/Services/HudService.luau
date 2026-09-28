--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataService = require(script.Parent.Parent.PlayerDataService)

local HudService = {}
local initialized = false

function HudService.Init()
    if initialized then return end
    initialized = true

    local snapshot = Instance.new("RemoteFunction")
    snapshot.Name = "GetHudState"
    snapshot.OnServerInvoke = function(player: Player)
        local data = PlayerDataService.GetData(player)
        if not data then return nil end
        return {
            Coins = data.Coins,
            Inventory = data.Inventory,
            Buildings = data.Buildings,
            Seeds = data.Seeds,
        }
    end
    snapshot.Parent = ReplicatedStorage

    local notice = Instance.new("RemoteEvent")
    notice.Name = "HudNotice"
    notice.Parent = ReplicatedStorage
end

return HudService
