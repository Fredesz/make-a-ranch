--!strict

export type ProductDefinition = {
    DisplayName: string,
    SellPrice: number,
}

local ProductConfig: { [string]: ProductDefinition } = {
    Egg = {
        DisplayName = "Egg",
        SellPrice = 75,
    },
}

return ProductConfig
