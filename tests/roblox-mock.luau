-- Test doubles cover only the APIs used by these services.
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

local Instance = {}
function Instance.new(className)
    local object = { ClassName = className, attributes = {}, children = {}, Triggered = signal() }
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
local Players = { PlayerAdded = signal(), PlayerRemoving = signal(), list = {} }
function Players:GetPlayers() return table.clone(self.list) end
local game = { GetService = function(_, name)
    if name == "Players" then return Players end
    return {}
end }
local now = 0
local scheduled = {}
local os = { clock = function() return now end }
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
    local player = { UserId = id, Parent = Players }
    table.insert(Players.list, player)
    Players.PlayerAdded:Fire(player)
    return player
end
local function leave(player)
    Players.PlayerRemoving:Fire(player)
    table.remove(Players.list, table.find(Players.list, player))
    player.Parent = nil
end
