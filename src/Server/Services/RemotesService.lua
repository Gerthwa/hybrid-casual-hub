--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

export type RemotesService = {
	Init: (self: RemotesService) -> (),
	GetFolder: (self: RemotesService) -> Folder,
	GetPlayerDataUpdated: (self: RemotesService) -> RemoteEvent,
	GetMinigameStateChanged: (self: RemotesService) -> RemoteEvent,
	GetPlaySwarmAnimation: (self: RemotesService) -> RemoteEvent,
	GetTycoonRequestPurchase: (self: RemotesService) -> RemoteFunction,
	GetTycoonProgressUpdated: (self: RemotesService) -> RemoteEvent,
	GetTycoonStructureSpawned: (self: RemotesService) -> RemoteEvent,
}

local RemotesService = {} :: RemotesService
RemotesService.__index = RemotesService

local folder: Folder? = nil
local playerDataUpdated: RemoteEvent? = nil
local minigameStateChanged: RemoteEvent? = nil
local playSwarmAnimation: RemoteEvent? = nil
local tycoonRequestPurchase: RemoteFunction? = nil
local tycoonProgressUpdated: RemoteEvent? = nil
local tycoonStructureSpawned: RemoteEvent? = nil

local function getOrCreateRemoteEvent(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local function getOrCreateRemoteFunction(parent: Instance, name: string): RemoteFunction
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteFunction") then
		return existing
	end

	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = parent
	return remote
end

function RemotesService:Init()
	local remotesFolder = ReplicatedStorage:FindFirstChild(Remotes.FolderName)
	if not remotesFolder or not remotesFolder:IsA("Folder") then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = Remotes.FolderName
		remotesFolder.Parent = ReplicatedStorage
	end

	folder = remotesFolder
	playerDataUpdated = getOrCreateRemoteEvent(remotesFolder, Remotes.PlayerDataUpdated)
	minigameStateChanged = getOrCreateRemoteEvent(remotesFolder, Remotes.MinigameStateChanged)
	playSwarmAnimation = getOrCreateRemoteEvent(remotesFolder, Remotes.PlaySwarmAnimation)
	tycoonRequestPurchase = getOrCreateRemoteFunction(remotesFolder, Remotes.TycoonRequestPurchase)
	tycoonProgressUpdated = getOrCreateRemoteEvent(remotesFolder, Remotes.TycoonProgressUpdated)
	tycoonStructureSpawned = getOrCreateRemoteEvent(remotesFolder, Remotes.TycoonStructureSpawned)
end

function RemotesService:GetFolder(): Folder
	assert(folder, "RemotesService not initialized")
	return folder
end

function RemotesService:GetPlayerDataUpdated(): RemoteEvent
	assert(playerDataUpdated, "RemotesService not initialized")
	return playerDataUpdated
end

function RemotesService:GetMinigameStateChanged(): RemoteEvent
	assert(minigameStateChanged, "RemotesService not initialized")
	return minigameStateChanged
end

function RemotesService:GetPlaySwarmAnimation(): RemoteEvent
	assert(playSwarmAnimation, "RemotesService not initialized")
	return playSwarmAnimation
end

function RemotesService:GetTycoonRequestPurchase(): RemoteFunction
	assert(tycoonRequestPurchase, "RemotesService not initialized")
	return tycoonRequestPurchase
end

function RemotesService:GetTycoonProgressUpdated(): RemoteEvent
	assert(tycoonProgressUpdated, "RemotesService not initialized")
	return tycoonProgressUpdated
end

function RemotesService:GetTycoonStructureSpawned(): RemoteEvent
	assert(tycoonStructureSpawned, "RemotesService not initialized")
	return tycoonStructureSpawned
end

return RemotesService
