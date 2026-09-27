--!strict

local PlayerDataService = require(script.PlayerDataService)
local PlotService = require(script.Services.PlotService)
local CropService = require(script.Services.CropService)
local SellService = require(script.Services.SellService)

PlayerDataService.Init()
PlotService.Init()
CropService.Init()
SellService.Init()

print("Make a Ranch | Server iniciado")
