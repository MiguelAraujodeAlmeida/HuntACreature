-- Interface apenas. Não decide acertos, alcance ou recursos.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Style = require(game:GetService("ReplicatedStorage").HACShared.VisualStyle)
local C = Style.Colors

local HUD = {}
HUD.__index = HUD

local function round(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or Style.Corner)
	corner.Parent = parent
end

local function outline(parent, width)
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.Ink
	stroke.Thickness = width or Style.Outline
	stroke.Parent = parent
end

local function box(parent, name, size, position, color, radius)
	local object = Instance.new("Frame")
	object.Name = name
	object.Size = size
	object.Position = position
	object.BorderSizePixel = 0
	object.BackgroundColor3 = color
	object.Parent = parent
	round(object, radius)
	return object
end

local function label(parent, name, value, size, position, color, fontSize, centered)
	local object = Instance.new("TextLabel")
	object.Name = name
	object.Size = size
	object.Position = position
	object.BackgroundTransparency = 1
	object.Text = value
	object.TextColor3 = color
	object.TextStrokeColor3 = C.Ink
	object.TextStrokeTransparency = color == C.Ink and 1 or 0
	object.TextSize = fontSize
	object.Font = Style.Font
	object.TextWrapped = true
	object.TextXAlignment = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
	object.Parent = parent
	return object
end

local function button(parent, name, value, size, position, color, fontSize)
	local shadow = box(parent, name .. "Sombra", size, position + UDim2.fromOffset(4, 5), C.Ink, 12)
	shadow.ZIndex = 1
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = value
	b.TextColor3 = C.White
	b.TextStrokeColor3 = C.Ink
	b.TextStrokeTransparency = 0
	b.TextSize = fontSize
	b.Font = Style.Font
	b.AutoButtonColor = true
	b.ZIndex = 2
	b.Parent = parent
	round(b, 12)
	outline(b, 3)
	return b, shadow
end

local function stat(parent, name, color, y)
	local f = box(parent, name, UDim2.fromOffset(177, 42), UDim2.fromOffset(18, y), color, 10)
	outline(f, 3)
	local t = label(f, "Valor", "", UDim2.new(1, -18, 1, 0), UDim2.fromOffset(9, 0), C.White, 22, false)
	return f, t
end

function HUD.new(player)
	local self = setmetatable({}, HUD)
	local gui = Instance.new("ScreenGui")
	gui.Name = "HuntACreatureGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = player:WaitForChild("PlayerGui")
	self.Gui = gui
	self.player = player

	local titleShadow = box(gui, "MarcaSombra", UDim2.fromOffset(312, 53), UDim2.new(0.5, -152, 0, 17), C.Ink, 14)
	titleShadow.ZIndex = 1
	local title = box(gui, "Marca", UDim2.fromOffset(312, 53), UDim2.new(0.5, -156, 0, 12), C.Sky, 14)
	title.ZIndex = 2
	outline(title, 3)
	label(title, "Nome", "HUNT A CREATURE", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.White, 27, true).ZIndex = 3

	local bag, bagShadow = button(gui, "BolsaBotao", "◈  BOLSA", UDim2.fromOffset(158, 54), UDim2.new(0, 18, 0.41, 0), C.Sky, 22)
	local guide, guideShadow = button(gui, "GuiaBotao", "?  GUIA", UDim2.fromOffset(158, 54), UDim2.new(0, 18, 0.41, 68), C.Sun, 22)
	self.BagButton = bag
	self.GuideButton = guide
	self.LeftShadows = {bagShadow, guideShadow}
	local _, goldText = stat(gui, "Ouro", C.DeepGrass, 0)
	local _, xpText = stat(gui, "XP", C.Purple, 46)
	local _, forceText = stat(gui, "Forca", C.Orange, 92)
	local statsAnchor = box(gui, "Estatisticas", UDim2.fromOffset(1, 1), UDim2.new(0, 0, 1, -160), C.White)
	statsAnchor.BackgroundTransparency = 1
	for _, name in ipairs({"Ouro", "XP", "Forca"}) do
		local item = gui:FindFirstChild(name)
		if item then item.Parent = statsAnchor end
	end
	self.GoldText = goldText
	self.XPText = xpText
	self.ForceText = forceText

	local hint = box(gui, "Dica", UDim2.fromOffset(545, 43), UDim2.new(0.5, -272, 1, -57), C.Ink, 12)
	hint.BackgroundTransparency = 0.08
	self.Hint = label(hint, "Texto", "Equipe o laço e atravesse a ponte para caçar.", UDim2.new(1, -22, 1, 0), UDim2.fromOffset(11, 0), C.White, 17, true)

	local status = box(gui, "StatusLaco", UDim2.fromOffset(196, 42), UDim2.new(1, -214, 1, -201), C.Ink, 12)
	self.Status = label(status, "Texto", "EQUIPE O LAÇO", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.White, 19, true)
	local charge = box(gui, "ForcaArremesso", UDim2.fromOffset(196, 48), UDim2.new(1, -214, 1, -153), C.Ink, 12)
	charge.Visible = false
	local chargeBack = box(charge, "Trilha", UDim2.fromOffset(178, 18), UDim2.fromOffset(9, 24), C.White, 7)
	self.ChargeFill = box(chargeBack, "Barra", UDim2.fromScale(0.04, 1), UDim2.fromScale(0, 0), C.Sky, 7)
	self.ChargeText = label(charge, "Texto", "FORÇA 0%", UDim2.fromOffset(180, 21), UDim2.fromOffset(9, 1), C.White, 17, true)
	self.ChargePanel = charge
	local throw, throwShadow = button(gui, "Arremessar", "SEGURE PARA\nLANÇAR", UDim2.fromOffset(196, 84), UDim2.new(1, -214, 1, -98), C.Coral, 24)
	self.ThrowButton = throw
	self.ThrowShadow = throwShadow
	throw.Visible = false
	throwShadow.Visible = false
	local reticle = label(gui, "Mira", "+", UDim2.fromOffset(38, 38), UDim2.new(0.5, -19, 0.5, -19), C.White, 37, true)
	reticle.Visible = false
	self.Reticle = reticle

	local shade = box(gui, "FundoPainel", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.Ink, 0)
	shade.BackgroundTransparency = 0.35
	shade.Visible = false
	shade.ZIndex = 20
	self.Shade = shade
	local sheet = box(gui, "PainelInfo", UDim2.fromOffset(360, 245), UDim2.new(0.5, -180, 0.5, -122), C.White, 18)
	sheet.AnchorPoint = Vector2.new(0.5, 0.5)
	sheet.Position = UDim2.fromScale(0.5, 0.5)
	sheet.Visible = false
	sheet.ZIndex = 21
	outline(sheet, 4)
	self.Sheet = sheet
	local sheetTitle = label(sheet, "Titulo", "", UDim2.fromOffset(310, 46), UDim2.fromOffset(19, 12), C.Ink, 27, false)
	sheetTitle.ZIndex = 22
	self.SheetTitle = sheetTitle
	local sheetBody = label(sheet, "Corpo", "", UDim2.fromOffset(316, 147), UDim2.fromOffset(20, 64), C.Ink, 21, false)
	sheetBody.ZIndex = 22
	self.SheetBody = sheetBody
	local close = button(sheet, "Fechar", "X", UDim2.fromOffset(42, 42), UDim2.new(1, -51, 0, 8), C.Coral, 22)
	close.ZIndex = 23
	self.CloseButton = close
	close.Activated:Connect(function() self:CloseSheet() end)
	bag.Activated:Connect(function() self:OpenSheet("bag") end)
	guide.Activated:Connect(function() self:OpenSheet("guide") end)

	local capture = box(gui, "Captura", UDim2.fromOffset(395, 320), UDim2.new(0.5, -197, 0.5, -160), C.White, 20)
	capture.AnchorPoint = Vector2.new(0.5, 0.5)
	capture.Position = UDim2.fromScale(0.5, 0.5)
	capture.Visible = false
	capture.ZIndex = 30
	outline(capture, 4)
	self.CapturePanel = capture
	local captureScale = Instance.new("UIScale")
	captureScale.Parent = capture
	local sheetScale = Instance.new("UIScale")
	sheetScale.Parent = sheet
	local function resize()
		local width = workspace.CurrentCamera.ViewportSize.X
		local height = workspace.CurrentCamera.ViewportSize.Y
		captureScale.Scale = math.min(1, math.max(0.72, width / 430))
		sheetScale.Scale = math.min(1, math.max(0.72, width / 395))
		local compact = width < 650 or height < 500
		bag.Size = UDim2.fromOffset(compact and 126 or 158, 54)
		guide.Size = UDim2.fromOffset(compact and 126 or 158, 54)
		bag.TextSize = compact and 19 or 22
		guide.TextSize = compact and 19 or 22
		for _, shadow in ipairs(self.LeftShadows) do shadow.Size = UDim2.fromOffset(compact and 126 or 158, 54) end
		bag.Position = compact and UDim2.fromOffset(18, 112) or UDim2.new(0, 18, 0.41, 0)
		guide.Position = compact and UDim2.fromOffset(151, 112) or UDim2.new(0, 18, 0.41, 68)
		self.LeftShadows[1].Position = bag.Position + UDim2.fromOffset(4, 5)
		self.LeftShadows[2].Position = guide.Position + UDim2.fromOffset(4, 5)
		hint.Visible = not compact
		hint.Size = UDim2.fromOffset(545, 43)
		hint.Position = UDim2.new(0.5, -272, 1, -57)
		statsAnchor.Position = compact and UDim2.fromOffset(0, 65) or UDim2.new(0, 0, 1, -160)
		for i, textObject in ipairs({self.GoldText, self.XPText, self.ForceText}) do
			local statBox = textObject.Parent
			statBox.Size = UDim2.fromOffset(compact and 112 or 177, compact and 34 or 42)
			statBox.Position = compact and UDim2.fromOffset(12 + (i - 1) * 117, 0) or UDim2.fromOffset(18, (i - 1) * 46)
			textObject.TextSize = compact and 15 or 22
			textObject.TextScaled = compact
		end
		status.Position = compact and UDim2.new(1, -208, 0, 68) or UDim2.new(1, -214, 1, -201)
		charge.Position = compact and UDim2.new(1, -208, 0, 68) or UDim2.new(1, -214, 1, -153)
		charge.Size = UDim2.fromOffset(196, compact and 42 or 48)
		throw.Position = compact and UDim2.new(1, -208, 0, 114) or UDim2.new(1, -214, 1, -98)
		throw.Size = UDim2.fromOffset(196, compact and 52 or 84)
		throw.TextSize = compact and 18 or 24
		throwShadow.Position = throw.Position + UDim2.fromOffset(4, compact and 4 or 5)
		throwShadow.Size = throw.Size
	end
	resize()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	label(capture, "Titulo", "DOMINE O LAÇO!", UDim2.fromOffset(360, 40), UDim2.fromOffset(18, 9), C.Ink, 30, true).ZIndex = 31
	self.CreatureName = label(capture, "Criatura", "LUMITO", UDim2.fromOffset(350, 30), UDim2.fromOffset(23, 49), C.Purple, 22, true)
	self.CreatureName.ZIndex = 31
	local track = box(capture, "Trilha", UDim2.fromOffset(76, 199), UDim2.fromOffset(25, 91), C.Ink, 12)
	track.ZIndex = 31
	track.ClipsDescendants = true
	self.Track = track
	local inner = box(track, "Interior", UDim2.new(1, -12, 1, -12), UDim2.fromOffset(6, 6), C.Sky, 8)
	inner.ZIndex = 32
	local zone = box(track, "Zona", UDim2.new(1, -6, 0, 58), UDim2.new(0, 3, 0.5, -29), C.Grass, 8)
	zone.ZIndex = 33
	zone.BackgroundTransparency = 0.16
	self.Zone = zone
	local target = box(track, "Alvo", UDim2.new(1, -13, 0, 16), UDim2.new(0, 6, 0.5, -8), C.Gold, 8)
	target.ZIndex = 34
	outline(target, 2)
	self.Target = target
	local instruction = label(capture, "Instrucao", "SEGURE para subir.\nSOLTE para descer.\nMantenha o alvo na faixa!", UDim2.fromOffset(265, 90), UDim2.fromOffset(117, 90), C.Ink, 20, false)
	instruction.ZIndex = 31
	self.ProgressText = label(capture, "Progresso", "CAPTURA 16%", UDim2.fromOffset(255, 30), UDim2.fromOffset(118, 184), C.Ink, 21, false)
	self.ProgressText.ZIndex = 31
	local progressBack = box(capture, "ProgressoFundo", UDim2.fromOffset(252, 20), UDim2.fromOffset(118, 218), C.Ink, 9)
	progressBack.ZIndex = 31
	self.ProgressFill = box(progressBack, "Barra", UDim2.fromScale(0.16, 1), UDim2.fromScale(0, 0), C.Grass, 9)
	self.ProgressFill.ZIndex = 32
	local hold = button(capture, "SegurarLaco", "SEGURAR O LAÇO", UDim2.fromOffset(252, 53), UDim2.fromOffset(118, 250), C.Orange, 21)
	hold.ZIndex = 32
	self.HoldButton = hold

	local toast = box(gui, "Aviso", UDim2.fromOffset(440, 54), UDim2.new(0.5, -220, 0, 83), C.Sun, 14)
	toast.Visible = false
	toast.ZIndex = 40
	outline(toast, 3)
	self.Toast = toast
	self.ToastText = label(toast, "Texto", "", UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), C.Ink, 20, true)
	self.ToastText.ZIndex = 41
	local function resizeToast()
		local viewportWidth = workspace.CurrentCamera.ViewportSize.X
		local compact = viewportWidth < 650 or workspace.CurrentCamera.ViewportSize.Y < 500
		local width = math.min(compact and 320 or 440, viewportWidth - 24)
		toast.Size = UDim2.fromOffset(width, 54)
		toast.Position = UDim2.new(0.5, -width / 2, 0, compact and 112 or 83)
	end
	resizeToast()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeToast)
	local reward = label(gui, "Recompensa", "", UDim2.fromOffset(650, 90), UDim2.new(0.5, -325, 0.21, 0), C.Gold, 48, true)
	reward.AnchorPoint = Vector2.new(0.5, 0.5)
	reward.Position = UDim2.fromScale(0.5, 0.24)
	reward.Visible = false
	reward.ZIndex = 50
	self.RewardText = reward
	self.RewardScale = Instance.new("UIScale")
	self.RewardScale.Parent = reward
	self.toastVersion = 0
	self.rewardVersion = 0
	self.equipped = false
	self.capturing = false
	self.charge = 0
	self.desired = {target = 0.5, zone = 0.5, progress = 0.16, overlap = false}
	self.display = {target = 0.5, zone = 0.5, progress = 0.16}
	self.renderConnection = RunService.RenderStepped:Connect(function(dt) self:_render(dt) end)
	return self
end

function HUD:OpenSheet(kind)
	self.Shade.Visible = true
	self.Sheet.Visible = true
	self.sheetKind = kind
	self:UpdateStats()
end

function HUD:CloseSheet()
	self.Shade.Visible = false
	self.Sheet.Visible = false
	self.sheetKind = nil
end

function HUD:UpdateStats()
	local stats = self.player:FindFirstChild("leaderstats")
	local gold = stats and stats:FindFirstChild("Ouro")
	local xp = stats and stats:FindFirstChild("XP")
	self.GoldText.Text = "●  " .. (gold and gold.Value or 0) .. " OURO"
	self.XPText.Text = "✦  " .. (xp and xp.Value or 0) .. " XP"
	self.ForceText.Text = "◆  " .. (self.player:GetAttribute("Forca") or 0) .. " FORÇA"
	local carried = self.player:GetAttribute("Carregando") or 0
	local installed = self.player:GetAttribute("Instaladas") or 0
	if self.sheetKind == "bag" then
		self.SheetTitle.Text = "SUA COLEÇÃO"
		self.SheetBody.Text = "NA BOLSA   " .. carried .. "/3\nNA BASE     " .. installed .. "/3\nRENDA       " .. (self.player:GetAttribute("Renda") or 0) .. " ouro / 5 s"
	elseif self.sheetKind == "guide" then
		self.SheetTitle.Text = "COMO CAÇAR"
		self.SheetBody.Text = "1  Equipe o laço.\n2  Mire e segure para ganhar força.\n3  Solte para lançar; acerte um Lumito.\n4  Controle a faixa e instale na base."
	end
	if self.player:GetAttribute("Treinando") then
		self.Hint.Text = "Treinando... fique perto da esteira."
	elseif carried > 0 then
		self.Hint.Text = "Lumito na bolsa! Volte ao totem da sua base."
	else
		self.Hint.Text = self.equipped and "Mire e segure para carregar o laço." or "Equipe o laço e atravesse a ponte para caçar."
	end
end

function HUD:SetEquipped(value)
	self.equipped = value
	self.ThrowButton.Visible = value and not self.capturing
	self.ThrowShadow.Visible = self.ThrowButton.Visible
	self.Reticle.Visible = value and not self.capturing
	self.Status.Text = value and "LAÇO PRONTO" or "EQUIPE O LAÇO"
	if not value then self.ChargePanel.Visible = false end
	self:UpdateStats()
end

function HUD:SetCharging(power)
	self.charge = power
	self.ChargePanel.Visible = self.equipped and not self.capturing
	self.ChargeFill.Size = UDim2.fromScale(math.max(0.04, power), 1)
	self.ChargeFill.BackgroundColor3 = C.Sky:Lerp(C.Gold, power)
	self.ChargeText.Text = "FORÇA " .. math.floor(power * 100) .. "%"
	self.ThrowButton.BackgroundColor3 = C.Coral:Lerp(C.Orange, power)
	self.Status.Text = power > 0 and "SOLTE PARA LANÇAR" or "LAÇO PRONTO"
end

function HUD:ThrowLaunched()
	self.ChargePanel.Visible = false
	self.Status.Text = "LAÇO NO AR!"
end

function HUD:ResetThrow()
	self.ChargePanel.Visible = false
	self.Status.Text = self.equipped and "LAÇO PRONTO" or "EQUIPE O LAÇO"
	self.ThrowButton.BackgroundColor3 = C.Coral
end

function HUD:StartCapture(name, golden)
	self.capturing = true
	self:CloseSheet()
	self.CapturePanel.Visible = true
	self.ThrowButton.Visible = false
	self.ThrowShadow.Visible = false
	self.Reticle.Visible = false
	self.ChargePanel.Visible = false
	self.Status.Text = "CONTROLE O LAÇO"
	self.CreatureName.Text = string.upper(name)
	self.CreatureName.TextColor3 = golden and C.Gold or C.Purple
	self.desired = {target = 0.5, zone = 0.5, progress = 0.16, overlap = false}
	self.display = {target = 0.5, zone = 0.5, progress = 0.16}
end

function HUD:CaptureState(state)
	if not self.capturing or typeof(state) ~= "table" then return end
	self.desired = state
end

function HUD:EndCapture(success, message)
	self.capturing = false
	self.CapturePanel.Visible = false
	self.ThrowButton.Visible = self.equipped
	self.ThrowShadow.Visible = self.equipped
	self.Reticle.Visible = self.equipped
	self.Status.Text = "LAÇO PRONTO"
	self:Notice(message, success and C.Grass or C.Sun)
end

function HUD:Notice(message, color)
	self.toastVersion += 1
	local version = self.toastVersion
	self.Toast.BackgroundColor3 = color or C.Sun
	self.ToastText.Text = message
	self.Toast.Visible = true
	task.delay(3.2, function()
		if version == self.toastVersion then self.Toast.Visible = false end
	end)
end

function HUD:Reward(golden, message)
	self.rewardVersion += 1
	local version = self.rewardVersion
	self.RewardText.Text = message
	self.RewardText.TextColor3 = golden and C.Gold or C.Sky
	self.RewardText.Visible = true
	local fullScale = math.min(1, workspace.CurrentCamera.ViewportSize.X / 700)
	self.RewardScale.Scale = fullScale * 0.35
	TweenService:Create(self.RewardScale, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = fullScale}):Play()
	task.delay(2.2, function()
		if version == self.rewardVersion then self.RewardText.Visible = false end
	end)
end

function HUD:_render(dt)
	if not self.capturing then return end
	local alpha = 1 - math.exp(-dt * 18)
	local progressAlpha = 1 - math.exp(-dt * 12)
	self.display.target += (self.desired.target - self.display.target) * alpha
	self.display.zone += (self.desired.zone - self.display.zone) * alpha
	self.display.progress += (self.desired.progress - self.display.progress) * progressAlpha
	self.Target.Position = UDim2.new(0, 6, 1 - self.display.target, -8)
	self.Zone.Position = UDim2.new(0, 3, 1 - self.display.zone, -29)
	self.Zone.BackgroundColor3 = self.desired.overlap and C.Grass or C.Orange
	self.ProgressFill.Size = UDim2.fromScale(self.display.progress, 1)
	self.ProgressText.Text = "CAPTURA " .. math.floor(self.display.progress * 100) .. "%"
end

return HUD
