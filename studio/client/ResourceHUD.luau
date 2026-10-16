-- Contadores v4; apenas apresentação dos valores replicados pelo servidor.
local TweenService = game:GetService("TweenService")
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local S = W.Style
local Resources = {}
Resources.__index = Resources
local specs = {
	{ "Ouro", "OURO", S.Icons.Coin, S.UI.Gold },
	{ "XP", "XP", S.Icons.XP, S.UI.Purple },
	{ "Forca", "FORÇA", S.Icons.Strength, S.UI.Cyan },
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
	return text:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
end
function Resources.new(parent, onDetails)
	local self = setmetatable({ items = {} }, Resources)
	self.Root = W.frame(parent, "Recursos", UDim2.fromOffset(854, 70), UDim2.new(1, -870, 0, 10))
	self.Scale = Instance.new("UIScale")
	self.Scale.Parent = self.Root
	for index, spec in ipairs(specs) do
		local card =
			W.panel(self.Root, spec[1], UDim2.fromOffset(274, 66), UDim2.fromOffset((index - 1) * 290, 0), spec[4])
		W.icon(card, "Icone", spec[3], UDim2.fromOffset(84, 84), UDim2.fromOffset(-9, -9))
		W.text(
			card,
			"Nome",
			spec[2],
			UDim2.fromOffset(145, 15),
			UDim2.fromOffset(70, 7),
			12,
			spec[4],
			Enum.TextXAlignment.Left
		)
		local text = W.text(
			card,
			"Valor",
			"0",
			UDim2.fromOffset(147, 40),
			UDim2.fromOffset(69, 20),
			33,
			nil,
			Enum.TextXAlignment.Left
		)
		text.TextScaled = true
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = 33
		limit.MinTextSize = 16
		limit.Parent = text
		local scale = Instance.new("UIScale")
		scale.Parent = text
		local plus = Button.new(
			card,
			{
				name = "Detalhes",
				text = "+",
				textSize = 38,
				color = S.UI.Green,
				size = UDim2.fromOffset(44, 46),
				position = UDim2.fromOffset(220, 10),
			}
		)
		plus.Root.Activated:Connect(function()
			onDetails(spec[1])
		end)
		self.items[index] = { text = text, scale = scale }
	end
	return self
end
function Resources:Resize(view)
	local scale = math.clamp((view.X - 32) / 854, 0.40, 1)
	if view.X >= 1100 then
		scale = 1
	end
	self.Scale.Scale = scale
	self.Root.Position = UDim2.new(1, -16 - 854 * scale, 0, view.X < 1100 and 48 or 10)
end
function Resources:Update(gold, xp, force)
	for i, value in ipairs({ gold, xp, force }) do
		local item = self.items[i]
		item.text.Text = formatNumber(value)
		if item.value and value > item.value then
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
