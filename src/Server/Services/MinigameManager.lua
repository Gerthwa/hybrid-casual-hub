--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Types = require(ReplicatedStorage.Shared.Types)

type DataService = require(script.Parent.DataService)
type RemotesService = require(script.Parent.RemotesService)
type MinigamePhase = Types.MinigamePhase

export type MinigameManager = {
	Init: (self: MinigameManager, dataService: DataService, remotesService: RemotesService) -> (),
}

local MinigameManager = {} :: MinigameManager
MinigameManager.__index = MinigameManager

type SessionState = {
	phase: MinigamePhase,
	taskToken: number,
}

local sessions: { [Player]: SessionState } = {}
local dataServiceRef: DataService? = nil
local remotesServiceRef: RemotesService? = nil
local nextSessionToken = 0

local function getHubSpawn(name: string): SpawnLocation?
	local hub = Workspace:FindFirstChild(GameConfig.World.HubModelName)
	if not hub then
		return nil
	end
	local spawn = hub:FindFirstChild(name)
	if spawn and spawn:IsA("SpawnLocation") then
		return spawn
	end
	return nil
end

local function teleportCharacterToSpawn(player: Player, spawnName: string)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local spawn = getHubSpawn(spawnName)
	if root and spawn then
		root.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
	end
end

local function fireMinigameState(player: Player, phase: MinigamePhase, timeRemaining: number)
	local remotes = remotesServiceRef
	if not remotes then
		return
	end
	remotes:GetMinigameStateChanged():FireClient(player, {
		phase = phase,
		timeRemaining = timeRemaining,
	})
end

local function cancelSession(player: Player)
	local session = sessions[player]
	if session then
		session.taskToken = -1
	end
	sessions[player] = nil
end

local function runMinigameLoop(player: Player, token: number)
	local config = GameConfig.Minigame
	local dataService = dataServiceRef
	local remotes = remotesServiceRef
	if not dataService or not remotes then
		return
	end

	local session = sessions[player]
	if not session or session.taskToken ~= token then
		return
	end

	session.phase = "Lobby"
	for remaining = config.LobbyCountdownSeconds, 1, -1 do
		if not sessions[player] or sessions[player].taskToken ~= token then
			return
		end
		fireMinigameState(player, "Lobby", remaining)
		task.wait(1)
	end

	if not sessions[player] or sessions[player].taskToken ~= token then
		return
	end

	teleportCharacterToSpawn(player, GameConfig.World.ArenaSpawnName)
	session.phase = "Playing"

	for remaining = config.DurationSeconds, 0, -1 do
		if not sessions[player] or sessions[player].taskToken ~= token then
			return
		end
		fireMinigameState(player, "Playing", remaining)
		if remaining == 0 then
			break
		end
		task.wait(1)
	end

	if not sessions[player] or sessions[player].taskToken ~= token then
		return
	end

	dataService:AddCoins(player, config.DefaultCoinReward)
	dataService:PushDataToClient(player, remotes)

	session.phase = "Reward"
	fireMinigameState(player, "Reward", 0)
	task.wait(2)

	teleportCharacterToSpawn(player, GameConfig.World.LobbySpawnName)
	sessions[player] = nil
	fireMinigameState(player, "Idle", 0)

	task.defer(function()
		if player.Parent == Players then
			MinigameManager:StartSession(player)
		end
	end)
end

function MinigameManager:StartSession(player: Player)
	cancelSession(player)
	nextSessionToken += 1
	local token = nextSessionToken
	sessions[player] = {
		phase = "Idle",
		taskToken = token,
	}
	task.spawn(runMinigameLoop, player, token)
end

function MinigameManager:Init(dataService: DataService, remotesService: RemotesService)
	dataServiceRef = dataService
	remotesServiceRef = remotesService

	local function hookPlayer(player: Player)
		dataService:OnProfileReady(player, function()
			teleportCharacterToSpawn(player, GameConfig.World.LobbySpawnName)
			self:StartSession(player)
		end)

		player.CharacterAdded:Connect(function()
			if sessions[player] then
				local phase = sessions[player].phase
				if phase == "Playing" then
					teleportCharacterToSpawn(player, GameConfig.World.ArenaSpawnName)
				else
					teleportCharacterToSpawn(player, GameConfig.World.LobbySpawnName)
				end
			end
		end)
	end

	Players.PlayerAdded:Connect(hookPlayer)
	Players.PlayerRemoving:Connect(cancelSession)

	for _, player in Players:GetPlayers() do
		hookPlayer(player)
	end
end

return MinigameManager
