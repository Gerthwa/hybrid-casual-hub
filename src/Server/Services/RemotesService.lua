--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

export type RemotesService = {
	Init: (self: RemotesService) -> (),
	GetFolder: (self: RemotesService) -> Folder,
	GetPlayerDataUpdated: (self: RemotesService) -> RemoteEvent,
	GetMinigameStateChanged: (self: RemotesService) -> RemoteEvent,
}

local RemotesService = {} :: RemotesService
RemotesService.__index = RemotesService

local folder: Folder? = nil
local playerDataUpdated: RemoteEvent? = nil
local minigameStateChanged: RemoteEvent? = nil

local function getOrCreateRemote(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
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
	playerDataUpdated = getOrCreateRemote(remotesFolder, Remotes.PlayerDataUpdated)
	minigameStateChanged = getOrCreateRemote(remotesFolder, Remotes.MinigameStateChanged)
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

return RemotesService
