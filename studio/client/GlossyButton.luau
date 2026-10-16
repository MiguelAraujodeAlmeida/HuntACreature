-- Aparência/interação apenas. O GuiButton exposto continua sendo o alvo de input.
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Style = require(game:GetService("ReplicatedStorage").HACShared.VisualStyle)
local Theme = Style.Button
local Button = {}
Button.__index = Button

local function rounded(parent, name, size, position, color, radius)
	local object = Instance.new("Frame")
	object.Name = name
	object.Size = size
	object.Position = position
	object.BackgroundColor3 = color
	object.BorderSizePixel = 0
	object.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
	return object
end

local function outline(parent, color, thickness, transparency)
	local line = Instance.new("UIStroke")
	line.Color = color
	line.Thickness = thickness
	line.Transparency = transparency or 0
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	line.Parent = parent
	return line
end

local function gradient(parent, top, bottom)
	local value = Instance.new("UIGradient")
	value.Color = ColorSequence.new(top, bottom)
	value.Rotation = 90
	value.Parent = parent
	return value
end

function Button.new(parent, options)
	local self = setmetatable({connections = {}, tweens = {}, hovered = false, held = false, selected = false}, Button)
	local palette = Theme.Palettes[options.palette or "Cyan"]
	local tile = options.icon ~= nil
	local radius = tile and 23 or 14
	local root = Instance.new("TextButton")
	root.Name = options.name
	root.Size = options.size
	root.Position = options.position
	root.BackgroundTransparency = 1
	root.Text = ""
	root.AutoButtonColor = false
	root.BorderSizePixel = 0
	root.ZIndex = options.zIndex or 2
	root.Parent = parent
	self.Root = root
	self.palette = palette

	-- Escalar o desenho mantém o alvo de toque fixo e previsível.
	local visual = rounded(root, "Visual", UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Theme.Outline, radius + 3)
	visual.AnchorPoint = Vector2.new(0.5, 0.5)
	visual.BackgroundTransparency = 1
	self.scale = Instance.new("UIScale")
	self.scale.Parent = visual
	self.visual = visual
	local halo = rounded(visual, "Halo", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), palette.Rim, radius)
	halo.BackgroundTransparency = 1
	self.glow = outline(halo, palette.Rim, 5, 0.68)
	local shadow = rounded(visual, "Sombra", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 5), Theme.Outline, radius)
	outline(shadow, Theme.Outline, 2)
	local rim = rounded(visual, "Aro", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), Color3.new(1, 1, 1), radius)
	gradient(rim, palette.Rim, palette.Edge)
	outline(rim, Theme.Outline, 2)
	-- Camadas finas dão volume sem textura rasterizada ou texto embutido.
	local lip = rounded(rim, "Bisel", UDim2.new(1, -6, 1, -6), UDim2.fromOffset(3, 3), Color3.new(1, 1, 1), radius - 2)
	gradient(lip, Color3.new(1, 1, 1), palette.Rim)
	local face = rounded(lip, "Face", UDim2.new(1, -5, 1, -5), UDim2.fromOffset(2.5, 2), Color3.new(1, 1, 1), radius - 4)
	gradient(face, palette.Top, palette.Bottom)
	outline(face, palette.Edge, 1)
	face.ClipsDescendants = true
	self.face = face
	local reflection = rounded(face, "Reflexo", UDim2.new(1, -12, 0.46, 0), UDim2.fromOffset(6, 3), Color3.new(1, 1, 1), radius - 6)
	reflection.BackgroundTransparency = 0.7
	local reflectionGradient = gradient(reflection, Color3.new(1, 1, 1), Color3.new(1, 1, 1))
	reflectionGradient.Transparency = NumberSequence.new(0, 1)
	local glint = rounded(face, "LuzSuperior", UDim2.new(0.56, 0, 0, 2), UDim2.new(0.17, 0, 0, 3), Color3.new(1, 1, 1), 2)
	glint.BackgroundTransparency = 0.12

	if tile then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icone"
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.new(0.83, 0, 0.76, 0)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.38)
		icon.Image = options.icon
		icon.ScaleType = Enum.ScaleType.Fit
		if options.iconIndex then
			icon.ImageRectSize = Style.IconCellSize
			icon.ImageRectOffset = Vector2.new((options.iconIndex - 1) * Style.IconCellSize.X, 0)
		end
		icon.Parent = face
		self.icon = icon
	end
	local plate = rounded(face, "LegendaFundo", tile and UDim2.new(1, -7, 0.29, 0) or UDim2.new(1, -8, 1, -8), tile and UDim2.new(0, 3.5, 0.69, -1) or UDim2.fromOffset(4, 4), palette.Plate, tile and 12 or 8)
	plate.BackgroundTransparency = tile and 0 or 1
	if tile then outline(plate, palette.Rim, 1.5) end
	local caption = Instance.new("TextLabel")
	caption.Name = "Legenda"
	caption.BackgroundTransparency = 1
	caption.Size = UDim2.new(1, -4, 1, -2)
	caption.Position = UDim2.fromOffset(2, 0)
	caption.Font = Theme.Font
	caption.Text = options.text
	caption.TextColor3 = Color3.new(1, 1, 1)
	caption.TextScaled = true
	caption.Parent = plate
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 12
	limit.MaxTextSize = options.textSize or 23
	limit.Parent = caption
	local textOutline = Instance.new("UIStroke")
	textOutline.Color = Theme.Outline
	textOutline.Thickness = 2
	textOutline.Parent = caption
	self.caption = caption

	-- Um reflexo atravessa o acabamento ao focar/ativar, sem loop constante.
	local sheen = rounded(face, "ReflexoAnimado", UDim2.fromScale(0.25, 2), UDim2.fromScale(-0.6, -0.5), Color3.new(1, 1, 1), 0)
	sheen.Rotation = 25
	sheen.BackgroundTransparency = 1
	local sheenGradient = Instance.new("UIGradient")
	sheenGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.68), NumberSequenceKeypoint.new(1, 1)})
	sheenGradient.Parent = sheen
	self.sheen = sheen
	local sparkle = rounded(face, "Brilho", UDim2.fromOffset(13, 13), UDim2.fromScale(0.86, 0.14), Color3.new(1, 1, 1), 0)
	sparkle.BackgroundTransparency = 1
	sparkle.AnchorPoint = Vector2.new(0.5, 0.5)
	for _, size in ipairs({Vector2.new(3, 13), Vector2.new(13, 3)}) do
		local ray = rounded(sparkle, "Raio", UDim2.fromOffset(size.X, size.Y), UDim2.fromScale(0.5, 0.5), Color3.new(1, 1, 1), 2)
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Rotation = 20
	end
	self.sparkleScale = Instance.new("UIScale")
	self.sparkleScale.Scale = tile and 0.7 or 0
	self.sparkleScale.Parent = sparkle
	self.tile = tile

	local function connect(signal, callback)
		table.insert(self.connections, signal:Connect(callback))
	end
	connect(root.MouseEnter, function() self.hovered = true; self:_refresh(); self:Shine() end)
	connect(root.MouseLeave, function() self.hovered = false; self:_refresh() end)
	connect(root.SelectionGained, function() self.focused = true; self:_refresh(); self:Shine() end)
	connect(root.SelectionLost, function() self.focused = false; self:_refresh() end)
	connect(root.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonA then
			self.pressInput = input
			self:_refresh()
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if input == self.pressInput then self.pressInput = nil; self:_refresh() end
	end)
	connect(UserInputService.WindowFocusReleased, function() self.pressInput = nil; self.hovered = false; self:_refresh() end)
	connect(root.Activated, function() self:Shine() end)
	connect(root:GetPropertyChangedSignal("Visible"), function()
		if not root.Visible then self.pressInput = nil; self.hovered = false; self.held = false; self:_refresh() end
	end)
	connect(root.Destroying, function() self:Destroy() end)
	return self
end

function Button:_tween(key, object, seconds, properties, easing)
	if self.tweens[key] then self.tweens[key]:Cancel() end
	local tween = TweenService:Create(object, TweenInfo.new(seconds, easing or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	self.tweens[key] = tween
	tween:Play()
end

function Button:_refresh()
	local down = self.pressInput ~= nil or self.held
	local focus = self.hovered or self.focused or self.selected
	self:_tween("scale", self.scale, down and 0.07 or Theme.ReleaseSeconds, {Scale = down and Theme.PressScale or (focus and Theme.HoverScale or 1)}, down and Enum.EasingStyle.Quad or Enum.EasingStyle.Back)
	self:_tween("depth", self.visual, 0.1, {Position = UDim2.new(0.5, 0, 0.5, down and 3 or 0)})
	self:_tween("glow", self.glow, Theme.HoverSeconds, {Transparency = (focus or down) and 0.22 or 0.68})
	if self.icon then self:_tween("icon", self.icon, Theme.HoverSeconds, {Rotation = focus and -6 or 0}) end
end

function Button:Shine()
	if self.destroyed then return end
	if self.tweens.sheen then self.tweens.sheen:Cancel() end
	self.sheen.Position = UDim2.fromScale(-0.6, -0.5)
	self.sheen.BackgroundTransparency = 0
	self:_tween("sheen", self.sheen, 0.55, {Position = UDim2.fromScale(1.3, -0.5)})
	self.sparkleScale.Scale = 1.5
	self:_tween("sparkle", self.sparkleScale, 0.45, {Scale = self.tile and 0.7 or 0})
end

function Button:SetText(value)
	self.caption.Text = value
end

function Button:SetHeld(value)
	if self.held == value then return end
	self.held = value
	self:_refresh()
end

function Button:SetSelected(value)
	if self.selected == value then return end
	self.selected = value
	self:_refresh()
	if value then self:Shine() end
end

function Button:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	for _, tween in pairs(self.tweens) do tween:Cancel() end
end

return Button
