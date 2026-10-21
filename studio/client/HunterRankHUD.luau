-- Entrada própria de Hunter Rank e celebração curta. Sem regras de progressão aqui.
local TweenService = game:GetService("TweenService")
local Rank = require(game.ReplicatedStorage.HACShared.HunterProgression)
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local Effects = require(script.Parent.UIEffects)
local Audio = require(script.Parent.AudioFeedback)
local RankHUD = {}
RankHUD.__index = RankHUD

function RankHUD.new(parent, onOpen)
	local self = setmetatable({}, RankHUD)
	self.Skin = Button.new(parent, {
		name = "HunterRankButton", text = "Rank 1", icon = W.Style.Icons.HunterRank,
		color = W.Style.UI.Purple, size = UDim2.fromOffset(86, 86),
		position = UDim2.fromOffset(16, 220), textSize = 19,
	})
	self.Root = self.Skin.Root
	self.Root:SetAttribute("FocusKey", "OpenHunterRank")
	self.Root.Activated:Connect(onOpen)
	local track, fill = W.bar(self.Root, "RankProgress", UDim2.new(0.84, 0, 0, 7),
		UDim2.new(0.08, 0, 1, -4), W.Style.UI.Purple)
	track.ZIndex = self.Root.ZIndex + 3
	fill.Size = UDim2.fromScale(0, 1)
	self.Fill = fill

	local toast = W.panel(parent, "RankUp", UDim2.fromOffset(378, 105),
		UDim2.new(0.5, 0, 0, 28), W.Style.UI.Purple)
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.ZIndex, toast.Visible = 45, false
	self.Toast = toast
	self.ToastScale = Instance.new("UIScale")
	self.ToastScale.Parent = toast
	local icon = W.icon(toast, "Crest", W.Style.Icons.HunterRank,
		UDim2.fromOffset(84, 84), UDim2.fromOffset(8, 10))
	icon.ZIndex = 46
	self.Title = W.text(toast, "Title", "RANK UP!", UDim2.new(1, -108, 0, 46),
		UDim2.fromOffset(94, 8), 30)
	self.Title.ZIndex = 46
	self.Subtitle = W.text(toast, "Reward", "", UDim2.new(1, -108, 0, 42),
		UDim2.fromOffset(94, 54), 17, W.Style.UI.White)
	self.Subtitle.ZIndex = 46
	return self
end

function RankHUD:Resize(view, position, size)
	self.Root.Size = UDim2.fromOffset(size, size)
	self.Root.Position = position
	self.Skin.caption:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize = size < 75 and 16 or 19
	self.Toast.Size = UDim2.fromOffset(math.min(378, view.X - 28), 105)
	self.Title.TextSize = view.X < 440 and 24 or 30
	self.Subtitle.TextSize = view.X < 440 and 14 or 17
end

function RankHUD:Update(xp)
	local level, _, progress = Rank.Progress(xp)
	if self.level ~= level then
		self.level = level
		self.Skin:SetText("Rank " .. level)
	end
	if self.xp ~= xp then
		self.xp = xp
		if self.fillTween then self.fillTween:Cancel() end
		self.fillTween = TweenService:Create(self.Fill,
			TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(progress, 1) })
		self.fillTween:Play()
	end
end

function RankHUD:Celebrate(from, to)
	if type(to) ~= "number" or type(from) ~= "number" or to <= from then return end
	self.version = (self.version or 0) + 1
	local version = self.version
	self.Title.Text = "RANK " .. to .. " UNLOCKED!"
	self.Subtitle.Text = string.format("+%d%% gold  ·  +%d%% training",
		Rank.GoldBonusPerRank * 100,
		Rank.TrainingBonusPerRank * 100)
	self.Toast.Visible = true
	self.ToastScale.Scale = 0.68
	if self.toastTween then self.toastTween:Cancel() end
	self.toastTween = TweenService:Create(self.ToastScale,
		TweenInfo.new(0.48, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
	self.toastTween:Play()
	Effects.Burst(self.Toast, W.Style.UI.Gold, 11)
	self.Skin:Shine()
	Audio.Play("Rare")
	task.delay(3.2, function()
		if version == self.version and self.Toast.Parent then self.Toast.Visible = false end
	end)
end

return RankHUD
