--!strict
--[[
	Authoritative tycoon purchases — costs, dependencies, and currency live on the server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Server = script.Parent
local DataService = require(Server.Services.DataService)
local RemotesService = require(Server.Services.RemotesService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local Types = require(ReplicatedStorage.Shared.Types)

type TycoonProgressPayload = Types.TycoonProgressPayload
type TycoonStructureSpawnedPayload = Types.TycoonStructureSpawnedPayload

local PLOTS_FOLDER_NAME = "TycoonPlots"
local PLOT_ORIGIN_NAME = "Origin"
local STRUCTURES_FOLDER_NAME = "Structures"

local plotByPlayer: { [Player]: Model } = {}
local plotAssignments: { [string]: Player } = {}

local function waitForTycoonRemotes()
	local folder = ReplicatedStorage:WaitForChild(Remotes.FolderName)
	folder:WaitForChild(Remotes.TycoonRequestPurchase)
	folder:WaitForChild(Remotes.TycoonProgressUpdated)
	folder:WaitForChild(Remotes.TycoonStructureSpawned)
end

local function getPlotsFolder(): Folder?
	local hub = Workspace:FindFirstChild("Hub")
	if not hub then
		return nil
	end
	local plots = hub:FindFirstChild(PLOTS_FOLDER_NAME)
	if plots and plots:IsA("Folder") then
		return plots
	end
	return nil
end

local function getPrefabsFolder(): Folder?
	local prefabs = ReplicatedStorage:FindFirstChild("TycoonPrefabs")
	if prefabs and prefabs:IsA("Folder") then
		return prefabs
	end
	return nil
end

local function assignPlot(player: Player): Model?
	local existing = plotByPlayer[player]
	if existing then
		return existing
	end

	local plotsFolder = getPlotsFolder()
	if not plotsFolder then
		warn("[TycoonService] Missing Workspace.Hub.TycoonPlots")
		return nil
	end

	for _, plot in plotsFolder:GetChildren() do
		if plot:IsA("Model") and plotAssignments[plot.Name] == nil then
			plotAssignments[plot.Name] = player
			plotByPlayer[player] = plot
			plot:SetAttribute("OwnerUserId", player.UserId)

			local structures = plot:FindFirstChild(STRUCTURES_FOLDER_NAME)
			if not structures then
				structures = Instance.new("Folder")
				structures.Name = STRUCTURES_FOLDER_NAME
				structures.Parent = plot
			end

			return plot
		end
	end

	return nil
end

local function getPlotOrigin(plot: Model): CFrame
	local origin = plot:FindFirstChild(PLOT_ORIGIN_NAME)
	if origin and origin:IsA("BasePart") then
		return origin.CFrame
	end
	return plot:GetPivot()
end

local function buildProgressPayload(player: Player): TycoonProgressPayload?
	local data = DataService:GetData(player)
	if not data then
		return nil
	end
	return {
		unlocked = data.TycoonUnlocked,
		coins = data.Coins,
		stats = data.Stats,
	}
end

local function pushProgress(player: Player)
	local payload = buildProgressPayload(player)
	if not payload then
		return
	end
	RemotesService:GetTycoonProgressUpdated():FireClient(player, payload)
	DataService:PushDataToClient(player, RemotesService)
end

local function spawnStructure(player: Player, nodeId: string): Model?
	local plot = assignPlot(player)
	if not plot then
		return nil
	end

	local node = TycoonConfig.getNode(nodeId)
	if not node then
		return nil
	end

	local prefabs = getPrefabsFolder()
	if not prefabs then
		warn("[TycoonService] Missing ReplicatedStorage.TycoonPrefabs")
		return nil
	end

	local template = prefabs:FindFirstChild(node.PrefabName)
	if not template or not template:IsA("Model") then
		warn("[TycoonService] Missing prefab:", node.PrefabName)
		return nil
	end

	local structures = plot:FindFirstChild(STRUCTURES_FOLDER_NAME) :: Folder
	local clone = template:Clone()
	if not clone.PrimaryPart then
		local base = clone:FindFirstChild("Base")
		if base and base:IsA("BasePart") then
			clone.PrimaryPart = base
		end
	end
	clone.Name = node.ID
	clone:SetAttribute("TycoonNodeId", node.ID)
	clone:SetAttribute("OwnerUserId", player.UserId)
	clone:PivotTo(getPlotOrigin(plot) * node.PlotOffset)
	clone.Parent = structures

	return clone
end

local function handlePurchase(player: Player, nodeId: any): (boolean, string?)
	if typeof(nodeId) ~= "string" then
		return false, "InvalidNode"
	end

	local data = DataService:GetData(player)
	if not data then
		return false, "NoData"
	end

	local canBuy, reason = TycoonConfig.canPurchase(nodeId, data.TycoonUnlocked, data.Coins)
	if not canBuy then
		return false, reason
	end

	local node = TycoonConfig.getNode(nodeId)
	if not node then
		return false, "InvalidNode"
	end

	if not DataService:TrySpendCoins(player, node.Cost) then
		return false, "InsufficientCoins"
	end

	if not DataService:UnlockTycoonNode(player, nodeId) then
		return false, "UnlockFailed"
	end

	local plot = assignPlot(player)
	if not plot then
		return false, "NoPlot"
	end

	spawnStructure(player, nodeId)

	local spawnPayload: TycoonStructureSpawnedPayload = {
		ownerUserId = player.UserId,
		nodeId = nodeId,
		plotName = plot.Name,
	}
	RemotesService:GetTycoonStructureSpawned():FireAllClients(spawnPayload)
	pushProgress(player)

	return true, nil
end

local function restoreStructures(player: Player)
	local data = DataService:GetData(player)
	if not data then
		return
	end
	for nodeId, isUnlocked in data.TycoonUnlocked do
		if isUnlocked then
			spawnStructure(player, nodeId)
		end
	end
end

waitForTycoonRemotes()

RemotesService:GetTycoonRequestPurchase().OnServerInvoke = function(player: Player, nodeId: string)
	return handlePurchase(player, nodeId)
end

Players.PlayerAdded:Connect(function(player: Player)
	DataService:OnProfileReady(player, function()
		assignPlot(player)
		restoreStructures(player)
		pushProgress(player)
	end)
end)

for _, player in Players:GetPlayers() do
	DataService:OnProfileReady(player, function()
		assignPlot(player)
		restoreStructures(player)
		pushProgress(player)
	end)
end

Players.PlayerRemoving:Connect(function(player: Player)
	local plot = plotByPlayer[player]
	if plot then
		plotAssignments[plot.Name] = nil
		plot:SetAttribute("OwnerUserId", nil)
	end
	plotByPlayer[player] = nil
end)

print("[HybridCasualHub] TycoonService ready")
