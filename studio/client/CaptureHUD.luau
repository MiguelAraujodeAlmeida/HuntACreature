-- Carga e disputa v4: renderização separada da simulação autoritativa.
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local S = W.Style
local Effects = require(script.Parent.UIEffects)
local Audio = require(script.Parent.AudioFeedback)
local Capture = {}
Capture.__index = Capture
function Capture.new(parent)
	local self = setmetatable({}, Capture)
	self.Charge = W.panel(parent, "ForcaArremesso", UDim2.fromOffset(510, 78), UDim2.new(0.5, 0, 1, -200), S.UI.Gold)
	self.Charge.AnchorPoint = Vector2.new(0.5, 0)
	self.Charge.Visible = false
	self.ChargeScale = Instance.new("UIScale")
	self.ChargeScale.Parent = self.Charge
	W.icon(self.Charge, "Laco", S.Icons.Lasso, UDim2.fromOffset(60, 60), UDim2.fromOffset(6, 6))
	W.text(
		self.Charge,
		"Titulo",
		"ARREMESSO",
		UDim2.fromOffset(290, 24),
		UDim2.fromOffset(76, 8),
		19,
		S.UI.White,
		Enum.TextXAlignment.Left
	)
	self.Power = W.text(self.Charge, "Valor", "0%", UDim2.fromOffset(90, 26), UDim2.fromOffset(398, 6), 22, S.UI.Gold)
	local _, fill = W.bar(self.Charge, "Carga", UDim2.fromOffset(406, 22), UDim2.fromOffset(77, 40), S.UI.Gold)
	self.ChargeFill = fill
	self.Range = W.text(self.Charge, "Alcance", "", UDim2.fromOffset(145, 22), UDim2.fromOffset(257, 8), 16, S.UI.Gold)
	self.Root = W.panel(parent, "Captura", UDim2.fromOffset(610, 150), UDim2.new(0.5, 0, 1, -286), S.UI.Cyan)
	self.Root.AnchorPoint = Vector2.new(0.5, 0)
	self.Root.Visible = false
	self.Root.ZIndex = 10
	self.Scale = Instance.new("UIScale")
	self.Scale.Parent = self.Root
	W.icon(self.Root, "Laco", S.Icons.Lasso, UDim2.fromOffset(90, 90), UDim2.fromOffset(-9, 24))
	self.Name = W.text(
		self.Root,
		"Criatura",
		"Lumito",
		UDim2.fromOffset(300, 32),
		UDim2.fromOffset(85, 12),
		28,
		nil,
		Enum.TextXAlignment.Left
	)
	self.Progress =
		W.text(self.Root, "Progresso", "16%", UDim2.fromOffset(94, 32), UDim2.fromOffset(405, 12), 28, S.UI.Gold)
	self.Timer = W.text(self.Root, "Tempo", "28s", UDim2.fromOffset(66, 30), UDim2.fromOffset(520, 14), 20)
	local _, progress =
		W.bar(self.Root, "ProgressoBarra", UDim2.fromOffset(492, 12), UDim2.fromOffset(87, 50), S.UI.Green)
	self.ProgressFill = progress
	self.Track = W.frame(self.Root, "Disputa", UDim2.fromOffset(350, 42), UDim2.fromOffset(87, 79), S.UI.Ink, 13)
	self.Track.ClipsDescendants = true
	W.stroke(self.Track, S.UI.Cyan, 2)
	self.Zone = W.frame(self.Track, "Zona", UDim2.fromScale(0.32, 1), UDim2.fromScale(0.34, 0), S.UI.Cyan, 10)
	W.gradient(self.Zone, S.UI.Cyan, Color3.fromRGB(12, 95, 240))
	self.Target = W.frame(self.Track, "Alvo", UDim2.fromOffset(12, 42), UDim2.fromOffset(170, 0), S.UI.Gold, 6)
	W.stroke(self.Target, S.UI.White, 2)
	self.Hold = Button.new(self.Root, {
		name = "SegurarLaco",
		text = "PUXAR",
		textSize = 22,
		color = S.UI.Gold,
		size = UDim2.fromOffset(135, 54),
		position = UDim2.fromOffset(450, 73),
		zIndex = 12,
		sound = false,
	})
	self:Reset()
	return self
end
function Capture:Reset()
	self.milestone = 0
	self.desired = { target = 0.5, zone = 0.5, progress = 0.16, overlap = false, timeLeft = 28 }
	self.display = { target = 0.5, zone = 0.5, progress = 0.16 }
end
function Capture:Resize(layout)
	local width, height = layout.centerWidth, layout.captureHeight
	self.Scale.Scale, self.ChargeScale.Scale = 1, 1
	self.Root.Size = UDim2.fromOffset(width, height)
	self.Root.Position = UDim2.new(0.5, 0, 1, -(layout.captureBottom + height))
	local icon = self.Root:FindFirstChild("Laco")
	icon.Visible = width >= 520
	icon.Size = UDim2.fromOffset(58, 58)
	icon.Position = UDim2.fromOffset(6, 32)
	local left = icon.Visible and 70 or 14
	self.Name.Position = UDim2.fromOffset(left, 10)
	self.Name.Size = UDim2.fromOffset(width - left - 116, 24)
	self.Name.TextSize = layout.short and 18 or 22
	self.Name.TextScaled = true
	if not self.Name:FindFirstChildOfClass("UITextSizeConstraint") then
		local limit = Instance.new("UITextSizeConstraint")
		limit.MinTextSize, limit.MaxTextSize = 14, 22
		limit.Parent = self.Name
	end
	self.Progress.Position = UDim2.new(1, -112, 0, 10)
	self.Progress.Size = UDim2.fromOffset(56, 24)
	self.Progress.TextSize = 20
	self.Timer.Position = UDim2.new(1, -52, 0, 10)
	self.Timer.Size = UDim2.fromOffset(40, 24)
	self.Timer.TextSize = 16
	local bar = self.ProgressFill.Parent
	bar.Position = UDim2.fromOffset(left, 39)
	bar.Size = UDim2.new(1, -left - 14, 0, 10)
	self.Track.Position = UDim2.fromOffset(left, 60)
	self.Track.Size = UDim2.new(1, -left - 116, 0, height - 72)
	self.Target.Size = UDim2.new(0, 10, 1, 0)
	self.Hold.Root.Size = UDim2.fromOffset(88, 46)
	self.Hold.Root.Position = UDim2.new(1, -102, 0, 55)
	self.Hold.caption:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize = 18
	local chargeWidth = math.min(480, width)
	self.Charge.Size = UDim2.fromOffset(chargeWidth, 64)
	self.Charge.Position = UDim2.new(0.5, 0, 1, -(layout.chargeBottom + 64))
	self.Charge.Laco.Size = UDim2.fromOffset(44, 44)
	self.Charge.Laco.Position = UDim2.fromOffset(7, 8)
	self.Charge.Titulo.Position = UDim2.fromOffset(57, 7)
	self.Charge.Titulo.Size = UDim2.fromOffset(chargeWidth - 200, 20)
	self.Charge.Titulo.TextSize = 14
	self.Charge.Titulo.Visible = chargeWidth >= 380
	self.Power.Position = UDim2.new(1, -66, 0, 6)
	self.Power.Size = UDim2.fromOffset(54, 22)
	self.Power.TextSize = 20
	self.Range.Position = UDim2.fromOffset(57, 8)
	self.Range.Size = UDim2.fromOffset(chargeWidth - 132, 20)
	self.Range.TextXAlignment = Enum.TextXAlignment.Right
	self.Range.TextSize = 14
	self.ChargeFill.Parent.Position = UDim2.fromOffset(57, 35)
	self.ChargeFill.Parent.Size = UDim2.new(1, -72, 0, 19)
end
function Capture:SetCharging(power, range, maxRange)
	Audio.Charge(power)
	if range then
		self.Range.Text = string.format("%.0f / %.0f studs", range, maxRange)
	end
	if power >= 1 and not self.wasFull then
		Effects.Burst(self.Charge, W.Style.UI.Gold, 6)
	end
	self.wasFull = power >= 1
	self.Power.Text = string.format("%d%%", math.floor(power * 100))
	self.ChargeFill.Size = UDim2.fromScale(math.max(0.005, power), 1)
	self.Power.TextColor3 = power >= 1 and S.UI.White or S.UI.Gold
end
function Capture:SetHolding(value)
	self.Hold:SetHeld(value)
	self.Hold:SetText(value and "PUXANDO" or "PUXAR")
end
function Capture:Render(dt)
	if not self.Root.Visible then
		return
	end
	local d, s = self.display, self.desired
	local alpha = 1 - math.exp(-dt * 20)
	d.target += (s.target - d.target) * alpha
	d.zone += (s.zone - d.zone) * alpha
	d.progress += (s.progress - d.progress) * (1 - math.exp(-dt * 12))
	self.Target.Position = UDim2.new(d.target, -6, 0, 0)
	local radius = s.radius or 0.16
	self.Zone.Size = UDim2.fromScale(radius * 2, 1)
	self.Zone.Position = UDim2.new(d.zone - radius, 0, 0, 0)
	self.Zone.BackgroundColor3 = s.overlap and S.UI.Green or S.UI.White
	self.ProgressFill.Size = UDim2.fromScale(d.progress, 1)
	self.Progress.Text = string.format("%d%%", math.floor(d.progress * 100))
	self.Timer.Text = string.format("%ds", math.max(0, math.ceil(s.timeLeft or 0)))
	self.Timer.TextColor3 = s.potion and S.UI.Green or S.UI.White
	self.Target.BackgroundColor3 = s.potion and S.UI.Green or S.UI.Gold
	local milestone = math.floor(d.progress * 4)
	if milestone > self.milestone then
		self.milestone = milestone
		Effects.Burst(self.Progress, S.UI.Gold, 5)
		if milestone < 4 then Audio.Play("Progress", 1 + milestone * 0.12) end
	end
	self.Hold:SetSelected(s.overlap)
end
return Capture

