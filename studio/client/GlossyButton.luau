-- Arte v4 e interação visual. Não executa ações do jogo.
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local W = require(script.Parent.HUDWidgets)
local S = W.Style
local Effects = require(script.Parent.UIEffects)
local Audio = require(script.Parent.AudioFeedback)
local Button = {}
Button.__index = Button
function Button.new(parent, o)
	local self = setmetatable({ connections = {}, tweens = {} }, Button)
	local root = Instance.new("TextButton")
	root.Name = o.name
	root.Size = o.size
	root.Position = o.position
	root.BackgroundTransparency = 1
	root.Text = ""
	root.AutoButtonColor = false
	root.ZIndex = o.zIndex or 2
	root.Parent = parent
	self.Root = root
	local visual = W.frame(root, "Visual", UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5))
	visual.AnchorPoint = Vector2.new(0.5, 0.5)
	self.scale = Instance.new("UIScale")
	self.scale.Parent = visual
	if o.icon then
		local face = W.icon(visual, "Arte", S.Skins.Tile, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0))
		face.ScaleType = Enum.ScaleType.Stretch
		self.icon = W.icon(face, "Icone", o.icon, UDim2.fromScale(0.78, 0.76), UDim2.fromScale(0.11, 0.005))
		local plate = W.panel(face, "Placa", UDim2.fromScale(0.9, 0.28), UDim2.fromScale(0.05, 0.68), S.UI.Cyan)
		self.caption =
			W.text(plate, "Legenda", o.text, UDim2.new(1, -12, 1, -4), UDim2.fromOffset(6, 0), o.textSize or 25)
	else
		local color = o.color or S.UI.Gold
		local face = W.frame(visual, "Face", UDim2.new(1, -6, 1, -6), UDim2.fromOffset(3, 3), S.UI.White, 12)
		W.gradient(face, color, color:Lerp(S.UI.Ink, 0.35))
		W.stroke(face, S.UI.Ink, 3)
		local rim = W.frame(face, "Bisel", UDim2.new(1, -4, 1, -4), UDim2.fromOffset(2, 2), nil, 10)
		W.stroke(rim, color:Lerp(S.UI.White, 0.5), 2)
		local shine = W.frame(face, "Luz", UDim2.new(1, -12, 0.32, 0), UDim2.fromOffset(6, 3), S.UI.White, 7)
		shine.BackgroundTransparency = 0.67
		self.caption =
			W.text(face, "Legenda", o.text, UDim2.new(1, -8, 1, -4), UDim2.fromOffset(4, 0), o.textSize or 24)
	end
	local reflectionMask = W.frame(visual, "ReflexoMascara", UDim2.new(1, -18, 1, -18), UDim2.fromOffset(9, 9))
	reflectionMask.ClipsDescendants = true
	self.sweep = W.frame(reflectionMask, "Reflexo", UDim2.fromScale(0.18, 2), UDim2.fromScale(-0.3, -0.5), S.UI.White)
	self.sweep.Rotation = 22
	self.sweep.BackgroundTransparency = 0.8
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = self.sweep
	self.caption.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = o.textSize or 25
	limit.MinTextSize = 12
	limit.Parent = self.caption
	self.spark = W.text(visual, "Brilho", "✦", UDim2.fromOffset(26, 26), UDim2.fromScale(0.78, 0.06), 24)
	self.spark.TextTransparency = 1
	self.spark:FindFirstChildOfClass("UIStroke").Enabled = false
	local function connect(signal, fn)
		table.insert(self.connections, signal:Connect(fn))
	end
	connect(root.MouseEnter, function()
		self.hover = true
		self:_refresh()
		self:Shine()
	end)
	connect(root.MouseLeave, function()
		self.hover = false
		self:_refresh()
	end)
	connect(root.SelectionGained, function()
		self.focus = true
		self:_refresh()
		self:Shine()
	end)
	connect(root.SelectionLost, function()
		self.focus = false
		self:_refresh()
	end)
	connect(root.InputBegan, function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			self.input = input
			self:_refresh()
		end
	end)
	connect(UIS.InputEnded, function(input)
		if self.input == input then
			self.input = nil
			self:_refresh()
		end
	end)
	connect(UIS.WindowFocusReleased, function()
		self.input = nil
		self.hover = false
		self:_refresh()
	end)
	connect(root.Activated, function()
		if o.sound ~= false then Audio.Play("Click") end
		Effects.Burst(visual, S.UI.Gold, 5)
		self:Shine()
	end)
	connect(root:GetPropertyChangedSignal("Visible"), function()
		if not root.Visible then
			self.input = nil
			self.hover = false
			self:_refresh()
		end
	end)
	connect(root.Destroying, function()
		self.dead = true
		for _, c in ipairs(self.connections) do
			c:Disconnect()
		end
		for _, t in pairs(self.tweens) do
			t:Cancel()
		end
	end)
	return self
end
function Button:_tween(key, object, properties, duration)
	if self.tweens[key] then
		self.tweens[key]:Cancel()
	end
	local t = TweenService:Create(
		object,
		TweenInfo.new(duration or 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		properties
	)
	self.tweens[key] = t
	t:Play()
end
function Button:_refresh()
	local down = self.input ~= nil or self.held
	local focus = self.hover or self.focus or self.selected
	self:_tween(
		"scale",
		self.scale,
		{ Scale = down and S.UI.PressScale or (focus and S.UI.HoverScale or 1) },
		down and 0.08 or 0.24
	)
	if self.icon then
		self:_tween("icon", self.icon, { Rotation = focus and -5 or 0 })
	end
end
function Button:Shine()
	if self.dead then
		return
	end
	self.sweep.Position = UDim2.fromScale(-0.3, -0.5)
	self:_tween("sweep", self.sweep, { Position = UDim2.fromScale(1.3, -0.5) }, 0.5)
	self.spark.TextTransparency = 0
	self:_tween("spark", self.spark, { TextTransparency = 1 }, 0.55)
end
function Button:SetText(t)
	self.caption.Text = t
end
function Button:SetHeld(v)
	if self.held ~= v then
		self.held = v
		self:_refresh()
	end
end
function Button:SetSelected(v)
	if self.selected ~= v then
		self.selected = v
		self:_refresh()
		if v then
			self:Shine()
		end
	end
end
return Button

