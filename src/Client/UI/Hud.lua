--!strict
local Players = game:GetService("Players")

export type Hud = {
	Gui: ScreenGui,
	SetCoins: (self: Hud, coins: number) -> (),
	SetTimer: (self: Hud, label: string, seconds: number) -> (),
}

local Hud = {} :: Hud
Hud.__index = Hud

function Hud.new(): Hud
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HybridCasualHud"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "Root"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.fromScale(0.5, 0.02)
	frame.Size = UDim2.fromOffset(320, 88)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 6)
	layout.Parent = frame

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(1, 0, 0, 28)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextSize = 20
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.TextColor3 = Color3.fromRGB(255, 214, 102)
	coinsLabel.Text = "Coins: 0"
	coinsLabel.Parent = frame

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, 0, 0, 24)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Font = Enum.Font.GothamMedium
	timerLabel.TextSize = 18
	timerLabel.TextXAlignment = Enum.TextXAlignment.Left
	timerLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	timerLabel.Text = "Minigame: waiting..."
	timerLabel.Parent = frame

	local self = setmetatable({
		Gui = screenGui,
		_coinsLabel = coinsLabel,
		_timerLabel = timerLabel,
	}, Hud)

	return self
end

function Hud:SetCoins(coins: number)
	self._coinsLabel.Text = string.format("Coins: %d", coins)
end

function Hud:SetTimer(label: string, seconds: number)
	if seconds > 0 then
		self._timerLabel.Text = string.format("%s — %ds", label, seconds)
	else
		self._timerLabel.Text = label
	end
end

return Hud
