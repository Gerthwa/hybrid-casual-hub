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
}

return GameConfig
