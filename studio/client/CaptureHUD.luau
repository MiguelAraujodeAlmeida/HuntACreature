-- Carga e disputa v4: renderização separada da simulação autoritativa.
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local S = W.Style
local Capture = {}
Capture.__index = Capture
function Capture.new(parent)
	local self = setmetatable({}, Capture)
	self.Charge = W.panel(parent, "ForcaArremesso", UDim2.fromOffset(510, 78), UDim2.new(0.5, 0, 1, -200), S.UI.Gold)
	self.Charge.AnchorPoint = Vector2.new(0.5, 0)
	self.Charge.Visible = false
	self.ChargeScale = Instance.new("UIScale")
	self.ChargeScale.Parent = self.Charge
	W.icon(self.Charge, "Laco", S.Icons.Lasso, UDim2.fromOffset(88, 88), UDim2.fromOffset(-14, -7))
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
	self.Hold = Button.new(
		self.Root,
		{
			name = "SegurarLaco",
			text = "PUXAR",
			textSize = 22,
			color = S.UI.Gold,
			size = UDim2.fromOffset(135, 54),
			position = UDim2.fromOffset(450, 73),
			zIndex = 12,
		}
	)
	self:Reset()
	return self
end
function Capture:Reset()
	self.desired = { target = 0.5, zone = 0.5, progress = 0.16, overlap = false, timeLeft = 28 }
	self.display = { target = 0.5, zone = 0.5, progress = 0.16 }
end
function Capture:Resize(view)
	local scale = math.min(1, (view.X - 28) / 610, view.Y < 500 and 0.8 or 1)
	self.Scale.Scale = scale
	self.ChargeScale.Scale = scale
	self.Root.Position = UDim2.new(0.5, 0, 1, -(110 + 150 * scale))
	self.Charge.Position = UDim2.new(0.5, 0, 1, -(106 + 78 * scale))
end
function Capture:SetCharging(power)
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
	self.Zone.Position = UDim2.new(d.zone - 0.16, 0, 0, 0)
	self.Zone.BackgroundColor3 = s.overlap and S.UI.Green or S.UI.White
	self.ProgressFill.Size = UDim2.fromScale(d.progress, 1)
	self.Progress.Text = string.format("%d%%", math.floor(d.progress * 100))
	self.Timer.Text = string.format("%ds", math.max(0, math.ceil(s.timeLeft or 0)))
	self.Hold:SetSelected(s.overlap)
end
return Capture
