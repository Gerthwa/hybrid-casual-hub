--!strict
--[[
	Shared Luau types for the hybrid-casual minigame hub.
]]

export type PlayerStats = {
	StartingArmy: number,
}

export type PlayerData = {
	Coins: number,
	Gems: number,
	Rebirths: number,
	TycoonUnlocked: { [string]: boolean },
	Stats: PlayerStats,
}

export type MinigamePhase = "Lobby" | "Playing" | "Reward" | "Idle"

export type MinigameStatePayload = {
	phase: MinigamePhase,
	timeRemaining: number,
}

export type PlayerDataPayload = PlayerData

export type TycoonProgressPayload = {
	unlocked: { [string]: boolean },
	coins: number,
	stats: PlayerStats,
}

export type TycoonStructureSpawnedPayload = {
	ownerUserId: number,
	nodeId: string,
	plotName: string,
}

export type SwarmAttackPayload = {
	armySize: number,
	damageDealt: number,
	survivingSoldiers: number,
	bossMaxHP: number,
	bossCurrentHP: number,
	coinsAwarded: number,
}

return nil
