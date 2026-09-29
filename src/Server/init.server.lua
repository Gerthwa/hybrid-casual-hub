--!strict
--[[
	Server bootstrap: remotes → persistence → minigame loop.
]]

local Server = script.Parent

local RemotesService = require(Server.Services.RemotesService)
local DataService = require(Server.Services.DataService)
local MinigameManager = require(Server.Services.MinigameManager)

RemotesService:Init()
DataService:Init(RemotesService)
MinigameManager:Init(DataService, RemotesService)

print("[HybridCasualHub] Server initialized")
