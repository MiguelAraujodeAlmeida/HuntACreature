-- HUD v4. Orquestra apresentação; captura, valores e inventário continuam no servidor.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local Resources = require(script.Parent.ResourceHUD)
local Capture = require(script.Parent.CaptureHUD)
local QuickSlot = require(script.Parent.QuickSlot)
local S = W.Style
local HUD = {}
HUD.__index = HUD
local details = {
	Ouro = { "OURO", S.Icons.Coin, S.UI.Gold, "Suas criaturas instaladas geram ouro na base." },
	XP = { "EXPERIÊNCIA", S.Icons.XP, S.UI.Purple, "Suas criaturas instaladas geram experiência na base." },
	Forca = { "FORÇA", S.Icons.Strength, S.UI.Cyan, "O treino aumenta sua força com o laço." },
}
function HUD.new(player)
	local self = setmetatable(
		{ player = player, connections = {}, equipped = false, capturing = false, toastVersion = 0, rewardVersion = 0 },
		HUD
	)
	local gui = Instance.new("ScreenGui")
	gui.Name = "HuntACreatureGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	self.Gui = gui
	self.Resources = Resources.new(gui, function(kind)
		self:OpenSheet(kind)
	end)
	self.BagSkin = Button.new(
		gui,
		{
			name = "BolsaBotao",
			text = "Bolsa",
			icon = S.Icons.Bag,
			size = UDim2.fromOffset(146, 146),
			position = UDim2.new(0, 14, 0.34, 0),
			textSize = 29,
		}
	)
	self.BagButton = self.BagSkin.Root
	self.BagBadge = W.panel(self.BagButton, "Contagem", UDim2.fromOffset(48, 35), UDim2.new(1, -37, 0, -5), S.UI.Gold)
	self.BagBadge.ZIndex = 4
	self.BagCount = W.text(self.BagBadge, "Valor", "0/3", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 18)
	self.ThrowSkin = Button.new(
		gui,
		{
			name = "Arremessar",
			text = "Lançar",
			icon = S.Icons.Lasso,
			size = UDim2.fromOffset(120, 120),
			position = UDim2.new(1, -140, 0.46, 0),
			textSize = 25,
		}
	)
	self.ThrowButton = self.ThrowSkin.Root
	self.ThrowButton.Visible = false
	self.Slot = QuickSlot.new(player, gui, function()
		return self.capturing or self.sheetKind ~= nil or player:GetAttribute("Treinando")
	end)
	self.Reticle = W.frame(gui, "Mira", UDim2.fromOffset(24, 24), UDim2.new(0.5, -12, 0.5, -12))
	self.Reticle.Visible = false
	local ring = W.frame(self.Reticle, "Anel", UDim2.fromOffset(20, 20), UDim2.fromOffset(2, 2), nil, 10)
	W.stroke(ring, S.UI.White, 2)
	W.frame(self.Reticle, "Ponto", UDim2.fromOffset(4, 4), UDim2.fromOffset(10, 10), S.UI.Gold, 2)
	self.Capture = Capture.new(gui)
	self.HoldButton = self.Capture.Hold.Root
	self.CapturePanel = self.Capture.Root
	self.ChargePanel = self.Capture.Charge
	self.Shade = W.frame(gui, "FundoPainel", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), S.UI.Ink)
	self.Shade.BackgroundTransparency = 0.35
	self.Shade.Visible = false
	self.Shade.ZIndex = 20
	self.Shade.Active = true
	self.Sheet = W.panel(gui, "PainelInfo", UDim2.fromOffset(570, 320), UDim2.fromScale(0.5, 0.5), S.UI.Cyan)
	self.Sheet.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Sheet.ZIndex = 21
	self.Sheet.Visible = false
	self.SheetScale = Instance.new("UIScale")
	self.SheetScale.Parent = self.Sheet
	self.SheetIcon = W.icon(self.Sheet, "Icone", S.Icons.Bag, UDim2.fromOffset(104, 104), UDim2.fromOffset(20, -30))
	self.SheetTitle = W.text(self.Sheet, "Titulo", "BOLSA", UDim2.fromOffset(350, 56), UDim2.fromOffset(120, 9), 36)
	self.CloseSkin = Button.new(
		self.Sheet,
		{
			name = "Fechar",
			text = "×",
			color = S.UI.Red,
			size = UDim2.fromOffset(49, 49),
			position = UDim2.new(1, -59, 0, 9),
			textSize = 35,
			zIndex = 23,
		}
	)
	self.CloseButton = self.CloseSkin.Root
	self.BagContent = W.frame(self.Sheet, "Conteudo", UDim2.new(1, -42, 1, -93), UDim2.fromOffset(21, 74))
	self.BagSlots = {}
	for i = 1, 3 do
		local slot = W.panel(
			self.BagContent,
			"Espaco" .. i,
			UDim2.fromOffset(155, 120),
			UDim2.fromOffset((i - 1) * 173 + 12, 0),
			S.UI.Cyan
		)
		local icon = W.icon(slot, "Icone", S.Icons.Bag, UDim2.fromOffset(72, 72), UDim2.fromOffset(42, 9))
		local caption = W.text(slot, "Estado", "Livre", UDim2.fromOffset(145, 26), UDim2.fromOffset(5, 83), 20)
		self.BagSlots[i] = { icon = icon, caption = caption }
	end
	self.BagSummary = W.text(self.BagContent, "Resumo", "", UDim2.new(1, -20, 0, 36), UDim2.fromOffset(10, 133), 23)
	W.icon(self.BagContent, "RendaIcone", S.Icons.Coin, UDim2.fromOffset(43, 43), UDim2.fromOffset(102, 175))
	self.Income = W.text(
		self.BagContent,
		"Renda",
		"",
		UDim2.fromOffset(300, 38),
		UDim2.fromOffset(147, 176),
		24,
		S.UI.Gold,
		Enum.TextXAlignment.Left
	)
	self.DetailBody = W.text(self.Sheet, "Detalhes", "", UDim2.fromOffset(470, 170), UDim2.fromOffset(50, 102), 27)
	self.DetailBody.Visible = false
	self.Toast = W.panel(gui, "Aviso", UDim2.fromOffset(450, 64), UDim2.fromScale(0.5, 0.17), S.UI.Cyan)
	self.Toast.AnchorPoint = Vector2.new(0.5, 0)
	self.Toast.Visible = false
	self.Toast.ZIndex = 40
	self.ToastText = W.text(self.Toast, "Texto", "", UDim2.new(1, -35, 1, -14), UDim2.fromOffset(17, 7), 22)
	self.ToastScale = Instance.new("UIScale")
	self.ToastScale.Parent = self.Toast
	self.RewardRoot = W.panel(gui, "Vitoria", UDim2.fromOffset(550, 110), UDim2.fromScale(0.5, 0.27), S.UI.Gold)
	self.RewardRoot.AnchorPoint = Vector2.new(0.5, 0.5)
	self.RewardRoot.Visible = false
	self.RewardRoot.ZIndex = 45
	self.RewardScale = Instance.new("UIScale")
	self.RewardScale.Parent = self.RewardRoot
	W.icon(self.RewardRoot, "Estrela", S.Icons.XP, UDim2.fromOffset(108, 108), UDim2.fromOffset(-23, -7))
	W.text(self.RewardRoot, "Titulo", "CAPTUROU!", UDim2.fromOffset(410, 40), UDim2.fromOffset(88, 8), 32, S.UI.Gold)
	self.RewardText = W.text(self.RewardRoot, "Recompensa", "", UDim2.fromOffset(425, 48), UDim2.fromOffset(84, 48), 23)
	table.insert(
		self.connections,
		self.BagButton.Activated:Connect(function()
			if self.sheetKind == "bag" then
				self:CloseSheet()
			else
				self:OpenSheet("bag")
			end
		end)
	)
	table.insert(
		self.connections,
		self.CloseButton.Activated:Connect(function()
			self:CloseSheet()
		end)
	)
	table.insert(
		self.connections,
		UIS.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.ButtonB then
				self:CloseSheet()
			end
		end)
	)
	table.insert(
		self.connections,
		player.CharacterAdded:Connect(function()
			self:EndCapture(false)
			self:CloseSheet()
		end)
	)
	local function resize()
		self:Resize(workspace.CurrentCamera.ViewportSize)
	end
	resize()
	table.insert(self.connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize))
	table.insert(
		self.connections,
		RunService.RenderStepped:Connect(function(dt)
			self.Capture:Render(dt)
		end)
	)
	gui.Destroying:Connect(function()
		self.dead = true
		for _, c in ipairs(self.connections) do
			c:Disconnect()
		end
	end)
	return self
end
function HUD:Resize(view)
	self.view = view
	local compact = view.Y < 500 or view.X < 700
	self.Resources:Resize(view)
	self.Capture:Resize(view)
	local size = compact and 102 or 146
	self.BagButton.Size = UDim2.fromOffset(size, size)
	self.BagButton.Position = UDim2.new(0, 14, 0, compact and 130 or math.max(140, view.Y * 0.31))
	self.ThrowButton.Size = UDim2.fromOffset(compact and 96 or 120, compact and 96 or 120)
	self.ThrowButton.Position = UDim2.new(1, compact and -112 or -140, 0.46, 0)
	self.SheetScale.Scale = math.min(1, (view.X - 30) / 570, (view.Y - 40) / 320)
	self.ToastScale.Scale = math.min(1, (view.X - 24) / 450)
	self.RewardBaseScale = math.min(1, (view.X - 30) / 550)
	self.RewardScale.Scale = self.RewardBaseScale
end
function HUD:OpenSheet(kind)
	if self.capturing then
		return
	end
	self.sheetKind = kind
	self.Shade.Visible = true
	self.Sheet.Visible = true
	self.BagContent.Visible = kind == "bag"
	self.DetailBody.Visible = kind ~= "bag"
	self.BagSkin:SetSelected(kind == "bag")
	if kind == "bag" then
		self.SheetIcon.Image = S.Icons.Bag
		self.SheetTitle.Text = "BOLSA"
		self.Sheet.ImageColor3 = S.UI.Cyan
	else
		local data = details[kind]
		if not data then
			self:CloseSheet()
			return
		end
		self.SheetTitle.Text = data[1]
		self.SheetIcon.Image = data[2]
		self.Sheet.ImageColor3 = data[3]
		self.DetailBody.Text = data[4]
	end
	self:UpdateStats()
end
function HUD:CloseSheet()
	self.sheetKind = nil
	self.Shade.Visible = false
	self.Sheet.Visible = false
	self.BagSkin:SetSelected(false)
end
function HUD:UpdateStats()
	local stats = self.player:FindFirstChild("leaderstats")
	local gold = stats and stats:FindFirstChild("Ouro")
	local xp = stats and stats:FindFirstChild("XP")
	self.Resources:Update(gold and gold.Value or 0, xp and xp.Value or 0, self.player:GetAttribute("Forca") or 0)
	local carried = self.player:GetAttribute("Carregando") or 0
	local installed = self.player:GetAttribute("Instaladas") or 0
	self.BagCount.Text = string.format("%d/3", carried)
	for i, slot in ipairs(self.BagSlots) do
		slot.icon.ImageTransparency = i <= carried and 0 or 0.8
		slot.caption.Text = i <= carried and "Ocupado" or "Livre"
	end
	self.BagSummary.Text = string.format("Na bolsa: %d/3   •   Na base: %d/3", carried, installed)
	self.Income.Text = string.format("%d ouro / 5 s", self.player:GetAttribute("Renda") or 0)
end
function HUD:SetEquipped(value)
	self.equipped = value
	self.Slot:SetEquipped(value)
	self.ThrowButton.Visible = value and UIS.TouchEnabled and not self.capturing
	self.Reticle.Visible = value and UIS.TouchEnabled and not self.capturing
	if not value then
		self:ResetThrow()
	end
end
function HUD:SetCharging(power)
	self.ChargePanel.Visible = self.equipped and not self.capturing
	self.Capture:SetCharging(power)
	self.ThrowSkin:SetHeld(true)
	self.ThrowSkin:SetSelected(power >= 1)
end
function HUD:ResetThrow()
	self.ChargePanel.Visible = false
	self.ThrowSkin:SetHeld(false)
	self.ThrowSkin:SetSelected(false)
end
function HUD:ThrowLaunched()
	self:ResetThrow()
end
function HUD:StartCapture(name, golden)
	self.capturing = true
	self:CloseSheet()
	self:ResetThrow()
	self.Capture:Reset()
	self.CapturePanel.Visible = true
	self.Capture.Name.Text = name
	self.Capture.Name.TextColor3 = golden and S.UI.Gold or S.UI.White
	self.ThrowButton.Visible = false
	self.Reticle.Visible = false
	self:SetHolding(false)
end
function HUD:CaptureState(state)
	if self.capturing and typeof(state) == "table" then
		self.Capture.desired = state
	end
end
function HUD:SetHolding(value)
	self.Capture:SetHolding(value)
end
function HUD:EndCapture(success, message)
	self.capturing = false
	self:SetHolding(false)
	self.Capture.Hold:SetSelected(false)
	self.CapturePanel.Visible = false
	self:SetEquipped(self.equipped)
	self:ResetThrow()
	if not success and message then
		self:Notice(message)
	end
end
function HUD:Notice(message)
	self.toastVersion += 1
	local version = self.toastVersion
	self.ToastText.Text = message
	self.Toast.Visible = true
	task.delay(2.5, function()
		if not self.dead and version == self.toastVersion then
			self.Toast.Visible = false
		end
	end)
end
function HUD:Reward(golden, message)
	self.rewardVersion += 1
	local version = self.rewardVersion
	self.RewardText.Text = message
	self.RewardRoot.Visible = true
	self.RewardScale.Scale = 0.35 * self.RewardBaseScale
	TweenService:Create(
		self.RewardScale,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = self.RewardBaseScale }
	):Play()
	for i = 1, 10 do
		local spark = W.icon(
			self.Gui,
			"EstrelaVitoria",
			S.Icons.XP,
			UDim2.fromOffset(golden and 48 or 34, golden and 48 or 34),
			UDim2.fromScale(0.5, 0.27)
		)
		spark.AnchorPoint = Vector2.new(0.5, 0.5)
		spark.ZIndex = 44
		local angle = i * math.pi / 5
		local distance = golden and 260 or 205
		TweenService:Create(
			spark,
			TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.new(0.5, math.cos(angle) * distance, 0.27, math.sin(angle) * distance * 0.48),
				Rotation = i % 2 == 0 and 80 or -80,
				ImageTransparency = 1,
			}
		):Play()
		task.delay(0.9, function()
			spark:Destroy()
		end)
	end
	self.BagSkin:Shine()
	task.delay(2.5, function()
		if not self.dead and version == self.rewardVersion then
			self.RewardRoot.Visible = false
		end
	end)
end
return HUD
