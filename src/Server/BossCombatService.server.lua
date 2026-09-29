--!strict
--[[
	Boss Fight Phase — Swarm Attack (server-authoritative math only).
	Only the finish-line part uses .Touched (one collider), never per-soldier physics.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent
local DataService = require(Server.Services.DataService)
local RemotesService = require(Server.Services.RemotesService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Types = require(ReplicatedStorage.Shared.Types)

type SwarmAttackPayload = Types.SwarmAttackPayload

local bossHPByPlayer: { [Player]: number } = {}
local finishDebounce: { [Player]: boolean } = {}

local function getPlaySwarmRemote(): RemoteEvent
	local folder = ReplicatedStorage:WaitForChild(Remotes.FolderName)
	return folder:WaitForChild(Remotes.PlaySwarmAnimation) :: RemoteEvent
end

local function getArmySize(player: Player): number
	local army = player:GetAttribute(GameConfig.BossCombat.RunnerArmyAttribute)
	if typeof(army) == "number" and army > 0 then
		return math.floor(army)
	end
	return 100
end

local function getBossHP(player: Player): (number, number)
	local maxHP = GameConfig.BossCombat.DefaultBossMaxHP
	local current = bossHPByPlayer[player]
	if current == nil then
		current = maxHP
		bossHPByPlayer[player] = current
	end
	return current, maxHP
end

local function triggerSwarmAttack(player: Player)
	if finishDebounce[player] then
		return
	end
	finishDebounce[player] = true
	task.delay(2, function()
		finishDebounce[player] = nil
	end)

	local armySize = getArmySize(player)
	local bossHP, bossMaxHP = getBossHP(player)

	local damageDealt = math.min(armySize, bossHP)
	local survivingSoldiers = armySize - damageDealt
	local newBossHP = bossHP - damageDealt
	bossHPByPlayer[player] = newBossHP

	local coinsAwarded = damageDealt * GameConfig.BossCombat.CoinsPerDamage
	if coinsAwarded > 0 then
		DataService:AddCoins(player, coinsAwarded)
		DataService:PushDataToClient(player, RemotesService)
	end

	local payload: SwarmAttackPayload = {
		armySize = armySize,
		damageDealt = damageDealt,
		survivingSoldiers = survivingSoldiers,
		bossMaxHP = bossMaxHP,
		bossCurrentHP = newBossHP,
		coinsAwarded = coinsAwarded,
	}

	getPlaySwarmRemote():FireClient(player, payload)

	if newBossHP <= 0 then
		task.delay(3, function()
			bossHPByPlayer[player] = bossMaxHP
		end)
	end
end

local function bindFinishPart(part: BasePart)
	if part:GetAttribute("SwarmFinishBound") then
		return
	end
	part:SetAttribute("SwarmFinishBound", true)

	part.Touched:Connect(function(hit: BasePart)
		local character = hit.Parent
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		triggerSwarmAttack(player)
	end)
end

for _, instance in CollectionService:GetTagged(GameConfig.BossCombat.FinishLineTag) do
	if instance:IsA("BasePart") then
		bindFinishPart(instance)
	end
end

CollectionService:GetInstanceAddedSignal(GameConfig.BossCombat.FinishLineTag):Connect(function(instance: Instance)
	if instance:IsA("BasePart") then
		bindFinishPart(instance)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	bossHPByPlayer[player] = nil
	finishDebounce[player] = nil
end)

print("[HybridCasualHub] BossCombatService ready")
