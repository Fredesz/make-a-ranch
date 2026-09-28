--!strict

local PlayerDataService = require(script.PlayerDataService)
local PlotService = require(script.Services.PlotService)
local CropService = require(script.Services.CropService)
local SellService = require(script.Services.SellService)
local SeedShopService = require(script.Services.SeedShopService)
local BuildService = require(script.Services.BuildService)
local DataService = require(script.Services.DataService)
local HudService = require(script.Services.HudService)

PlayerDataService.Init()
PlotService.Init()
CropService.Init()
SellService.Init()
SeedShopService.Init()
BuildService.Init()
DataService.Init()
HudService.Init()

print("Make a Ranch | Server iniciado")
