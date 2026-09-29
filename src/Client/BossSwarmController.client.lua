--!strict
--[[
	Client-side swarm visuals. Server already applied damage / rewards.
	Batched Heartbeat launches keep tween cost spread across frames.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Client = script.Parent
local SoldierObjectPool = require(Client.Modules.SoldierObjectPool)
local BossCombatJuice = require(Client.Modules.BossCombatJuice)
local BossUIController = require(Client.Controllers.BossUIController)

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

type SwarmAttackPayload = Types.SwarmAttackPayload

local player = Players.LocalPlayer
local pool = SoldierObjectPool.new(Workspace.CurrentCamera or Workspace)
local isPlaying = false

local function findBossHitbox(): BasePart?
	local hub = Workspace:FindFirstChild(GameConfig.World.HubModelName)
	local boss = hub and hub:FindFirstChild(GameConfig.BossCombat.BossModelName)
	local hitbox = boss and boss:FindFirstChild(GameConfig.BossCombat.BossHitboxName)
	if hitbox and hitbox:IsA("BasePart") then
		return hitbox
	end
	return nil
end

local function playSwarmAnimation(payload: SwarmAttackPayload)
	if isPlaying then
		return
	end
	isPlaying = true

	local hitbox = findBossHitbox()
	if not hitbox then
		warn("[BossSwarm] Boss hitbox not found under Workspace.Hub.SwarmBoss")
		isPlaying = false
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local formationOrigin = if root then root.CFrame else CFrame.new(0, 5, 80)

	local hitsToShow = math.min(payload.damageDealt, GameConfig.SwarmVisuals.MaxAnimatedSoldiers)
	local pendingSoldiers = pool:PrepareSwarm(hitsToShow, formationOrigin)

	local bossHPBefore = payload.bossCurrentHP + payload.damageDealt
	BossUIController:BeginEncounter(payload.bossMaxHP, bossHPBefore)

	local damagePerSoldier = 1
	local extraDamageRemainder = math.max(0, payload.damageDealt - hitsToShow)

	local queueIndex = 1
	local completedHits = 0
	local totalLaunched = #pendingSoldiers

	local function launchSoldierTween(soldier: BasePart, hitDamage: number)
		local target = hitbox.CFrame * CFrame.new(math.random(-3, 3), math.random(-2, 2), math.random(-3, 3))
		local tween = TweenService:Create(
			soldier,
			TweenInfo.new(GameConfig.SwarmVisuals.TweenDurationSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = target }
		)

		tween.Completed:Once(function()
			pool:Release(soldier)
			BossCombatJuice.emitHitParticles(hitbox)
			BossCombatJuice.playHitSound(hitbox)
			BossUIController:ApplyVisualHit(hitDamage)
			completedHits += 1

			if completedHits >= totalLaunched then
				BossUIController:SnapToAuthority(payload.bossCurrentHP, payload.bossMaxHP)
				isPlaying = false
			end
		end)

		tween:Play()
	end

	if totalLaunched == 0 then
		BossUIController:SnapToAuthority(payload.bossCurrentHP, payload.bossMaxHP)
		isPlaying = false
		return
	end

	-- Stagger: launch N soldiers per frame instead of all at once.
	local batchConnection: RBXScriptConnection?
	batchConnection = RunService.Heartbeat:Connect(function()
		local launchedThisFrame = 0
		while launchedThisFrame < GameConfig.SwarmVisuals.SoldiersPerFrame and queueIndex <= totalLaunched do
			local soldier = pendingSoldiers[queueIndex]
			local hitDamage = damagePerSoldier
			if queueIndex == totalLaunched and extraDamageRemainder > 0 then
				hitDamage += extraDamageRemainder
			end

			launchSoldierTween(soldier, hitDamage)
			queueIndex += 1
			launchedThisFrame += 1
		end

		if queueIndex > totalLaunched and batchConnection then
			batchConnection:Disconnect()
		end
	end)
end

local remotesFolder = ReplicatedStorage:WaitForChild(Remotes.FolderName)
local playSwarmRemote = remotesFolder:WaitForChild(Remotes.PlaySwarmAnimation) :: RemoteEvent

playSwarmRemote.OnClientEvent:Connect(function(payload: SwarmAttackPayload)
	playSwarmAnimation(payload)
end)

print("[HybridCasualHub] BossSwarmController ready")
