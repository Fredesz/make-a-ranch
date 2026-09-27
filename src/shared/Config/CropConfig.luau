--!strict

export type CropDefinition = {
    DisplayName: string,
    BuyPrice: number,
    SellPrice: number,
    GrowthTime: number, -- Seconds.
}

local CropConfig: { [string]: CropDefinition } = {
    Wheat = {
        DisplayName = "Wheat",
        BuyPrice = 10,
        SellPrice = 15,
        GrowthTime = 30,
    },
}

return CropConfig
