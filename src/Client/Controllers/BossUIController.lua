--!strict
--[[
	Boss health bar + floating damage numbers (client-side presentation).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local BossUIController = {}

local bossHitbox: BasePart? = nil
local healthFill: Frame? = nil
local visualHP = 0
local visualMaxHP = 1

local function findBossHitbox(): BasePart?
	local hub = Workspace:FindFirstChild(GameConfig.World.HubModelName)
	if not hub then
		return nil
	end
	local boss = hub:FindFirstChild(GameConfig.BossCombat.BossModelName)
	if not boss then
		return nil
	end
	local hitbox = boss:FindFirstChild(GameConfig.BossCombat.BossHitboxName)
	if hitbox and hitbox:IsA("BasePart") then
		return hitbox
	end
	return nil
end

local function ensureBillboard(hitbox: BasePart): Frame
	local existing = hitbox:FindFirstChild("BossHealthBillboard")
	if existing and existing:IsA("BillboardGui") then
		local fill = existing:FindFirstChild("Fill", true) :: Frame?
		if fill then
			return fill
		end
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BossHealthBillboard"
	billboard.Size = UDim2.fromOffset(220, 36)
	billboard.StudsOffset = Vector3.new(0, 12, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = hitbox

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	back.BorderSizePixel = 0
	back.Parent = billboard

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 8)
	backCorner.Parent = back

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 72, 72)
	fill.BorderSizePixel = 0
	fill.Parent = back

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 8)
	fillCorner.Parent = fill

	return fill
end

function BossUIController:Init()
	bossHitbox = findBossHitbox()
	if bossHitbox then
		healthFill = ensureBillboard(bossHitbox)
	end
end

function BossUIController:BeginEncounter(bossMaxHP: number, bossHPBeforeDamage: number)
	visualMaxHP = math.max(1, bossMaxHP)
	visualHP = math.clamp(bossHPBeforeDamage, 0, visualMaxHP)
	self:_tweenHealthBar(visualHP / visualMaxHP)
end

function BossUIController:ApplyVisualHit(damage: number)
	if not healthFill or not bossHitbox then
		bossHitbox = findBossHitbox()
		if bossHitbox then
			healthFill = ensureBillboard(bossHitbox)
		end
	end
	if not healthFill or not bossHitbox then
		return
	end

	visualHP = math.max(0, visualHP - damage)
	self:_tweenHealthBar(visualHP / visualMaxHP)
	self:_spawnDamageIndicator(bossHitbox, damage)
end

function BossUIController:SnapToAuthority(bossCurrentHP: number, bossMaxHP: number)
	visualMaxHP = math.max(1, bossMaxHP)
	visualHP = math.clamp(bossCurrentHP, 0, visualMaxHP)
	self:_tweenHealthBar(visualHP / visualMaxHP, 0.12)
end

function BossUIController:_tweenHealthBar(scaleX: number, duration: number?)
	local fill = healthFill
	if not fill then
		return
	end
	local tween = TweenService:Create(fill, TweenInfo.new(duration or 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(math.clamp(scaleX, 0, 1), 1),
	})
	tween:Play()
end

function BossUIController:_spawnDamageIndicator(hitbox: BasePart, damage: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(80, 40)
	billboard.StudsOffset = Vector3.new(math.random(-4, 4), 6 + math.random(), math.random(-4, 4))
	billboard.AlwaysOnTop = true
	billboard.Parent = hitbox

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 22
	label.TextColor3 = Color3.fromRGB(255, 235, 120)
	label.TextStrokeTransparency = 0.4
	label.Text = string.format("-%d", damage)
	label.Parent = billboard

	local rise = TweenService:Create(billboard, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = billboard.StudsOffset + Vector3.new(0, 3, 0),
	})

	local fade = TweenService:Create(label, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})

	rise:Play()
	fade:Play()
	fade.Completed:Once(function()
		billboard:Destroy()
	end)
end

return BossUIController
