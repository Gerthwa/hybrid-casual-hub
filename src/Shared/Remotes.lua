--!strict
--[[
	Remote names live in one place so server and client stay in sync.
	Instances are created at runtime by RemotesService (server).
]]

local Remotes = {
	FolderName = "Remotes",
	PlayerDataUpdated = "PlayerDataUpdated",
	MinigameStateChanged = "MinigameStateChanged",
}

return Remotes
