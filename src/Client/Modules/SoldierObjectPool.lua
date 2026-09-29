--!strict
--[[
	Client-only soldier visuals. Anchored parts — no .Touched / physics swarm.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

export type SoldierObjectPool = {
	PrepareSwarm: (self: SoldierObjectPool, count: number, origin: CFrame) -> { BasePart },
	Release: (self: SoldierObjectPool, soldier: BasePart) -> (),
	GetActiveCount: (self: SoldierObjectPool) -> number,
}

local SoldierObjectPool = {} :: SoldierObjectPool
SoldierObjectPool.__index = SoldierObjectPool

local POOL_FOLDER_NAME = "SwarmSoldierPool"

local function createSoldier(): BasePart
	local part = Instance.new("Part")
	part.Name = "SwarmSoldier"
	part.Size = Vector3.new(0.9, 1.4, 0.9)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(72, 132, 255)
	part.CastShadow = false
	return part
end

function SoldierObjectPool.new(parent: Instance): SoldierObjectPool
	local folder = Instance.new("Folder")
	folder.Name = POOL_FOLDER_NAME
	folder.Parent = parent

	return setmetatable({
		_folder = folder,
		_available = {} :: { BasePart },
		_active = {} :: { BasePart },
	}, SoldierObjectPool)
end

function SoldierObjectPool:PrepareSwarm(count: number, origin: CFrame): { BasePart }
	local capped = math.min(count, GameConfig.SwarmVisuals.MaxAnimatedSoldiers)
	local swarm: { BasePart } = {}

	for index = 1, capped do
		local soldier = table.remove(self._available)
		if not soldier then
			soldier = createSoldier()
			soldier.Parent = self._folder
		end
		table.insert(self._active, soldier)
		table.insert(swarm, soldier)

		local ring = math.floor((index - 1) / 12)
		local angle = ((index - 1) % 12) / 12 * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * (6 + ring * 2), 2 + ring * 0.2, math.sin(angle) * (6 + ring * 2))
		soldier.CFrame = origin * CFrame.new(offset)
	end

	return swarm
end

function SoldierObjectPool:Release(soldier: BasePart)
	local activeIndex = table.find(self._active, soldier)
	if activeIndex then
		table.remove(self._active, activeIndex)
	end
	soldier.Transparency = 0
	table.insert(self._available, soldier)
end

function SoldierObjectPool:GetActiveCount(): number
	return #self._active
end

return SoldierObjectPool
