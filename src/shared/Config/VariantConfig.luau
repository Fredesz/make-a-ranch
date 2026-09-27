--!strict

export type VariantDefinition = {
    DisplayName: string,
    Weight: number, -- Relative RNG weight, not a percentage.
    ValueMultiplier: number,
}

local VariantConfig: { [string]: VariantDefinition } = {
    Normal = {
        DisplayName = "Normal",
        Weight = 70,
        ValueMultiplier = 1,
    },
    Golden = {
        DisplayName = "Golden",
        Weight = 5,
        ValueMultiplier = 2,
    },
}

return VariantConfig
