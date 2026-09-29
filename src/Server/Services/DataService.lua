--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local Types = require(ReplicatedStorage.Shared.Types)

type RemotesService = require(script.Parent.RemotesService)
type PlayerData = Types.PlayerData
type PlayerStats = Types.PlayerStats

local ProfileService = require(ServerStorage.ServerPackages.ProfileService)

export type DataService = {
	Init: (self: DataService, remotesService: RemotesService) -> (),
	GetData: (self: DataService, player: Player) -> PlayerData?,
	AddCoins: (self: DataService, player: Player, amount: number) -> boolean,
	TrySpendCoins: (self: DataService, player: Player, amount: number) -> boolean,
	IsTycoonUnlocked: (self: DataService, player: Player, nodeId: string) -> boolean,
	UnlockTycoonNode: (self: DataService, player: Player, nodeId: string) -> boolean,
	GetStats: (self: DataService, player: Player) -> PlayerStats,
	OnProfileReady: (self: DataService, player: Player, callback: (data: PlayerData) -> ()) -> (),
	PushDataToClient: (self: DataService, player: Player, remotesService: RemotesService) -> (),
}

local DataService = {} :: DataService
DataService.__index = DataService

type Profile = any

local DEFAULT_STATS: PlayerStats = {
	StartingArmy = 0,
}

local profileTemplate = {
	Coins = 0,
	Gems = 0,
	Rebirths = 0,
	TycoonUnlocked = {},
	Stats = {
		StartingArmy = 0,
	},
}

local profileStore = ProfileService.GetProfileStore(GameConfig.DataStore.StoreName, profileTemplate)

local profiles: { [Player]: Profile } = {}
local readyCallbacks: { [Player]: { (data: PlayerData) -> () } } = {}

local function normalizeUnlocked(raw: any): { [string]: boolean }
	local unlocked: { [string]: boolean } = {}
	if typeof(raw) == "table" then
		for key, value in raw do
			if value == true then
				unlocked[tostring(key)] = true
			end
		end
	end
	return unlocked
end

local function normalizeStats(raw: any): PlayerStats
	if typeof(raw) ~= "table" then
		return table.clone(DEFAULT_STATS)
	end
	return {
		StartingArmy = if typeof(raw.StartingArmy) == "number" then raw.StartingArmy else 0,
	}
end

local function snapshotFromProfile(profile: Profile): PlayerData
	local data = profile.Data
	return {
		Coins = data.Coins,
		Gems = data.Gems,
		Rebirths = data.Rebirths,
		TycoonUnlocked = normalizeUnlocked(data.TycoonUnlocked),
		Stats = normalizeStats(data.Stats),
	}
end

local function applyBuffToProfile(profile: Profile, buff: { Stat: string, Value: number })
	local stats = profile.Data.Stats
	if typeof(stats) ~= "table" then
		profile.Data.Stats = table.clone(DEFAULT_STATS)
		stats = profile.Data.Stats
	end
	if buff.Stat == "StartingArmy" then
		stats.StartingArmy = (stats.StartingArmy or 0) + buff.Value
	end
end

local function syncStatAttributes(player: Player, stats: PlayerStats)
	player:SetAttribute("Stat_StartingArmy", stats.StartingArmy)
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
		syncStatAttributes(player, snapshot.Stats)
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

function DataService:TrySpendCoins(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or amount <= 0 then
		return false
	end
	if profile.Data.Coins < amount then
		return false
	end
	profile.Data.Coins -= amount
	return true
end

function DataService:IsTycoonUnlocked(player: Player, nodeId: string): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local unlocked = normalizeUnlocked(profile.Data.TycoonUnlocked)
	return unlocked[nodeId] == true
end

function DataService:UnlockTycoonNode(player: Player, nodeId: string): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end

	if typeof(profile.Data.TycoonUnlocked) ~= "table" then
		profile.Data.TycoonUnlocked = {}
	end

	local node = TycoonConfig.getNode(nodeId)
	if not node then
		return false
	end

	profile.Data.TycoonUnlocked[nodeId] = true
	if node.Buff then
		applyBuffToProfile(profile, node.Buff)
		syncStatAttributes(player, normalizeStats(profile.Data.Stats))
	end

	return true
end

function DataService:GetStats(player: Player): PlayerStats
	local data = self:GetData(player)
	if not data then
		return table.clone(DEFAULT_STATS)
	end
	return data.Stats
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
