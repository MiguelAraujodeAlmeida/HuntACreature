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
local Effects = require(script.Parent.UIEffects)
local Layout = require(script.Parent.HUDLayout)
local Audio = require(script.Parent.AudioFeedback)
local GuiService = game:GetService("GuiService")
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
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ClipToDeviceSafeArea = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	self.Gui = gui
	Audio.Init()
	local surface = W.frame(gui, "AreaSegura", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0))
	self.Surface = surface
	gui = surface
	self.Resources = Resources.new(gui, function(kind)
		self:OpenSheet(kind)
	end)
	self.BagSkin = Button.new(gui, {
		name = "BolsaBotao",
		text = "Bolsa",
		icon = S.Icons.Bag,
		size = UDim2.fromOffset(146, 146),
		position = UDim2.new(0, 14, 0.34, 0),
		textSize = 29,
	})
	self.BagButton = self.BagSkin.Root
	self.BagSkin.caption:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize = 23
	self.BagBadge = W.panel(self.BagButton, "Contagem", UDim2.fromOffset(40, 29), UDim2.new(1, -32, 0, -3), S.UI.Gold)
	self.BagBadge.ZIndex = 4
	self.BagCount = W.text(self.BagBadge, "Valor", "0/3", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 18)
	self.IndexSkin = Button.new(gui, {name = "IndexBotao", text = "Index", color = S.UI.Purple,
		size = UDim2.fromOffset(86,44), position = UDim2.new(), textSize = 20})
	self.SpeedSkin = Button.new(gui, {name = "VelocidadeBotao", text = "Velocidade", color = S.UI.Green,
		size = UDim2.fromOffset(86,40), position = UDim2.new(), textSize = 14})
	self.IndexSkin.Root.Activated:Connect(function()
		if self.Collection then self.Collection:Open("Index") end
	end)
	self.SpeedSkin.Root.Activated:Connect(function()
		if self.Collection then self.Collection:Open("Melhorias","Velocidade") end
	end)
	self.ThrowSkin = Button.new(gui, {
		name = "Arremessar",
		text = "Lançar",
		icon = S.Icons.Lasso,
		size = UDim2.fromOffset(120, 120),
		position = UDim2.new(1, -140, 0.46, 0),
		textSize = 25,
		sound = false,
	})
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
	self.CloseSkin = Button.new(self.Sheet, {
		name = "Fechar",
		text = "×",
		color = S.UI.Red,
		size = UDim2.fromOffset(49, 49),
		position = UDim2.new(1, -59, 0, 9),
		textSize = 35,
		zIndex = 23,
	})
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
		self.BagSlots[i] = { root = slot, icon = icon, caption = caption }
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
		local view = self.Surface.AbsoluteSize
		if view.X > 0 and view.Y > 0 then self:Resize(view) end
	end
	table.insert(self.connections, surface:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	table.insert(self.connections, UIS:GetPropertyChangedSignal("TouchEnabled"):Connect(resize))
	resize()
	task.defer(function() if not self.dead then resize() end end)
	table.insert(
		self.connections,
		RunService.RenderStepped:Connect(function(dt)
			self.Capture:Render(dt)
		end)
	)
	gui.Destroying:Connect(function()
		self.dead = true
		Audio.Destroy()
		for _, c in ipairs(self.connections) do
			c:Disconnect()
		end
	end)
	return self
end
function HUD:Resize(view)
	self.view = view
	local layout = Layout.Resolve(view, UIS.TouchEnabled)
	self.layout = layout
	self.Resources:Resize(layout)
	self.Capture:Resize(layout)
	local margin = layout.margin
	self.BagButton.Size = UDim2.fromOffset(layout.bag, layout.bag)
	local bagY = layout.desktop and math.max(margin, view.Y - 3 * (layout.resourceHeight + 8) - layout.bag - 28)
		or margin + layout.resourceHeight + 14
	self.BagButton.Position = layout.narrow and UDim2.new(1, -margin - layout.bag, 0, margin + 5)
		or UDim2.fromOffset(margin, bagY)
	local navWidth=math.max(76,layout.bag)
	self.IndexSkin.Root.Size=UDim2.fromOffset(navWidth,44)
	self.SpeedSkin.Root.Size=UDim2.fromOffset(navWidth,40)
	if layout.narrow then
		local y=margin+5+layout.bag+6
		self.IndexSkin.Root.Position=UDim2.new(1,-margin-navWidth,0,y)
		self.SpeedSkin.Root.Position=UDim2.new(1,-margin-navWidth,0,y+48)
	elseif layout.desktop then
		self.IndexSkin.Root.Position=UDim2.fromOffset(margin,bagY-50)
		self.SpeedSkin.Root.Position=UDim2.fromOffset(margin,bagY-94)
	else
		self.IndexSkin.Root.Position=UDim2.fromOffset(margin+layout.bag+8,bagY)
		self.SpeedSkin.Root.Position=UDim2.fromOffset(margin+layout.bag+navWidth+16,bagY)
	end
	self.BagBadge.Size = UDim2.fromOffset(32, 24)
	self.BagBadge.Position = UDim2.new(1, -29, 0, 0)
	self.BagCount.TextSize = 14
	local throwSize = layout.short and 68 or 80
	self.ThrowButton.Size = UDim2.fromOffset(throwSize, throwSize)
	self.ThrowButton.Position = UDim2.new(1, -margin - throwSize, 0, math.max(margin + layout.resourceHeight + 12, view.Y - 160 - throwSize))
	self.Slot.Root.Size = UDim2.fromOffset(layout.slot, layout.slot)
	self.Slot.Root.Position = UDim2.new(0.5, 0, 1, -margin)
	local width = math.min(570, view.X - margin * 2)
	local height = math.min(310, view.Y - margin * 2)
	self.Sheet.Size = UDim2.fromOffset(width, height)
	if self.sheetTween then self.sheetTween:Cancel() end
	self.SheetScale.Scale = 1
	self.SheetIcon.Size = UDim2.fromOffset(54, 54)
	self.SheetIcon.Position = UDim2.fromOffset(12, 6)
	self.SheetTitle.Position = UDim2.fromOffset(70, 14)
	self.SheetTitle.Size = UDim2.fromOffset(width - 136, 32)
	self.SheetTitle.TextScaled = true
	self.SheetTitle.Visible = true
	self.CloseButton.Size = UDim2.fromOffset(46, 46)
	self.CloseButton.Position = UDim2.new(1, -56, 0, 9)
	self.BagContent.Position = UDim2.fromOffset(16, 66)
	self.BagContent.Size = UDim2.new(1, -32, 1, -76)
	local slotWidth = (width - 56) / 3
	local slotHeight = math.min(116, height - 150)
	for i, item in ipairs(self.BagSlots) do
		item.root.Size = UDim2.fromOffset(slotWidth, slotHeight)
		item.root.Position = UDim2.fromOffset((i - 1) * (slotWidth + 12), 0)
		local iconSize = math.max(8, math.min(64, slotWidth - 14, slotHeight - 32))
		item.icon.Size = UDim2.fromOffset(iconSize, iconSize)
		item.icon.Position = UDim2.new(0.5, -iconSize / 2, 0, 6)
		item.caption.Position = UDim2.new(0, 4, 1, -27)
		item.caption.Size = UDim2.new(1, -8, 0, 24)
		item.caption.TextSize = 16
	end
	self.BagSummary.Position = UDim2.fromOffset(0, slotHeight + 6)
	self.BagSummary.Size = UDim2.new(1, 0, 0, 28)
	self.BagSummary.TextSize = width < 420 and 15 or 20
	self.BagContent.RendaIcone.Size = UDim2.fromOffset(28, 28)
	self.BagContent.RendaIcone.Position = UDim2.new(0.5, -104, 0, slotHeight + 36)
	self.Income.Position = UDim2.new(0.5, -70, 0, slotHeight + 36)
	self.Income.Size = UDim2.fromOffset(180, 28)
	self.Income.TextSize = 18
	self.DetailBody.Position = UDim2.fromOffset(22, 80)
	self.DetailBody.Size = UDim2.new(1, -44, 1, -100)
	self.DetailBody.TextSize = width < 420 and 19 or 24
	self.Toast.Size = UDim2.fromOffset(math.min(450, view.X - margin * 2), 58)
	self.Toast.Position = UDim2.new(0.5, 0, 0, margin + layout.resourceHeight + 8)
	self.ToastText.TextSize = layout.short and 16 or 20
	self.ToastScale.Scale = 1
	self.RewardBaseScale = math.min(1, (view.X - margin * 2) / 550)
	self.RewardScale.Scale = self.RewardBaseScale
	self.RewardRoot.Position = UDim2.fromScale(0.5, layout.short and 0.38 or 0.3)
	-- A mira representa o centro da câmera, não o centro da área abaixo da topbar.
	local camera = workspace.CurrentCamera
	if camera then
		local inset = GuiService:GetGuiInset()
		self.Reticle.Position = UDim2.fromOffset(camera.ViewportSize.X / 2 - inset.X - 12, camera.ViewportSize.Y / 2 - inset.Y - 12)
	end
	if self.Collection then self.Collection:Resize() end
end
function HUD:OpenSheet(kind)
	if kind == "bag" and self.Collection then self.Collection:Open("Bolsa"); return end
	if self.Collection then self.Collection:Close() end
	if self.capturing then
		return
	end
	self.sheetKind = kind
	local scale = 1
	Audio.Play("Open")
	if self.sheetTween then
		self.sheetTween:Cancel()
	end
	self.SheetScale.Scale = scale * 0.92
	self.sheetTween = TweenService:Create(
		self.SheetScale,
		TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = scale }
	)
	self.sheetTween:Play()
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
	if self.Collection then self.Collection:Close() end
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
	local bagCapacity = self.player:GetAttribute("BagCapacity") or 3
	local baseCapacity = self.player:GetAttribute("BaseCapacity") or 3
	self.BagCount.Text = string.format("%d/%d", carried, bagCapacity)
	for i, slot in ipairs(self.BagSlots) do
		slot.icon.ImageTransparency = i <= carried and 0 or 0.8
		slot.caption.Text = i <= carried and "Ocupado" or "Livre"
	end
	self.BagSummary.Text = string.format("Na bolsa: %d/%d   •   Na base: %d/%d", carried, bagCapacity, installed, baseCapacity)
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
function HUD:SetCharging(power, range, maxRange)
	self.ChargePanel.Visible = self.equipped and not self.capturing
	self.Capture:SetCharging(power, range, maxRange)
	self.ThrowSkin:SetHeld(true)
	self.ThrowSkin:SetSelected(power >= 1)
end
function HUD:ResetThrow()
	Audio.StopCharge()
	self.Capture.wasFull = false
	self.ChargePanel.Visible = false
	self.ThrowSkin:SetHeld(false)
	self.ThrowSkin:SetSelected(false)
end
function HUD:ThrowLaunched()
	self:ResetThrow()
end
function HUD:StartCapture(name, golden)
	Audio.Play("Hit")
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
	if self.capturing and not success then Audio.Play("Return", 0.8) end
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
	if not message or message == self.lastNotice and os.clock() - (self.lastNoticeTime or 0) < 3 then
		return
	end
	self.lastNotice = message
	self.lastNoticeTime = os.clock()
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
			self.Surface,
			"EstrelaVitoria",
			S.Icons.XP,
			UDim2.fromOffset(golden and 48 or 34, golden and 48 or 34),
			self.RewardRoot.Position
		)
		spark.AnchorPoint = Vector2.new(0.5, 0.5)
		spark.ZIndex = 44
		local angle = i * math.pi / 5
		local distance = math.min(golden and 260 or 205, self.view.X * 0.4)
		TweenService:Create(spark, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = self.RewardRoot.Position + UDim2.fromOffset(math.cos(angle) * distance, math.sin(angle) * distance * 0.48),
			Rotation = i % 2 == 0 and 80 or -80,
			ImageTransparency = 1,
		}):Play()
		task.delay(0.9, function()
			spark:Destroy()
		end)
	end
	self.BagSkin:Shine()
	Audio.Reward(golden)
	local origin = self.RewardRoot.AbsolutePosition + self.RewardRoot.AbsoluteSize / 2
	local destination = self.BagButton.AbsolutePosition + self.BagButton.AbsoluteSize / 2
	Effects.Fly(self.Surface, S.Icons.Bag, origin - self.Surface.AbsolutePosition, destination - self.Surface.AbsolutePosition)
	task.delay(2.5, function()
		if not self.dead and version == self.rewardVersion then
			self.RewardRoot.Visible = false
		end
	end)
end
return HUD

