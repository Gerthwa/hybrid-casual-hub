--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Types = require(ReplicatedStorage.Shared.Types)

type RemotesService = require(script.Parent.RemotesService)
type PlayerData = Types.PlayerData

local ProfileService = require(ServerStorage.ServerPackages.ProfileService)

export type DataService = {
	Init: (self: DataService, remotesService: RemotesService) -> (),
	GetData: (self: DataService, player: Player) -> PlayerData?,
	AddCoins: (self: DataService, player: Player, amount: number) -> boolean,
	OnProfileReady: (self: DataService, player: Player, callback: (data: PlayerData) -> ()) -> (),
}

local DataService = {} :: DataService
DataService.__index = DataService

type Profile = any

local profileStore = ProfileService.GetProfileStore(GameConfig.DataStore.StoreName, {
	Coins = 0,
	Gems = 0,
	Rebirths = 0,
})

local profiles: { [Player]: Profile } = {}
local readyCallbacks: { [Player]: { (data: PlayerData) -> () } } = {}

local function snapshotFromProfile(profile: Profile): PlayerData
	local data = profile.Data
	return {
		Coins = data.Coins,
		Gems = data.Gems,
		Rebirths = data.Rebirths,
	}
end

function DataService:Init(remotesService: RemotesService)
	local playerDataRemote = remotesService:GetPlayerDataUpdated()

	local function onPlayerAdded(player: Player)
		local profileKey = GameConfig.DataStore.ProfileKeyPrefix .. player.UserId
		local profile = profileStore:LoadProfileAsync(profileKey)

		if profile == nil then
			player:Kick("Could not load data. Please rejoin.")
			return
		end

		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			profiles[player] = nil
			if player.Parent then
				player:Kick("Profile released — please rejoin.")
			end
		end)

		if player.Parent ~= Players then
			profile:Release()
			return
		end

		profiles[player] = profile
		local snapshot = snapshotFromProfile(profile)
		playerDataRemote:FireClient(player, snapshot)

		local callbacks = readyCallbacks[player]
		if callbacks then
			for _, callback in callbacks do
				task.spawn(callback, snapshot)
			end
			readyCallbacks[player] = nil
		end
	end

	local function onPlayerRemoving(player: Player)
		local profile = profiles[player]
		profiles[player] = nil
		readyCallbacks[player] = nil
		if profile then
			profile:Release()
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

function DataService:GetData(player: Player): PlayerData?
	local profile = profiles[player]
	if not profile then
		return nil
	end
	return snapshotFromProfile(profile)
end

function DataService:AddCoins(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or amount <= 0 then
		return false
	end

	profile.Data.Coins += amount
	return true
end

function DataService:OnProfileReady(player: Player, callback: (data: PlayerData) -> ())
	if profiles[player] then
		callback(snapshotFromProfile(profiles[player]))
		return
	end

	local list = readyCallbacks[player]
	if not list then
		list = {}
		readyCallbacks[player] = list
	end
	table.insert(list, callback)
end

function DataService:PushDataToClient(player: Player, remotesService: RemotesService)
	local data = self:GetData(player)
	if not data then
		return
	end
	remotesService:GetPlayerDataUpdated():FireClient(player, data)
end

return DataService
