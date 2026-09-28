--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CropConfig = require(ReplicatedStorage.Shared.Config.CropConfig)
local VariantConfig = require(ReplicatedStorage.Shared.Config.VariantConfig)
local PlotService = require(script.Parent.PlotService)
local VariantRng = require(script.Parent.VariantRng)
local InventoryService = require(script.Parent.InventoryService)
local PlayerDataService = require(script.Parent.Parent.PlayerDataService)

-- This phase supports exactly one crop, selected from its configuration.
local cropId, config = next(CropConfig)
assert(cropId ~= nil and config ~= nil, "CropConfig must contain one crop")
assert(next(CropConfig, cropId) == nil, "Phase 3 supports exactly one crop")

type SavedCrop = PlayerDataService.ActiveCrop
type Growth = { Visual: Part, ReadyAt: number, Variant: string }
type Session = {
    Slot: Part,
    Growth: Growth?,
    Prompt: ProximityPrompt,
    Connection: RBXScriptConnection?,
}

local sessions: { [Player]: Session } = {}
local fieldSessions: { [Player]: { [Part]: Session } } = {}
local initialized = false
local CropService = {}

local function slotId(slot: Part): string
    return if slot:GetAttribute("FieldSlot") then slot:GetAttribute("SlotId") else "Main"
end

local function getSession(player: Player, slot: Instance): Session?
    local main = sessions[player]
    if main and main.Slot == slot then return main end
    local fields = fieldSessions[player]
    return if fields then fields[slot :: Part] else nil
end

local function updatePrompt(player: Player, session: Session)
    local growth = session.Growth
    local ready = growth ~= nil and os.time() >= growth.ReadyAt
    local seeds = PlayerDataService.GetSeeds(player) or 0
    session.Slot:SetAttribute("CropState", if growth then (if ready then "Ready" else "Growing") else "Empty")
    session.Slot:SetAttribute("SeedsRemaining", seeds)
    session.Prompt.ActionText = if growth then "Harvest" else "Plant"
    session.Prompt.ObjectText = config.DisplayName .. " | Seeds: " .. seeds
    session.Prompt.Enabled = if growth then ready else seeds > 0
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
    if not sessions[player] then return nil end
    return PlayerDataService.GetSeeds(player)
end

function CropService.AddSeeds(player: Player, quantity: number): (boolean, string?)
    if not sessions[player] then return false, "DataNotFound" end
    local added, reason = PlayerDataService.AddSeeds(player, quantity)
    if not added then return false, reason end
    CropService.RefreshSeeds(player)
    return true, nil
end

function CropService.RefreshSeeds(player: Player)
    local session = sessions[player]
    if session then updatePrompt(player, session) end
    for _, fieldSession in fieldSessions[player] or {} do
        updatePrompt(player, fieldSession)
    end
end

function CropService.Plant(player: Player, slot: Instance): (boolean, string?)
    local session = getSession(player, slot)
    if not session or slot ~= session.Slot or not canInteract(player, session) then
        return false, "InvalidPlotOrDistance"
    end
    if not PlayerDataService.IsReady(player) then return false, "DataNotReady" end
    if session.Growth then
        return false, "Occupied"
    end
    if (PlayerDataService.GetSeeds(player) or 0) <= 0 then return false, "NoSeeds" end

    local consumed, reason = PlayerDataService.ConsumeSeed(player)
    if not consumed then return false, reason end
    local visual = Instance.new("Part")
    visual.Name = cropId
    visual.Anchored = true
    visual.CanCollide = false
    visual.Color = config.GrowingColor
    local growth: Growth = {
        Visual = visual,
        ReadyAt = os.time() + config.GrowthTime,
        Variant = VariantRng.Roll(),
    }
    assert(PlayerDataService.SetActiveCrop(player, {
        SlotId = slotId(session.Slot),
        CropId = cropId,
        ReadyAt = growth.ReadyAt,
        Variant = growth.Variant,
    }), "Active crop could not be recorded")
    for _, fieldSession in fieldSessions[player] or {} do
        updatePrompt(player, fieldSession)
    end
    if sessions[player] and sessions[player] ~= session then
        updatePrompt(player, sessions[player])
    end
    session.Growth = growth
    session.Slot:SetAttribute("CropId", cropId)
    visual.Parent = session.Slot
    CropService.ResumeGrowth(player, session, growth)
    return true, nil
end

function CropService.Harvest(player: Player, slot: Instance): (boolean, string?, string?)
    local session = getSession(player, slot)
    if not session or slot ~= session.Slot or not canInteract(player, session) then
        return false, "InvalidPlotOrDistance"
    end
    local growth = session.Growth
    if not growth then
        return false, "Empty"
    end
    -- Never trust replicated attributes or prompt state to determine readiness.
    if os.time() < growth.ReadyAt then
        return false, "NotReady"
    end

    local added, reason = InventoryService.AddCrop(player, cropId, growth.Variant, 1)
    if not added then
        return false, reason
    end
    assert(PlayerDataService.ClearActiveCrop(player, slotId(session.Slot)),
        "Harvested crop was not recorded")

    session.Growth = nil
    growth.Visual:Destroy()
    session.Slot:SetAttribute("CropId", nil)
    session.Slot:SetAttribute("GrowthStage", nil)
    session.Slot:SetAttribute("Variant", nil)
    updatePrompt(player, session)
    return true, cropId, growth.Variant
end

function CropService.ResumeGrowth(player: Player, session: Session, growth: Growth)
    local now = os.time()
    local plantedAt = growth.ReadyAt - config.GrowthTime
    local stage = math.clamp(math.floor((now - plantedAt) * #config.StageSizes
        / config.GrowthTime) + 1, 1, #config.StageSizes)
    setStage(session, growth, stage)
    if now >= growth.ReadyAt then
        session.Slot:SetAttribute("Variant", growth.Variant)
        growth.Visual.Color = VariantConfig[growth.Variant].ReadyColor
    end
    updatePrompt(player, session)

    -- Identity checks stop old timers from touching another crop or a released plot.
    for nextStage = stage + 1, #config.StageSizes do
        local stageAt = plantedAt + config.GrowthTime * (nextStage - 1)
            / #config.StageSizes
        task.delay(math.max(0, stageAt - now), function()
            if getSession(player, session.Slot) == session and session.Growth == growth
                and PlotService.OwnsSlot(player, session.Slot) then
                setStage(session, growth, nextStage)
            end
        end)
    end
    if now < growth.ReadyAt then
        task.delay(growth.ReadyAt - now, function()
            if getSession(player, session.Slot) == session and session.Growth == growth
                and PlotService.OwnsSlot(player, session.Slot) then
                session.Slot:SetAttribute("Variant", growth.Variant)
                growth.Visual.Color = VariantConfig[growth.Variant].ReadyColor
                updatePrompt(player, session)
            end
        end)
    end
end

local function createSlotSession(player: Player, slot: Part): Session
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CropInteraction"
    prompt.MaxActivationDistance = config.InteractionDistance
    prompt.RequiresLineOfSight = false
    local session: Session = {
        Slot = slot,
        Growth = nil,
        Prompt = prompt,
        Connection = nil,
    }
    session.Connection = prompt.Triggered:Connect(function(actor: Player)
        local ok: boolean
        local reason: string?
        local message: string
        if session.Growth then
            local harvested, harvestReason, variant = CropService.Harvest(actor, slot)
            ok = harvested
            reason = harvestReason
            message = if harvested then "Harvested " .. (variant or "") .. " Carrot!"
                else "Harvest failed"
        else
            ok, reason = CropService.Plant(actor, slot)
            message = if ok then "Carrot planted!" else "Planting failed"
        end
        local notice = ReplicatedStorage:FindFirstChild("HudNotice")
        if notice and notice:IsA("RemoteEvent") then
            notice:FireClient(actor, message, reason)
        end
    end)
    updatePrompt(player, session)
    prompt.Parent = slot
    return session
end

local function createSession(player: Player)
    if sessions[player] then return end
    local slot = PlotService.GetSlot(player)
    if not slot then return end
    sessions[player] = createSlotSession(player, slot)
end

function CropService.EnsureSession(player: Player)
    createSession(player)
end

function CropService.Restore(player: Player, saved: { SavedCrop })
    for _, entry in saved do
        if entry.CropId ~= cropId then continue end
        local session = if entry.SlotId == "Main" then sessions[player] else nil
        if not session then
            for _, field in fieldSessions[player] or {} do
                if slotId(field.Slot) == entry.SlotId then
                    session = field
                    break
                end
            end
        end
        if not session or session.Growth then continue end
        local visual = Instance.new("Part")
        visual.Name = cropId
        visual.Anchored = true
        visual.CanCollide = false
        visual.Color = config.GrowingColor
        visual.Parent = session.Slot
        local growth: Growth = {
            Visual = visual,
            ReadyAt = entry.ReadyAt,
            Variant = entry.Variant,
        }
        session.Growth = growth
        session.Slot:SetAttribute("CropId", cropId)
        CropService.ResumeGrowth(player, session, growth)
    end
end

function CropService.RegisterFieldSlot(player: Player, slot: Part): boolean
    local main = sessions[player]
    if not main or not PlotService.OwnsSlot(player, slot) then return false end
    local fields = fieldSessions[player]
    if not fields then
        fields = {}
        fieldSessions[player] = fields
    end
    if fields[slot] then return false end
    fields[slot] = createSlotSession(player, slot)
    return true
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
        local fields = fieldSessions[player]
        fieldSessions[player] = nil
        if fields then
            for _, fieldSession in fields do
                if fieldSession.Connection then fieldSession.Connection:Disconnect() end
                if fieldSession.Growth then fieldSession.Growth.Visual:Destroy() end
                fieldSession.Prompt:Destroy()
            end
        end
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
