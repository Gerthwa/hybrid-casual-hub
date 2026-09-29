--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent.Parent.UI.Hud)
local Types = require(ReplicatedStorage.Shared.Types)

type PlayerDataPayload = Types.PlayerDataPayload
type MinigameStatePayload = Types.MinigameStatePayload

export type GameController = {
	Init: (self: GameController) -> (),
}

local GameController = {} :: GameController
GameController.__index = GameController

local PHASE_LABELS: { [Types.MinigamePhase]: string } = {
	Lobby = "Lobby",
	Playing = "Minigame",
	Reward = "Reward",
	Idle = "Hub",
}

function GameController:Init()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local playerDataUpdated = remotesFolder:WaitForChild("PlayerDataUpdated") :: RemoteEvent
	local minigameStateChanged = remotesFolder:WaitForChild("MinigameStateChanged") :: RemoteEvent

	local hud = Hud.new()

	playerDataUpdated.OnClientEvent:Connect(function(payload: PlayerDataPayload)
		hud:SetCoins(payload.Coins)
	end)

	minigameStateChanged.OnClientEvent:Connect(function(payload: MinigameStatePayload)
		local label = PHASE_LABELS[payload.phase] or payload.phase
		if payload.phase == "Reward" then
			hud:SetTimer("Round complete! +coins", 0)
		elseif payload.phase == "Idle" then
			hud:SetTimer("Next round soon...", 0)
		else
			hud:SetTimer(label, payload.timeRemaining)
		end
	end)
end

return GameController
