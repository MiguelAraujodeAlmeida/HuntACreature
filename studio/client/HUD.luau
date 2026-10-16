-- Apresentação do jogo. Nenhuma regra de captura ou economia vive aqui.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Style = require(game:GetService("ReplicatedStorage").HACShared.VisualStyle)
local C = Style.Colors

local HUD = {}
HUD.__index = HUD

local function corner(object, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius)
	value.Parent = object
end

local function stroke(object, color, thickness, transparency)
	local value = Instance.new("UIStroke")
	value.Color = color
	value.Thickness = thickness
	value.Transparency = transparency or 0
	value.Parent = object
	return value
end

local function frame(parent, name, size, position, color, transparency, radius)
	local object = Instance.new("Frame")
	object.Name = name
	object.Size = size
	object.Position = position
	object.BackgroundColor3 = color or C.Ink
	object.BackgroundTransparency = transparency or 0
	object.BorderSizePixel = 0
	object.Parent = parent
	if radius then corner(object, radius) end
	return object
end

local function label(parent, name, value, size, position, fontSize, color, alignment)
	local object = Instance.new("TextLabel")
	object.Name = name
	object.Size = size
	object.Position = position
	object.BackgroundTransparency = 1
	object.Font = Style.Font
	object.Text = value
	object.TextColor3 = color or C.White
	object.TextSize = fontSize
	object.TextXAlignment = alignment or Enum.TextXAlignment.Left
	object.TextYAlignment = Enum.TextYAlignment.Center
	object.TextWrapped = true
	object.Parent = parent
	return object
end

local function sprite(parent, name, index, size, position)
	local object = Instance.new("ImageLabel")
	object.Name = name
	object.Size = size
	object.Position = position
	object.BackgroundTransparency = 1
	object.Image = Style.ResourceIconSheet
	object.ImageRectSize = Style.IconCellSize
	object.ImageRectOffset = Vector2.new((index - 1) * Style.IconCellSize.X, 0)
	object.ScaleType = Enum.ScaleType.Fit
	object.Parent = parent
	return object
end

local function stat(parent, name, index, caption)
	local item = frame(parent, name, UDim2.fromOffset(160, 43), UDim2.fromOffset(0, 0), C.Ink, 1)
	sprite(item, "Icone", index, UDim2.fromOffset(42, 42), UDim2.fromOffset(0, 0))
	local number = label(item, "Valor", "0", UDim2.fromOffset(110, 29), UDim2.fromOffset(49, 0), 27, C.White)
	number.Font = Style.DisplayFont
	number.TextStrokeColor3 = C.Ink
	number.TextStrokeTransparency = 0.15
	local cap = label(item, "Legenda", caption, UDim2.fromOffset(105, 14), UDim2.fromOffset(51, 28), 12, C.White)
	cap.TextStrokeColor3 = C.Ink
	cap.TextStrokeTransparency = 0.2
	return item, number, cap
end

function HUD.new(player)
	local self = setmetatable({}, HUD)
	self.player = player
	local gui = Instance.new("ScreenGui")
	gui.Name = "HuntACreatureGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	self.Gui = gui

	local resources = frame(gui, "Recursos", UDim2.fromOffset(170, 138), UDim2.new(0, 15, 1, -162), C.Ink, 1)
	local gold, goldText = stat(resources, "Ouro", 1, "OURO")
	local xp, xpText = stat(resources, "XP", 2, "EXPERIÊNCIA")
	local strength, strengthText = stat(resources, "Forca", 3, "FORÇA DO LAÇO")
	self.ResourceItems = {gold, xp, strength}
	self.GoldText = goldText
	self.XPText = xpText
	self.ForceText = strengthText

	local bag = Instance.new("ImageButton")
	bag.Name = "BolsaBotao"
	bag.Size = UDim2.fromOffset(122, 66)
	bag.Position = UDim2.new(0, 18, 0.43, 0)
	bag.BackgroundTransparency = 1
	bag.Image = ""
	bag.Parent = gui
	self.BagButton = bag
	local bagIcon = Instance.new("ImageLabel")
	bagIcon.Name = "Icone"
	bagIcon.Size = UDim2.fromOffset(64, 64)
	bagIcon.Position = UDim2.fromOffset(0, 0)
	bagIcon.BackgroundTransparency = 1
	bagIcon.Image = Style.SatchelIcon
	bagIcon.ScaleType = Enum.ScaleType.Fit
	bagIcon.Parent = bag
	local bagCaption = label(bag, "Legenda", "BOLSA", UDim2.fromOffset(64, 28), UDim2.fromOffset(58, 30), 16, C.White)
	bagCaption.Font = Style.DisplayFont
	bagCaption.TextStrokeColor3 = C.Ink
	bagCaption.TextStrokeTransparency = 0
	local bagBadge = frame(bag, "Contagem", UDim2.fromOffset(31, 26), UDim2.fromOffset(52, 0), C.Coral, 0, 13)
	stroke(bagBadge, C.Ink, 2)
	self.BagBadge = label(bagBadge, "Texto", "0", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 15, C.White, Enum.TextXAlignment.Center)
	self.BagBadge.Font = Style.DisplayFont

	local throw = Instance.new("ImageButton")
	throw.Name = "Arremessar"
	throw.Size = UDim2.fromOffset(82, 78)
	throw.Position = UDim2.new(1, -100, 0, 102)
	throw.BackgroundColor3 = C.Ink
	throw.BackgroundTransparency = 0.18
	throw.BorderSizePixel = 0
	throw.Image = ""
	throw.Visible = false
	throw.Parent = gui
	corner(throw, 18)
	stroke(throw, C.Rope, 2)
	sprite(throw, "Laco", 3, UDim2.fromOffset(51, 51), UDim2.fromOffset(15, 1))
	local throwCaption = label(throw, "Legenda", "LANÇAR", UDim2.fromOffset(76, 22), UDim2.fromOffset(3, 54), 12, C.White, Enum.TextXAlignment.Center)
	throwCaption.Font = Style.DisplayFont
	self.ThrowButton = throw

	local reticle = frame(gui, "Mira", UDim2.fromOffset(28, 28), UDim2.new(0.5, -14, 0.5, -14), C.Ink, 1)
	reticle.Visible = false
	frame(reticle, "Centro", UDim2.fromOffset(6, 6), UDim2.fromOffset(11, 11), C.Gold, 0, 3)
	frame(reticle, "Topo", UDim2.fromOffset(2, 6), UDim2.fromOffset(13, 0), C.White)
	frame(reticle, "Baixo", UDim2.fromOffset(2, 6), UDim2.fromOffset(13, 22), C.White)
	frame(reticle, "Esquerda", UDim2.fromOffset(6, 2), UDim2.fromOffset(0, 13), C.White)
	frame(reticle, "Direita", UDim2.fromOffset(6, 2), UDim2.fromOffset(22, 13), C.White)
	self.Reticle = reticle

	local charge = frame(gui, "ForcaArremesso", UDim2.fromOffset(440, 55), UDim2.new(0.5, -220, 1, -125), C.Ink, 0.12, 13)
	charge.Visible = false
	stroke(charge, C.Rope, 2)
	self.ChargePanel = charge
	local chargeTitle = label(charge, "Titulo", "FORÇA DO LAÇO", UDim2.fromOffset(290, 21), UDim2.fromOffset(17, 3), 15, C.White)
	chargeTitle.Font = Style.DisplayFont
	self.ChargeText = label(charge, "Valor", "0%", UDim2.fromOffset(82, 21), UDim2.new(1, -99, 0, 3), 16, C.Gold, Enum.TextXAlignment.Right)
	self.ChargeText.Font = Style.DisplayFont
	local chargeBack = frame(charge, "Trilha", UDim2.new(1, -34, 0, 14), UDim2.fromOffset(17, 31), C.White, 0.7, 7)
	local chargeFill = frame(chargeBack, "Barra", UDim2.fromScale(0.02, 1), UDim2.fromScale(0, 0), C.Gold, 0, 7)
	self.ChargeFill = chargeFill
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(C.Sun, C.Coral)
	gradient.Parent = chargeFill

	local shade = frame(gui, "FundoPainel", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.Ink, 0.45)
	shade.Visible = false
	shade.ZIndex = 20
	self.Shade = shade
	local sheet = frame(gui, "PainelInfo", UDim2.fromOffset(360, 180), UDim2.fromScale(0.5, 0.5), C.Ink, 0.04, 18)
	sheet.AnchorPoint = Vector2.new(0.5, 0.5)
	sheet.Visible = false
	sheet.ZIndex = 21
	stroke(sheet, C.Rope, 2)
	self.Sheet = sheet
	local sheetIcon = Instance.new("ImageLabel")
	sheetIcon.Name = "BolsaIcone"
	sheetIcon.Size = UDim2.fromOffset(42, 42)
	sheetIcon.Position = UDim2.fromOffset(18, 11)
	sheetIcon.BackgroundTransparency = 1
	sheetIcon.Image = Style.SatchelIcon
	sheetIcon.Parent = sheet
	self.SheetTitle = label(sheet, "Titulo", "BOLSA", UDim2.fromOffset(230, 40), UDim2.fromOffset(67, 13), 25, C.White)
	self.SheetTitle.Font = Style.DisplayFont
	self.SheetBody = label(sheet, "Corpo", "", UDim2.fromOffset(310, 105), UDim2.fromOffset(23, 65), 20, C.White)
	self.SheetBody.TextYAlignment = Enum.TextYAlignment.Top
	local close = Instance.new("TextButton")
	close.Name = "Fechar"
	close.Size = UDim2.fromOffset(38, 38)
	close.Position = UDim2.new(1, -49, 0, 11)
	close.Text = "×"
	close.TextSize = 28
	close.Font = Style.DisplayFont
	close.TextColor3 = C.White
	close.BackgroundColor3 = C.Coral
	close.BorderSizePixel = 0
	close.ZIndex = 22
	close.Parent = sheet
	corner(close, 11)
	self.CloseButton = close
	close.Activated:Connect(function() self:CloseSheet() end)
	bag.Activated:Connect(function() self:OpenSheet("bag") end)

	local capture = frame(gui, "Captura", UDim2.fromOffset(540, 126), UDim2.new(0.5, 0, 1, -257), C.Ink, 0.1, 18)
	capture.AnchorPoint = Vector2.new(0.5, 0)
	capture.Visible = false
	capture.ZIndex = 30
	stroke(capture, C.Rope, 2)
	self.CapturePanel = capture
	self.CreatureName = label(capture, "Criatura", "LUMITO", UDim2.fromOffset(245, 29), UDim2.fromOffset(24, 7), 22, C.White)
	self.CreatureName.Font = Style.DisplayFont
	self.ProgressText = label(capture, "Progresso", "16%", UDim2.fromOffset(75, 29), UDim2.new(1, -132, 0, 7), 23, C.Gold, Enum.TextXAlignment.Right)
	self.ProgressText.Font = Style.DisplayFont
	self.TimerText = label(capture, "Tempo", "28s", UDim2.fromOffset(54, 29), UDim2.new(1, -68, 0, 7), 15, C.White, Enum.TextXAlignment.Right)
	local progressBack = frame(capture, "ProgressoFundo", UDim2.new(1, -48, 0, 7), UDim2.fromOffset(24, 42), C.White, 0.65, 4)
	self.ProgressFill = frame(progressBack, "Barra", UDim2.fromScale(0.16, 1), UDim2.fromScale(0, 0), C.Gold, 0, 4)
	local track = frame(capture, "Trilha", UDim2.fromOffset(354, 35), UDim2.fromOffset(24, 66), C.White, 0.78, 11)
	track.ClipsDescendants = true
	stroke(track, C.Rope, 1, 0.3)
	self.Track = track
	local zone = frame(track, "Zona", UDim2.fromOffset(113, 35), UDim2.fromOffset(120, 0), C.Sky, 0.3, 10)
	stroke(zone, C.Sky, 2)
	self.Zone = zone
	local target = frame(track, "Alvo", UDim2.fromOffset(13, 35), UDim2.fromOffset(170, 0), C.Gold, 0, 5)
	stroke(target, C.Ink, 2)
	self.Target = target
	local hold = Instance.new("TextButton")
	hold.Name = "SegurarLaco"
	hold.Size = UDim2.fromOffset(120, 50)
	hold.Position = UDim2.new(1, -138, 0, 61)
	hold.Text = "PUXAR"
	hold.TextColor3 = C.Ink
	hold.TextSize = 18
	hold.Font = Style.DisplayFont
	hold.BackgroundColor3 = C.Rope
	hold.BorderSizePixel = 0
	hold.ZIndex = 32
	hold.Parent = capture
	corner(hold, 12)
	self.HoldButton = hold

	local toast = frame(gui, "Aviso", UDim2.fromOffset(380, 46), UDim2.new(0.5, 0, 0, 19), C.Ink, 0.08, 12)
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Visible = false
	toast.ZIndex = 40
	stroke(toast, C.Rope, 2)
	self.Toast = toast
	self.ToastText = label(toast, "Texto", "", UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), 17, C.White, Enum.TextXAlignment.Center)
	self.ToastText.ZIndex = 41

	local reward = label(gui, "Recompensa", "", UDim2.fromOffset(650, 78), UDim2.fromScale(0.5, 0.23), 39, C.Gold, Enum.TextXAlignment.Center)
	reward.AnchorPoint = Vector2.new(0.5, 0.5)
	reward.Font = Style.DisplayFont
	reward.TextStrokeColor3 = C.Ink
	reward.TextStrokeTransparency = 0
	reward.Visible = false
	reward.ZIndex = 50
	self.RewardText = reward
	self.RewardScale = Instance.new("UIScale")
	self.RewardScale.Parent = reward

	self.toastVersion = 0
	self.rewardVersion = 0
	self.equipped = false
	self.capturing = false
	self.desired = {target = 0.5, zone = 0.5, progress = 0.16, overlap = false, timeLeft = 28, streak = 0}
	self.display = {target = 0.5, zone = 0.5, progress = 0.16}

	local function resize()
		local view = workspace.CurrentCamera.ViewportSize
		local compact = view.Y < 500 or view.X < 700
		if compact then
			resources.Size = UDim2.fromOffset(350, 42)
			resources.Position = UDim2.fromOffset(8, 46)
			for i, item in ipairs(self.ResourceItems) do
				item.Position = UDim2.fromOffset((i - 1) * 112, 0)
				item.Size = UDim2.fromOffset(110, 42)
				item.Icone.Size = UDim2.fromOffset(32, 32)
				item.Icone.Position = UDim2.fromOffset(0, 4)
				item.Valor.Position = UDim2.fromOffset(36, 1)
				item.Valor.Size = UDim2.fromOffset(70, 24)
				item.Valor.TextSize = 24
				item.Legenda.Position = UDim2.fromOffset(37, 25)
				item.Legenda.TextSize = 12
				item.Legenda.Text = ({"OURO", "XP", "FORÇA"})[i]
			end
			bag.Position = UDim2.fromOffset(13, 91)
			throw.Position = UDim2.new(1, -97, 0, 93)
			charge.Size = UDim2.fromOffset(340, 55)
			charge.Position = UDim2.new(0.5, -170, 1, -95)
			capture.Size = UDim2.fromOffset(440, 119)
			capture.Position = UDim2.new(0.5, 0, 1, -187)
			track.Size = UDim2.fromOffset(260, 32)
			track.Position = UDim2.fromOffset(19, 65)
			zone.Size = UDim2.fromOffset(83, 32)
			target.Size = UDim2.fromOffset(12, 32)
			hold.Size = UDim2.fromOffset(120, 49)
			hold.Position = UDim2.new(1, -140, 0, 59)
			progressBack.Position = UDim2.fromOffset(19, 41)
			progressBack.Size = UDim2.new(1, -38, 0, 7)
			self.CreatureName.Position = UDim2.fromOffset(19, 6)
			self.CreatureName.TextSize = 19
			reward.Size = UDim2.fromOffset(math.min(520, view.X - 20), 70)
			reward.TextSize = 30
			toast.Size = UDim2.fromOffset(math.min(350, view.X - 20), 46)
		else
			resources.Size = UDim2.fromOffset(170, 138)
			resources.Position = UDim2.new(0, 15, 1, -162)
			for i, item in ipairs(self.ResourceItems) do
				item.Position = UDim2.fromOffset(0, (i - 1) * 45)
				item.Size = UDim2.fromOffset(160, 43)
				item.Icone.Size = UDim2.fromOffset(42, 42)
				item.Icone.Position = UDim2.fromOffset(0, 0)
				item.Valor.Position = UDim2.fromOffset(49, 0)
				item.Valor.Size = UDim2.fromOffset(110, 29)
				item.Valor.TextSize = 27
				item.Legenda.Position = UDim2.fromOffset(51, 28)
				item.Legenda.TextSize = 12
				item.Legenda.Text = ({"OURO", "EXPERIÊNCIA", "FORÇA DO LAÇO"})[i]
			end
			bag.Position = UDim2.new(0, 18, 0.43, 0)
			charge.Size = UDim2.fromOffset(440, 55)
			charge.Position = UDim2.new(0.5, -220, 1, -125)
			capture.Size = UDim2.fromOffset(540, 126)
			capture.Position = UDim2.new(0.5, 0, 1, -257)
			track.Size = UDim2.fromOffset(354, 35)
			track.Position = UDim2.fromOffset(24, 66)
			zone.Size = UDim2.fromOffset(113, 35)
			target.Size = UDim2.fromOffset(13, 35)
			hold.Position = UDim2.new(1, -138, 0, 61)
			progressBack.Position = UDim2.fromOffset(24, 42)
			progressBack.Size = UDim2.new(1, -48, 0, 7)
			self.CreatureName.Position = UDim2.fromOffset(24, 7)
			self.CreatureName.TextSize = 22
			reward.Size = UDim2.fromOffset(650, 78)
			reward.TextSize = 39
			toast.Size = UDim2.fromOffset(380, 46)
		end
		charge.Trilha.Size = UDim2.new(1, -34, 0, 14)
	end
	resize()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	self.renderConnection = RunService.RenderStepped:Connect(function(dt) self:_render(dt) end)
	return self
end

function HUD:OpenSheet(kind)
	self.sheetKind = kind
	self.Shade.Visible = true
	self.Sheet.Visible = true
	self:UpdateStats()
end

function HUD:CloseSheet()
	self.sheetKind = nil
	self.Shade.Visible = false
	self.Sheet.Visible = false
end

function HUD:UpdateStats()
	local stats = self.player:FindFirstChild("leaderstats")
	local gold = stats and stats:FindFirstChild("Ouro")
	local xp = stats and stats:FindFirstChild("XP")
	self.GoldText.Text = tostring(gold and gold.Value or 0)
	self.XPText.Text = tostring(xp and xp.Value or 0)
	self.ForceText.Text = tostring(self.player:GetAttribute("Forca") or 0)
	local carried = self.player:GetAttribute("Carregando") or 0
	local installed = self.player:GetAttribute("Instaladas") or 0
	self.BagBadge.Text = tostring(carried)
	self.BagBadge.Parent.Visible = carried > 0
	if self.sheetKind == "bag" then
		self.SheetBody.Text = string.format("Na bolsa     %d / 3\nNa base       %d / 3\nRenda          %d ouro / 5 s", carried, installed, self.player:GetAttribute("Renda") or 0)
	end
end

function HUD:SetEquipped(value)
	self.equipped = value
	self.ThrowButton.Visible = value and UserInputService.TouchEnabled and not self.capturing
	self.Reticle.Visible = value and UserInputService.TouchEnabled and not self.capturing
	if not value then self.ChargePanel.Visible = false end
	self:UpdateStats()
end

function HUD:SetCharging(power)
	self.ChargePanel.Visible = self.equipped and not self.capturing
	self.ChargeFill.Size = UDim2.fromScale(math.max(0.02, power), 1)
	self.ChargeText.Text = string.format("%d%%", math.floor(power * 100))
	self.ThrowButton.BackgroundColor3 = C.Ink:Lerp(C.Coral, power * 0.55)
end

function HUD:ThrowLaunched()
	self.ChargePanel.Visible = false
end

function HUD:ResetThrow()
	self.ChargePanel.Visible = false
	self.ThrowButton.BackgroundColor3 = C.Ink
end

function HUD:StartCapture(name, golden)
	self.capturing = true
	self:CloseSheet()
	self.CapturePanel.Visible = true
	self.ThrowButton.Visible = false
	self.Reticle.Visible = false
	self.ChargePanel.Visible = false
	self.CreatureName.Text = string.upper(name)
	self.CreatureName.TextColor3 = golden and C.Gold or C.White
	self.desired = {target = 0.5, zone = 0.5, progress = 0.16, overlap = false, timeLeft = 28, streak = 0}
	self.display = {target = 0.5, zone = 0.5, progress = 0.16}
end

function HUD:CaptureState(state)
	if self.capturing and typeof(state) == "table" then self.desired = state end
end

function HUD:SetHolding(value)
	self.HoldButton.Text = value and "PUXANDO" or "PUXAR"
	self.HoldButton.BackgroundColor3 = value and C.Gold or C.Rope
end

function HUD:EndCapture(success, message)
	self.capturing = false
	self.CapturePanel.Visible = false
	self.ThrowButton.Visible = self.equipped and UserInputService.TouchEnabled
	self.Reticle.Visible = self.equipped and UserInputService.TouchEnabled
	self:ResetThrow()
	if not success and message then self:Notice(message) end
end

function HUD:Notice(message)
	self.toastVersion += 1
	local version = self.toastVersion
	self.ToastText.Text = message
	self.Toast.Visible = true
	task.delay(2.5, function()
		if version == self.toastVersion then self.Toast.Visible = false end
	end)
end

function HUD:Reward(golden, message)
	self.rewardVersion += 1
	local version = self.rewardVersion
	self.RewardText.Text = message
	self.RewardText.TextColor3 = golden and C.Gold or C.White
	self.RewardText.Visible = true
	self.RewardScale.Scale = 0.25
	TweenService:Create(self.RewardScale, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	for i = 1, 8 do
		local spark = sprite(self.Gui, "Brilho", 2, UDim2.fromOffset(golden and 40 or 28, golden and 40 or 28), UDim2.fromScale(0.5, 0.25))
		spark.AnchorPoint = Vector2.new(0.5, 0.5)
		spark.ZIndex = 49
		local angle = i * math.pi / 4
		local distance = golden and 220 or 150
		TweenService:Create(spark, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(angle) * distance, 0.25, math.sin(angle) * distance * 0.5),
			ImageTransparency = 1,
		}):Play()
		task.delay(0.8, function() spark:Destroy() end)
	end
	task.delay(2.4, function()
		if version == self.rewardVersion then self.RewardText.Visible = false end
	end)
end

function HUD:_render(dt)
	if not self.capturing then return end
	local alpha = 1 - math.exp(-dt * 20)
	self.display.target += (self.desired.target - self.display.target) * alpha
	self.display.zone += (self.desired.zone - self.display.zone) * alpha
	self.display.progress += (self.desired.progress - self.display.progress) * (1 - math.exp(-dt * 12))
	local width = self.Track.AbsoluteSize.X
	self.Target.Position = UDim2.fromOffset(self.display.target * width - self.Target.AbsoluteSize.X / 2, 0)
	self.Zone.Position = UDim2.fromOffset(self.display.zone * width - self.Zone.AbsoluteSize.X / 2, 0)
	self.Zone.BackgroundColor3 = self.desired.overlap and C.Grass or C.Sky
	self.ProgressFill.Size = UDim2.fromScale(self.display.progress, 1)
	self.ProgressText.Text = string.format("%d%%", math.floor(self.display.progress * 100))
	self.TimerText.Text = string.format("%ds", math.max(0, math.ceil(self.desired.timeLeft or 0)))
	self.HoldButton.BackgroundColor3 = self.desired.overlap and C.Gold or C.Rope
end

return HUD
