-- HUD v4. Orquestra apresentação; captura, valores e inventário continuam no servidor.
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local Resources = require(script.Parent.ResourceHUD)
local Capture = require(script.Parent.CaptureHUD)
local RewardPresentation = require(script.Parent.RewardPresentation)
local QuickSlot = require(script.Parent.QuickSlot)
local S = W.Style
local Layout = require(script.Parent.HUDLayout)
local Audio = require(script.Parent.AudioFeedback)
local GuiService = game:GetService("GuiService")
local HUD = {}
HUD.__index = HUD
function HUD.new(player)
	local self = setmetatable(
		{ player = player, connections = {}, equipped = false, capturing = false, toastVersion = 0 },
		HUD
	)
	local gui = Instance.new("ScreenGui")
	gui.Name = "HuntACreatureGui"
	gui.ResetOnSpawn = false
	gui.AutoLocalize = false
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
	self.Resources = Resources.new(gui)
	self.BagSkin = Button.new(gui, {
		name = "BolsaBotao",
		text = "Creatures",
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
	self.IndexSkin = Button.new(gui, {
		name = "IndexBotao",
		glyph = "book",
		text = "Index",
		color = S.UI.Purple,
		size = UDim2.fromOffset(86, 44),
		position = UDim2.new(),
		textSize = 20,
	})
	self.IndexSkin.Root.Activated:Connect(function()
		if self.Collection then
			self.Collection:Open("Index")
		end
	end)
	self.SettingsSkin = Button.new(
		gui,
		{
			name = "Settings",
			text = "Settings",
			glyph = "gear",
			color = S.UI.Cyan,
			size = UDim2.fromOffset(104, 40),
			position = UDim2.new(1, -116, 0, 10),
			textSize = 14,
		}
	)
	self.SettingsSkin.Root.Activated:Connect(function()
		if self.Collection then
			self.Collection:Open("Settings")
		end
	end)
	self.ThrowSkin = Button.new(gui, {
		name = "Arremessar",
		text = "Throw",
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
	self.Toast = W.panel(gui, "Aviso", UDim2.fromOffset(450, 64), UDim2.fromScale(0.5, 0.17), S.UI.Cyan)
	self.Toast.AnchorPoint = Vector2.new(0.5, 0)
	self.Toast.Visible = false
	self.Toast.ZIndex = 40
	self.ToastText = W.text(self.Toast, "Texto", "", UDim2.new(1, -35, 1, -14), UDim2.fromOffset(17, 7), 22)
	self.ToastScale = Instance.new("UIScale")
	self.ToastScale.Parent = self.Toast
	self.RewardView = RewardPresentation.new(gui, self.Surface, self.BagButton)
	table.insert(
		self.connections,
		self.BagButton.Activated:Connect(function()
			if self.Collection and self.Collection.root.Visible and self.Collection.tab == "Criaturas" then
				self:CloseSheet()
			else
				self:OpenSheet("bag")
			end
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
		if view.X > 0 and view.Y > 0 then
			self:Resize(view)
		end
	end
	table.insert(self.connections, surface:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	table.insert(self.connections, UIS:GetPropertyChangedSignal("TouchEnabled"):Connect(resize))
	resize()
	task.defer(function()
		if not self.dead then
			resize()
		end
	end)
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
	local navWidth = math.max(100, layout.bag)
	self.IndexSkin.Root.Size = UDim2.fromOffset(navWidth, 44)
	if layout.narrow then
		local y = margin + 5 + layout.bag + 6
		self.IndexSkin.Root.Position = UDim2.new(1, -margin - navWidth, 0, y)
	elseif layout.desktop then
		self.IndexSkin.Root.Position = UDim2.fromOffset(margin, bagY - 50)
	else
		self.IndexSkin.Root.Position = UDim2.fromOffset(margin + layout.bag + 8, bagY)
	end
	self.SettingsSkin.Root.Position = layout.narrow and UDim2.new(1, -margin - navWidth, 0, margin + layout.bag + 61)
		or (
			layout.desktop and UDim2.new(1, -margin - 116, 0, margin)
			or UDim2.fromOffset(margin + layout.bag + 8, bagY + 50)
		)
	self.SettingsSkin.Root.Size = UDim2.fromOffset(layout.narrow and navWidth or 116, 40)
	self.BagBadge.Size = UDim2.fromOffset(32, 24)
	self.BagBadge.Position = UDim2.new(1, -29, 0, 0)
	self.BagCount.TextSize = 14
	local throwSize = layout.short and 68 or 80
	self.ThrowButton.Size = UDim2.fromOffset(throwSize, throwSize)
	self.ThrowButton.Position =
		UDim2.new(1, -margin - throwSize, 0, math.max(margin + layout.resourceHeight + 12, view.Y - 160 - throwSize))
	self.Slot.Root.Size = UDim2.fromOffset(layout.slot, layout.slot)
	self.Slot.Root.Position = UDim2.new(0.5, 0, 1, -margin)
	self.Toast.Size = UDim2.fromOffset(math.min(450, view.X - margin * 2), 58)
	self.Toast.Position = UDim2.new(0.5, 0, 0, margin + layout.resourceHeight + 8)
	self.ToastText.TextSize = layout.short and 16 or 20
	self.ToastScale.Scale = 1
	self.RewardView:Resize(view, layout)
	-- A mira representa o centro da câmera, não o centro da área abaixo da topbar.
	local camera = workspace.CurrentCamera
	if camera then
		local inset = GuiService:GetGuiInset()
		self.Reticle.Position =
			UDim2.fromOffset(camera.ViewportSize.X / 2 - inset.X - 12, camera.ViewportSize.Y / 2 - inset.Y - 12)
	end
	if self.Collection then
		self.Collection:Resize()
	end
end
function HUD:OpenSheet(kind)
	if kind == "bag" and self.Collection then
		self.Collection:Open("Criaturas")
	end
end
function HUD:CloseSheet()
	if self.Collection then
		self.Collection:Close()
	end
	self.sheetKind = nil
	self.BagSkin:SetSelected(false)
end
function HUD:UpdateStats()
	local stats = self.player:FindFirstChild("leaderstats")
	local gold = stats and stats:FindFirstChild("Gold")
	local xp = stats and stats:FindFirstChild("XP")
	self.Resources:Update(gold and gold.Value or 0, xp and xp.Value or 0,
		self.player:GetAttribute("Forca") or 0, self.player:GetAttribute("HunterRank") or 1)
	local carried = self.player:GetAttribute("Carregando") or 0
	local bagCapacity = self.player:GetAttribute("BagCapacity") or 3
	self.BagCount.Text = string.format("%d/%d", carried, bagCapacity)
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
	self.Capture.ChargeScale.Scale = 1
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
	if self.capturing and not success then
		Audio.Play("Return", 0.8)
	end
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
function HUD:Reward(data)
	self.BagSkin:Shine()
	self.RewardView:Show(data)
end
return HUD
