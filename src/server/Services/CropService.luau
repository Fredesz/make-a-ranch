--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CropConfig = require(ReplicatedStorage.Shared.Config.CropConfig)
local VariantConfig = require(ReplicatedStorage.Shared.Config.VariantConfig)
local PlotService = require(script.Parent.PlotService)
local VariantRng = require(script.Parent.VariantRng)

-- This phase supports exactly one crop, selected from its configuration.
local cropId, config = next(CropConfig)
assert(cropId ~= nil and config ~= nil, "CropConfig must contain one crop")
assert(next(CropConfig, cropId) == nil, "Phase 3 supports exactly one crop")

type Growth = { Visual: Part, StartedAt: number, Variant: string? }
type Session = {
    Slot: Part,
    Seeds: number,
    Growth: Growth?,
    Prompt: ProximityPrompt,
    Connection: RBXScriptConnection?,
}

local sessions: { [Player]: Session } = {}
local initialized = false
local CropService = {}

local function updatePrompt(session: Session)
    local growth = session.Growth
    local ready = growth ~= nil and os.clock() - growth.StartedAt >= config.GrowthTime
    session.Slot:SetAttribute("CropState", if growth then (if ready then "Ready" else "Growing") else "Empty")
    session.Slot:SetAttribute("SeedsRemaining", session.Seeds)
    session.Prompt.ActionText = if growth then "Harvest" else "Plant"
    session.Prompt.ObjectText = config.DisplayName .. " | Seeds: " .. session.Seeds
    session.Prompt.Enabled = if growth then ready else session.Seeds > 0
end

local function canInteract(player: Player, session: Session): boolean
    if not PlotService.OwnsSlot(player, session.Slot) then
        return false
    end
    local character = player.Character
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    return root ~= nil and root:IsA("BasePart")
        and humanoid ~= nil and humanoid.Health > 0
        and (root.Position - session.Slot.Position).Magnitude <= config.InteractionDistance
end

local function setStage(session: Session, growth: Growth, stage: number)
    growth.Visual.Size = config.StageSizes[stage]
    growth.Visual.Position = session.Slot.Position
        + Vector3.new(0, (session.Slot.Size.Y + growth.Visual.Size.Y) / 2, 0)
    session.Slot:SetAttribute("GrowthStage", stage)
end

function CropService.GetSeeds(player: Player): number?
    local session = sessions[player]
    return if session then session.Seeds else nil
end

function CropService.Plant(player: Player, slot: Instance): (boolean, string?)
    local session = sessions[player]
    if not session or slot ~= session.Slot or not canInteract(player, session) then
        return false, "InvalidPlotOrDistance"
    end
    if session.Growth then
        return false, "Occupied"
    end
    if session.Seeds <= 0 then
        return false, "NoSeeds"
    end

    local visual = Instance.new("Part")
    visual.Name = cropId
    visual.Anchored = true
    visual.CanCollide = false
    visual.Color = config.GrowingColor
    local growth: Growth = { Visual = visual, StartedAt = os.clock(), Variant = nil }
    session.Seeds -= 1
    session.Growth = growth
    session.Slot:SetAttribute("CropId", cropId)
    setStage(session, growth, 1)
    visual.Parent = session.Slot
    updatePrompt(session)

    -- Identity checks stop old timers from touching another crop or a released plot.
    for stage = 2, #config.StageSizes do
        task.delay(config.GrowthTime * (stage - 1) / #config.StageSizes, function()
            if sessions[player] == session and session.Growth == growth
                and PlotService.OwnsSlot(player, session.Slot) then
                setStage(session, growth, stage)
            end
        end)
    end
    task.delay(config.GrowthTime, function()
        if sessions[player] == session and session.Growth == growth
            and PlotService.OwnsSlot(player, session.Slot) then
            local variantId = VariantRng.Roll()
            growth.Variant = variantId
            session.Slot:SetAttribute("Variant", variantId)
            visual.Color = VariantConfig[variantId].ReadyColor
            updatePrompt(session)
        end
    end)
    return true, nil
end

function CropService.Harvest(player: Player, slot: Instance): (boolean, string?, string?)
    local session = sessions[player]
    if not session or slot ~= session.Slot or not canInteract(player, session) then
        return false, "InvalidPlotOrDistance"
    end
    local growth = session.Growth
    if not growth then
        return false, "Empty"
    end
    -- Never trust replicated attributes or prompt state to determine readiness.
    if os.clock() - growth.StartedAt < config.GrowthTime or growth.Variant == nil then
        return false, "NotReady"
    end

    session.Growth = nil
    growth.Visual:Destroy()
    session.Slot:SetAttribute("CropId", nil)
    session.Slot:SetAttribute("GrowthStage", nil)
    session.Slot:SetAttribute("Variant", nil)
    updatePrompt(session)
    return true, cropId, growth.Variant
end

local function createSession(player: Player)
    if sessions[player] then return end
    local slot = PlotService.GetSlot(player)
    if not slot then return end
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CropInteraction"
    prompt.MaxActivationDistance = config.InteractionDistance
    prompt.RequiresLineOfSight = false
    local session: Session = {
        Slot = slot,
        Seeds = config.StartingSeeds,
        Growth = nil,
        Prompt = prompt,
        Connection = nil,
    }
    sessions[player] = session
    session.Connection = prompt.Triggered:Connect(function(actor: Player)
        if session.Growth then
            CropService.Harvest(actor, slot)
        else
            CropService.Plant(actor, slot)
        end
    end)
    updatePrompt(session)
    prompt.Parent = slot
end

function CropService.Init()
    if initialized then return end
    initialized = true
    PlotService.Init()
    Players.PlayerAdded:Connect(function(player: Player)
        -- Let PlotService finish its PlayerAdded callback first.
        task.defer(function()
            if player.Parent == Players then createSession(player) end
        end)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        local session = sessions[player]
        if session then
            sessions[player] = nil
            if session.Connection then session.Connection:Disconnect() end
            if session.Growth then session.Growth.Visual:Destroy() end
            session.Prompt:Destroy()
        end
    end)
    for _, player in Players:GetPlayers() do createSession(player) end
end

return CropService
