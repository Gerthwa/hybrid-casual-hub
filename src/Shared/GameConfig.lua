--!strict
--[[
	Global tuning values for the hub loop. Extend as tycoon / pets / rebirth systems land.
]]

local GameConfig = {
	DataStore = {
		ProfileKeyPrefix = "Player_",
		StoreName = "HybridCasualHub_v1",
	},

	Minigame = {
		LobbyCountdownSeconds = 3,
		DurationSeconds = 30,
		DefaultCoinReward = 50,
	},

	World = {
		LobbySpawnName = "LobbySpawn",
		ArenaSpawnName = "ArenaSpawn",
		HubModelName = "Hub",
	},

	BossCombat = {
		DefaultBossMaxHP = 5000,
		CoinsPerDamage = 2,
		FinishLineTag = "MultiplierRunnerFinish",
		BossModelName = "SwarmBoss",
		BossHitboxName = "Hitbox",
		RunnerArmyAttribute = "RunnerArmySize",
	},

	SwarmVisuals = {
		MaxAnimatedSoldiers = 180,
		SoldiersPerFrame = 10,
		TweenDurationSeconds = 0.35,
		HitStaggerSeconds = 0.02,
	},
}

return GameConfig
