--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VariantConfig = require(ReplicatedStorage.Shared.Config.VariantConfig)

type Entry = { Id: string, Weight: number }
local entries: { Entry } = {}
local totalWeight = 0
for id, definition in VariantConfig do
    local weight = definition.Weight
    assert(weight >= 0 and weight % 1 == 0, "Variant weights must be non-negative integers")
    if weight > 0 then
        totalWeight += weight
        table.insert(entries, { Id = id, Weight = weight })
    end
end
assert(totalWeight > 0, "At least one variant is required")
table.sort(entries, function(a: Entry, b: Entry): boolean
    return a.Id < b.Id
end)

local random = Random.new()
local VariantRng = {}

-- Relative integer weights: they need not add up to 100.
function VariantRng.Roll(): string
    local draw = random:NextInteger(1, totalWeight)
    for _, entry in entries do
        draw -= entry.Weight
        if draw <= 0 then
            return entry.Id
        end
    end
    error("Variant weight configuration is invalid")
end

return VariantRng
