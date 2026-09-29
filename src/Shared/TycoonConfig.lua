--!strict
--[[
	Tycoon node definitions (single source of truth for costs, deps, buffs).

	How to expand:
	1. Add a Model under ReplicatedStorage.TycoonPrefabs matching `PrefabName`.
	2. Append a new entry to `Nodes` with a unique `ID`.
	3. Set `Dependency` to the prerequisite node ID (or nil for roots).
	4. Tune `PlotOffset` (CFrame relative to the player's plot origin).
	5. Optional `Buff` permanently increases `Stats[Stat]` on the server profile.
]]

export type TycoonBuff = {
	Stat: string,
	Value: number,
}

export type TycoonNode = {
	ID: string,
	Cost: number,
	PrefabName: string,
	Dependency: string?,
	PlotOffset: CFrame,
	Buff: TycoonBuff?,
}

local TycoonConfig = {
	--[[
		Expand by copying a block and chaining Dependency:
		Dependency = "PreviousNodeId"
	]]
	Nodes = {
		Barracks = {
			ID = "Barracks",
			Cost = 150,
			PrefabName = "Barracks",
			Dependency = nil,
			PlotOffset = CFrame.new(-12, 0, -10),
			Buff = { Stat = "StartingArmy", Value = 5 },
		},
		Armory = {
			ID = "Armory",
			Cost = 400,
			PrefabName = "Armory",
			Dependency = "Barracks",
			PlotOffset = CFrame.new(0, 0, -14),
			Buff = { Stat = "StartingArmy", Value = 10 },
		},
		CommandCenter = {
			ID = "CommandCenter",
			Cost = 900,
			PrefabName = "CommandCenter",
			Dependency = "Armory",
			PlotOffset = CFrame.new(12, 0, -10),
			Buff = { Stat = "StartingArmy", Value = 20 },
		},
	} :: { [string]: TycoonNode },
}

local nodeList: { TycoonNode }? = nil

function TycoonConfig.getNode(nodeId: string): TycoonNode?
	return TycoonConfig.Nodes[nodeId]
end

function TycoonConfig.getAllNodes(): { TycoonNode }
	if nodeList then
		return nodeList
	end
	local list: { TycoonNode } = {}
	for _, node in TycoonConfig.Nodes do
		table.insert(list, node)
	end
	table.sort(list, function(a, b)
		return a.Cost < b.Cost
	end)
	nodeList = list
	return list
end

--[[
	Shared predicate for UI hints only — server MUST re-validate before spending currency.
]]
function TycoonConfig.canPurchase(
	nodeId: string,
	unlocked: { [string]: boolean },
	coins: number
): (boolean, string?)
	local node = TycoonConfig.getNode(nodeId)
	if not node then
		return false, "InvalidNode"
	end
	if unlocked[nodeId] then
		return false, "AlreadyUnlocked"
	end
	if node.Dependency and not unlocked[node.Dependency] then
		return false, "MissingDependency"
	end
	if coins < node.Cost then
		return false, "InsufficientCoins"
	end
	return true, nil
end

return TycoonConfig
