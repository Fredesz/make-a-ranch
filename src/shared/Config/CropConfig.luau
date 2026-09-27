--!strict

export type CropDefinition = {
    DisplayName: string,
    BuyPrice: number,
    SellPrice: number,
    GrowthTime: number, -- Seconds.
    StartingSeeds: number, -- Temporary session allowance until the seed shop exists.
    InteractionDistance: number,
    StageSizes: { Vector3 },
    GrowingColor: Color3,
}

local CropConfig: { [string]: CropDefinition } = {
    Carrot = {
        DisplayName = "Carrot",
        BuyPrice = 10,
        SellPrice = 15,
        GrowthTime = 30,
        StartingSeeds = 10,
        InteractionDistance = 12,
        StageSizes = {
            Vector3.new(0.5, 0.5, 0.5),
            Vector3.new(0.8, 1, 0.8),
            Vector3.new(1, 1.5, 1),
        },
        GrowingColor = Color3.fromRGB(75, 170, 65),
    },
}

return CropConfig
