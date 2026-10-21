-- Contadores v4; apenas apresentação dos valores replicados pelo servidor.
local TweenService = game:GetService("TweenService")
local W = require(script.Parent.HUDWidgets)
local S = W.Style
local Audio = require(script.Parent.AudioFeedback)
local Resources = {}
Resources.__index = Resources
local specs = {
	{ "Ouro", "GOLD", S.Icons.Coin, S.UI.Gold },
	{ "XP", "XP", S.Icons.XP, S.UI.Purple },
	{ "Forca", "STRENGTH", S.Icons.Strength, S.UI.Cyan },
}
local function formatNumber(value)
	local n = math.max(0, math.floor(value))
	if n >= 1000000000 then
		return string.format("%.1fB", n / 1000000000)
	end
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	end
	local text = tostring(n)
	return text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end
function Resources.new(parent, onDetails)
	local self = setmetatable({ items = {} }, Resources)
	self.Root = W.frame(parent, "Recursos", UDim2.fromOffset(244, 184), UDim2.new(0, 16, 1, -200))
	self.Scale = Instance.new("UIScale")
	self.Scale.Parent = self.Root
	for index, spec in ipairs(specs) do
		local card =
			W.panel(self.Root, spec[1], UDim2.fromOffset(244, 56), UDim2.fromOffset(0, (index - 1) * 64), spec[4])
		local icon = W.icon(card, "Icone", spec[3], UDim2.fromOffset(50, 50), UDim2.fromOffset(4, 3))
		local label = W.text(
			card,
			"Nome",
			spec[2],
			UDim2.fromOffset(130, 14),
			UDim2.fromOffset(61, 6),
			12,
			spec[4],
			Enum.TextXAlignment.Left
		)
		local text = W.text(
			card,
			"Valor",
			"0",
			UDim2.fromOffset(130, 30),
			UDim2.fromOffset(59, 19),
			27,
			nil,
			Enum.TextXAlignment.Left
		)
		text.TextScaled = true
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = 27
		limit.MinTextSize = 16
		limit.Parent = text
		local scale = Instance.new("UIScale")
		scale.Parent = text
		local gain = W.text(card, "Ganho", "", UDim2.fromOffset(100, 26), UDim2.fromOffset(80, -6), 19, spec[4])
		gain.Visible = false
		gain.AnchorPoint = Vector2.new(0.5, 0)
		self.items[index] = { text = text, scale = scale, card = card, gain = gain, icon = icon, label = label }
	end
	return self
end
function Resources:Resize(layout)
	local mode, margin = layout.resourceMode, layout.margin
	local row = mode == "row"
	local gap, height = 8, layout.resourceHeight
	local width = row and math.min(224, (layout.width - margin * 2 - gap * 2) / 3)
		or (mode == "narrow" and math.min(190, layout.width - layout.bag - margin * 3) or 224)
	self.Scale.Scale = 1
	self.Root.Size = UDim2.fromOffset(row and (width * 3 + gap * 2) or width, row and height or height * 3 + gap * 2)
	self.Root.AnchorPoint = mode == "stack" and Vector2.new(0, 1) or Vector2.zero
	self.Root.Position = mode == "stack" and UDim2.new(0, margin, 1, -margin) or UDim2.fromOffset(margin, margin)
	for i, item in ipairs(self.items) do
		item.card.Size = UDim2.fromOffset(width, height)
		item.card.Position =
			UDim2.fromOffset(row and (i - 1) * (width + gap) or 0, row and 0 or (i - 1) * (height + gap))
		local iconSize = height - 8
		item.icon.Size = UDim2.fromOffset(iconSize, iconSize)
		item.icon.Position = UDim2.fromOffset(4, 4)
		local left = iconSize + 10
		item.label.Position = UDim2.fromOffset(left, 5)
		item.label.Size = UDim2.fromOffset(width - left - 12, 13)
		item.label.TextSize = 11
		item.text.Position = UDim2.fromOffset(left, 18)
		item.text.Size = UDim2.fromOffset(width - left - 12, height - 22)
		item.text:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize = layout.short and 21 or 25
		item.gain.Size = UDim2.fromOffset(width - 30, 24)
	end
end
function Resources:Update(gold, xp, force, rank)
	self.items[2].label.Text = "XP · RANK " .. tostring(rank or 1)
	for i, value in ipairs({ gold, xp, force }) do
		local item = self.items[i]
		item.text.Text = formatNumber(value)
		if item.value and value > item.value then
			if i == 1 and os.clock() - (self.lastIncomeSound or 0) >= 5 then
				self.lastIncomeSound = os.clock()
				Audio.Play("Income")
			end
			if item.gainTween then
				item.gainTween:Cancel()
			end
			item.gain.Text = "+" .. formatNumber(value - item.value)
			item.gain.Position = UDim2.new(0.5, 0, 0, -6)
			item.gain.TextTransparency = 0
			item.gain.Visible = true
			item.gainTween = TweenService:Create(
				item.gain,
				TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = UDim2.new(0.5, 0, 0, -27), TextTransparency = 1 }
			)
			item.gainTween:Play()
			local outline = item.gain:FindFirstChildOfClass("UIStroke")
			if item.outlineTween then
				item.outlineTween:Cancel()
			end
			outline.Transparency = 0
			item.outlineTween = TweenService:Create(outline, TweenInfo.new(0.8), { Transparency = 1 })
			item.outlineTween:Play()
			if item.tween then
				item.tween:Cancel()
			end
			item.scale.Scale = 1.16
			item.tween = TweenService:Create(
				item.scale,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			item.tween:Play()
		end
		item.value = value
	end
end
return Resources
