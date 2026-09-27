--!strict

export type VariantDefinition = {
    DisplayName: string,
    Weight: number, -- Relative RNG weight, not a percentage.
    ValueMultiplier: number,
    ReadyColor: Color3,
}

local VariantConfig: { [string]: VariantDefinition } = {
    Normal = {
        DisplayName = "Normal",
        Weight = 94,
        ValueMultiplier = 1,
        ReadyColor = Color3.fromRGB(245, 140, 35),
    },
    Golden = {
        DisplayName = "Golden",
        Weight = 5,
        ValueMultiplier = 2,
        ReadyColor = Color3.fromRGB(255, 215, 40),
    },
    Rainbow = {
        DisplayName = "Rainbow",
        Weight = 1,
        ValueMultiplier = 5,
        ReadyColor = Color3.fromRGB(185, 80, 245),
    },
}

return VariantConfig
