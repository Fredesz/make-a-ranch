--!strict

export type BuildingDefinition = {
    DisplayName: string,
    Price: number,
}

local BuildingConfig: { [string]: BuildingDefinition } = {
    Barn = {
        DisplayName = "Barn",
        Price = 500,
    },
}

return BuildingConfig
