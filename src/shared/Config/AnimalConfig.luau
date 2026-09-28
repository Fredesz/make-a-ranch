--!strict

export type AnimalDefinition = {
    DisplayName: string,
    BuyPrice: number,
    ProductionTime: number,
    ProductId: string,
    Color: Color3,
    EggColor: Color3,
}

local AnimalConfig: { [string]: AnimalDefinition } = {
    Chicken = {
        DisplayName = "Chicken",
        BuyPrice = 100,
        ProductionTime = 20,
        ProductId = "Egg",
        Color = Color3.fromRGB(250, 225, 120),
        EggColor = Color3.fromRGB(245, 245, 225),
    },
}

return AnimalConfig
