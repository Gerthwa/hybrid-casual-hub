--!strict
--[[
	Client tycoon pads + spawn juice. Currency and unlock state are server-authoritative.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

type TycoonProgressPayload = Types.TycoonProgressPayload
type TycoonStructureSpawnedPayload = Types.TycoonStructureSpawnedPayload

local player = Players.LocalPlayer
local BUTTONS_FOLDER_NAME = "PurchasePads"
local PLOTS_FOLDER_NAME = "TycoonPlots"
local PLOT_ORIGIN_NAME = "Origin"

local progress: TycoonProgressPayload = {
	unlocked = {},
	coins = 0,
	stats = { StartingArmy = 0 },
}

local purchasePads: { [string]: BasePart } = {}

local remotesFolder = ReplicatedStorage:WaitForChild(Remotes.FolderName)
local requestPurchase = remotesFolder:WaitForChild(Remotes.TycoonRequestPurchase) :: RemoteFunction
local progressUpdated = remotesFolder:WaitForChild(Remotes.TycoonProgressUpdated) :: RemoteEvent
local structureSpawned = remotesFolder:WaitForChild(Remotes.TycoonStructureSpawned) :: RemoteEvent

local function getLocalPlot(): Model?
	local hub = Workspace:FindFirstChild("Hub")
	local plots = hub and hub:FindFirstChild(PLOTS_FOLDER_NAME)
	if not plots then
		return nil
	end
	for _, plot in plots:GetChildren() do
		if plot:IsA("Model") and plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot
		end
	end
	return nil
end

local function getPlotOrigin(plot: Model): CFrame
	local origin = plot:FindFirstChild(PLOT_ORIGIN_NAME)
	if origin and origin:IsA("BasePart") then
		return origin.CFrame
	end
	return plot:GetPivot()
end

local function playPlacementJuice(building: Model)
	local primary = building.PrimaryPart or building:FindFirstChildWhichIsA("BasePart")
	if not primary then
		return
	end

	local baseScale = building:GetScale()
	building:ScaleTo(0.01)

	-- Model tweening via stepped ScaleTo for elastic feel
	local start = os.clock()
	local duration = 0.65
	local connection: RBXScriptConnection?
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		local alpha = math.clamp((os.clock() - start) / duration, 0, 1)
		local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
		local scale = math.max(0.01, eased) * baseScale
		building:ScaleTo(scale)
		if alpha >= 1 and connection then
			connection:Disconnect()
			building:ScaleTo(baseScale)
		end
	end)

	local attachment = primary:FindFirstChild("PoofAttachment") :: Attachment?
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "PoofAttachment"
		attachment.Parent = primary
	end

	local emitter = attachment:FindFirstChild("PoofEmitter") :: ParticleEmitter?
	if not emitter then
		emitter = Instance.new("ParticleEmitter")
		emitter.Name = "PoofEmitter"
		emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.3, 0.6)
		emitter.Speed = NumberRange.new(6, 12)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Parent = attachment
	end
	emitter:Emit(24)

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://12221967"
	sound.Volume = 0.6
	sound.PlaybackSpeed = 0.95 + math.random() * 0.1
	sound.Parent = primary
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

local function findSpawnedBuilding(payload: TycoonStructureSpawnedPayload): Model?
	local hub = Workspace:FindFirstChild("Hub")
	local plots = hub and hub:FindFirstChild(PLOTS_FOLDER_NAME)
	local plot = plots and plots:FindFirstChild(payload.plotName)
	local structures = plot and plot:FindFirstChild("Structures")
	local building = structures and structures:FindFirstChild(payload.nodeId)
	if building and building:IsA("Model") then
		return building
	end
	return nil
end

local function clearPads()
	for _, pad in purchasePads do
		pad:Destroy()
	end
	table.clear(purchasePads)
end

local function createPurchasePad(plot: Model, node: TycoonConfig.TycoonNode)
	local pad = Instance.new("Part")
	pad.Name = "Pad_" .. node.ID
	pad.Size = Vector3.new(5, 1, 5)
	pad.Anchored = true
	pad.CanCollide = false
	pad.Material = Enum.Material.Neon
	pad.Color = Color3.fromRGB(255, 196, 72)
	pad.Transparency = 0.2
	pad.CFrame = getPlotOrigin(plot) * node.PlotOffset * CFrame.new(0, 0.5, 0)
	pad:SetAttribute("TycoonNodeId", node.ID)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(140, 56)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = pad

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = string.format("%s\n%d Coins", node.ID, node.Cost)
	label.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Unlock"
	prompt.ObjectText = node.ID
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 12
	prompt.Parent = pad

	prompt.Triggered:Connect(function()
		local ok, err = requestPurchase:InvokeServer(node.ID)
		if not ok then
			warn("[Tycoon] Purchase failed:", err)
		end
	end)

	local buttonsFolder = plot:FindFirstChild(BUTTONS_FOLDER_NAME)
	if not buttonsFolder then
		buttonsFolder = Instance.new("Folder")
		buttonsFolder.Name = BUTTONS_FOLDER_NAME
		buttonsFolder.Parent = plot
	end
	pad.Parent = buttonsFolder
	purchasePads[node.ID] = pad
end

local function refreshPurchasePads()
	local plot = getLocalPlot()
	clearPads()
	if not plot then
		return
	end

	for _, node in TycoonConfig.getAllNodes() do
		if progress.unlocked[node.ID] then
			-- already built
		else
			local dependencyMet = if node.Dependency then progress.unlocked[node.Dependency] else true
			if dependencyMet then
				createPurchasePad(plot, node)
			end
		end
	end
end

progressUpdated.OnClientEvent:Connect(function(payload: TycoonProgressPayload)
	progress = payload
	refreshPurchasePads()
end)

structureSpawned.OnClientEvent:Connect(function(payload: TycoonStructureSpawnedPayload)
	local building = findSpawnedBuilding(payload)
	if building then
		playPlacementJuice(building)
	end
	if payload.ownerUserId == player.UserId then
		refreshPurchasePads()
	end
end)

task.defer(refreshPurchasePads)

print("[HybridCasualHub] TycoonController ready")
