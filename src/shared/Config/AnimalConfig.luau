--!strict

export type AnimalDefinition = {
    DisplayName: string,
    BuyPrice: number,
    SellPrice: number,
}

local AnimalConfig: { [string]: AnimalDefinition } = {
    Chicken = {
        DisplayName = "Chicken",
        BuyPrice = 100,
        SellPrice = 75,
    },
}

return AnimalConfig
