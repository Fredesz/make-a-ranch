--!strict

export type BuildingDefinition = {
    DisplayName: string,
    Price: number,
    Footprint: Vector2,
    Height: number,
    Color: Color3,
}

local BuildingConfig: { [string]: BuildingDefinition } = {
    Barn = {
        DisplayName = "Barn",
        Price = 80,
        Footprint = Vector2.new(6, 4),
        Height = 4,
        Color = Color3.fromRGB(150, 90, 55),
    },
}

return BuildingConfig
