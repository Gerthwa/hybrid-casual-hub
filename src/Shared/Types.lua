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

export type SwarmAttackPayload = {
	armySize: number,
	damageDealt: number,
	survivingSoldiers: number,
	bossMaxHP: number,
	bossCurrentHP: number,
	coinsAwarded: number,
}

return nil
