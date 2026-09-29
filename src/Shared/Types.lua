--!strict
--[[
	Shared Luau types for the hybrid-casual minigame hub.
]]

export type PlayerData = {
	Coins: number,
	Gems: number,
	Rebirths: number,
}

export type MinigamePhase = "Lobby" | "Playing" | "Reward" | "Idle"

export type MinigameStatePayload = {
	phase: MinigamePhase,
	timeRemaining: number,
}

export type PlayerDataPayload = PlayerData

return nil
