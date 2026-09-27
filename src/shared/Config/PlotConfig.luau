--!strict

local PlotConfig = {
    Origin = Vector3.new(0, 0, 24),
    Spacing = 24,
    GroundSize = Vector3.new(20, 1, 20),
    GroundColor = Color3.fromRGB(100, 140, 70),
    SoilSize = Vector3.new(6, 0.5, 6),
    SoilColor = Color3.fromRGB(100, 65, 40),
    SellPadOffset = Vector3.new(7, 0, 0),
    SellPadSize = Vector3.new(3, 0.5, 3),
    SellPadColor = Color3.fromRGB(65, 130, 190),
    SellInteractionDistance = 12,
    SeedShopOffset = Vector3.new(-7, 0, 0),
    SeedShopSize = Vector3.new(3, 0.5, 3),
    SeedShopColor = Color3.fromRGB(235, 190, 55),
    BuildGridSize = 3,
}

return PlotConfig
