-- Test doubles cover only the APIs used by these services.
local warn = function(...) print("WARN", ...) end
local function signal()
    local callbacks = {}
    return {
        Connect = function(_, callback)
            table.insert(callbacks, callback)
            return { Disconnect = function() end }
        end,
        Fire = function(_, ...)
            for _, callback in callbacks do callback(...) end
        end,
    }
end

local vectorMeta = {}
local Vector3 = {}
function Vector3.new(x, y, z)
    return setmetatable({ X = x, Y = y, Z = z }, vectorMeta)
end
vectorMeta.__add = function(a, b) return Vector3.new(a.X+b.X, a.Y+b.Y, a.Z+b.Z) end
vectorMeta.__sub = function(a, b) return Vector3.new(a.X-b.X, a.Y-b.Y, a.Z-b.Z) end
vectorMeta.__index = function(v, key)
    if key == "Magnitude" then return math.sqrt(v.X*v.X + v.Y*v.Y + v.Z*v.Z) end
end
local Color3 = { fromRGB = function(...) return {...} end }
local Vector2 = { new = function(x, y) return { X = x, Y = y } end }
local cframeMeta = { __mul = function(a, _) return a end }
local CFrame = {
    new = function(x, y, z)
        return setmetatable({ Position = Vector3.new(x, y, z) }, cframeMeta)
    end,
    Angles = function() return setmetatable({}, cframeMeta) end,
}
local draws = {}
local Random = {}
function Random.new()
    return { NextInteger = function(_, minimum, maximum)
        local value = table.remove(draws, 1) or 6
        assert(value >= minimum and value <= maximum)
        return value
    end }
end
local function queueDraw(value) table.insert(draws, value) end

local Instance = {}
function Instance.new(className)
    local object = { ClassName = className, attributes = {}, children = {}, Triggered = signal(), OnServerEvent = signal() }
    local parent = nil
    function object:SetAttribute(key, value) self.attributes[key] = value end
    function object:GetAttribute(key) return self.attributes[key] end
    function object:FindFirstChild(name)
        for _, child in self.children do if child.Name == name then return child end end
        return nil
    end
    function object:FindFirstChildOfClass(class)
        for _, child in self.children do if child.ClassName == class then return child end end
        return nil
    end
    function object:GetChildren() return table.clone(self.children) end
    function object:GetDescendants()
        local result = {}
        local function visit(parent)
            for _, child in parent.children do
                table.insert(result, child)
                visit(child)
            end
        end
        visit(self)
        return result
    end
    function object:WaitForChild(name)
        local child = self:FindFirstChild(name)
        assert(child, "Missing test instance: " .. name)
        return child
    end
    function object:Clone()
        local copy = Instance.new(self.ClassName)
        copy.Name = self.Name
        copy.Size = self.Size
        copy.Position = self.Position
        copy.Color = self.Color
        copy.Anchored = self.Anchored
        copy.Text = self.Text
        copy.attributes = table.clone(self.attributes)
        for _, child in self.children do child:Clone().Parent = copy end
        return copy
    end
    function object:FireClient() end
    function object:IsA(class) return class == self.ClassName or (class == "BasePart" and self.ClassName == "Part") end
    function object:IsDescendantOf(ancestor)
        local current = self.Parent
        while current do
            if current == ancestor then return true end
            current = current.Parent
        end
        return false
    end
    function object:Destroy()
        local children = table.clone(self.children)
        for _, child in children do child:Destroy() end
        self.Parent = nil
    end
    return setmetatable(object, {
        __index = function(_, key) if key == "Parent" then return parent end end,
        __newindex = function(self, key, value)
            if key == "CFrame" then
                rawset(self, key, value)
                rawset(self, "Position", value.Position)
                return
            end
            if key ~= "Parent" then rawset(self, key, value); return end
            if parent then
                local index = table.find(parent.children, self)
                if index then table.remove(parent.children, index) end
            end
            parent = value
            if parent then table.insert(parent.children, self) end
        end,
    })
end
local workspace = Instance.new("Workspace")
local ranchPlots = Instance.new("Folder")
ranchPlots.Name = "RanchPlots"
ranchPlots.Parent = workspace
local firstPlot = Instance.new("Model")
firstPlot.Name = "Plot_1"
firstPlot.Parent = ranchPlots
firstPlot:SetAttribute("PlotIndex", 1)
local function plotPart(name, x, y, z, sx, sy, sz)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Position = Vector3.new(x, y, z)
    part.Size = Vector3.new(sx, sy, sz)
    part.Parent = firstPlot
end
plotPart("Ground", 0, 0, 24, 54, 1, 72)
plotPart("CropSlot", 0, 0.75, 24, 6, 0.5, 6)
plotPart("SeedShop", -7, 0.75, 24, 3, 0.5, 3)
plotPart("SellPad", 7, 0.75, 24, 3, 0.5, 3)
local ownerSign = Instance.new("Model")
ownerSign.Name = "OwnerSign"
ownerSign.Parent = firstPlot
local ownerText = Instance.new("TextLabel")
ownerText.Name = "OwnerText"
ownerText.Text = "Parcela 1\nDisponible"
ownerText.Parent = ownerSign
for index = 2, 8 do
    local model = firstPlot:Clone()
    model.Name = "Plot_" .. index
    model:SetAttribute("PlotIndex", index)
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.Position += Vector3.new((index - 1) * 64, 0, 0)
        elseif descendant:IsA("TextLabel") then
            descendant.Text = "Parcela " .. index .. "\nDisponible"
        end
    end
    model.Parent = ranchPlots
end
local replicatedStorage = Instance.new("ReplicatedStorage")
local saved = {}
local fakeStore = {
    GetAsync = function(self, key)
        if self.FailRead then error("simulated read failure") end
        return saved[key]
    end,
    UpdateAsync = function(_, key, transform)
        saved[key] = transform(saved[key])
        return saved[key]
    end,
}
local DataStoreService = { GetDataStore = function() return fakeStore end }
local RunService = { IsStudio = function() return false end }
local Players = { PlayerAdded = signal(), PlayerRemoving = signal(), list = {} }
function Players:GetPlayers() return table.clone(self.list) end
local game = { GameId = 123, BindToClose = function() end, GetService = function(_, name)
    if name == "Players" then return Players end
    if name == "ReplicatedStorage" then return replicatedStorage end
    if name == "DataStoreService" then return DataStoreService end
    if name == "RunService" then return RunService end
    return {}
end }
local now = 0
local scheduled = {}
local os = {
    clock = function() return now end,
    time = function() return math.floor(1700000000 + now) end,
}
local task = {}
function task.delay(seconds, callback)
    table.insert(scheduled, { At = now + seconds, Callback = callback })
end
function task.defer(callback) task.delay(0, callback) end
local function advance(seconds)
    local target = now + seconds
    while true do
        table.sort(scheduled, function(a, b) return a.At < b.At end)
        if #scheduled == 0 or scheduled[1].At > target then break end
        local event = table.remove(scheduled, 1)
        now = event.At
        event.Callback()
    end
    now = target
end
local function join(id)
    local player = { UserId = id, Parent = Players, Name = "Player" .. id, DisplayName = "Farmer" .. id }
    function player:Kick(message) self.KickMessage = message end
    table.insert(Players.list, player)
    Players.PlayerAdded:Fire(player)
    return player
end
local function leave(player)
    Players.PlayerRemoving:Fire(player)
    table.remove(Players.list, table.find(Players.list, player))
    player.Parent = nil
end
