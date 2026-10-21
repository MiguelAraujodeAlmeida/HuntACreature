-- Resultado curto da caca. Os valores chegam prontos do servidor.
local TweenService = game:GetService("TweenService")
local W = require(script.Parent.HUDWidgets)
local Portrait = require(script.Parent.CreaturePortrait)
local Effects = require(script.Parent.UIEffects)
local Audio = require(script.Parent.AudioFeedback)
local S = W.Style
local Reward = {}
Reward.__index = Reward

function Reward.new(parent, surface, bagButton)
	local self = setmetatable({ surface = surface, bagButton = bagButton, version = 0, baseScale = 1 }, Reward)
	self.Root = W.panel(parent, "Vitoria", UDim2.fromOffset(480, 126), UDim2.fromScale(0.5, 0.3), S.UI.Cyan)
	self.Root.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Root.Visible = false
	self.Root.ZIndex = 45
	self.Scale = Instance.new("UIScale")
	self.Scale.Parent = self.Root
	self.PortraitHost = W.frame(self.Root, "Retrato", UDim2.fromOffset(105, 105), UDim2.fromOffset(10, 10), S.UI.Ink, 13)
	self.PortraitHost.ZIndex = 46
	W.stroke(self.PortraitHost, S.UI.Cyan, 2)
	self.Title = W.text(self.Root, "Titulo", "CAPTURED!", UDim2.fromOffset(340, 27), UDim2.fromOffset(125, 8), 25, S.UI.White, Enum.TextXAlignment.Left)
	self.Name = W.text(self.Root, "Nome", "", UDim2.fromOffset(340, 29), UDim2.fromOffset(125, 35), 23, S.UI.White, Enum.TextXAlignment.Left)
	self.Rates = W.text(self.Root, "Renda", "", UDim2.fromOffset(340, 24), UDim2.fromOffset(125, 65), 16, S.UI.Green, Enum.TextXAlignment.Left)
	self.Detail = W.text(self.Root, "Destaque", "", UDim2.fromOffset(340, 20), UDim2.fromOffset(125, 94), 14, S.UI.Cyan, Enum.TextXAlignment.Left)
	return self
end

function Reward:Resize(view, layout)
	self.baseScale = math.min(1, (view.X - layout.margin * 2) / 480)
	self.Scale.Scale = self.baseScale
	self.Root.Position = UDim2.fromScale(0.5, layout.short and 0.35 or 0.29)
end

function Reward:Show(data)
	if typeof(data) ~= "table" or type(data.species) ~= "string" then return end
	self.version += 1
	local version = self.version
	local special = data.golden or data.firstSpecies or data.firstVariant
	local accent = data.golden and S.UI.Gold or special and S.UI.Purple or S.UI.Cyan
	self.Root.ImageColor3 = accent
	self.PortraitHost:FindFirstChildOfClass("UIStroke").Color = accent
	self.Title.Text = data.firstSpecies and "NEW DISCOVERY!" or data.golden and "GOLD CAPTURE!"
		or data.firstVariant and "NEW INDEX VARIANT!" or "CAPTURED!"
	self.Title.TextColor3 = accent
	self.Name.Text = data.name or data.species
	self.Rates.Text = string.format("+%d HUNTER XP  ·  AT BASE: +%d GOLD/s", data.xpEarned or 0, data.goldPerSecond or 0)
	local details = {}
	if data.firstVariant and data.golden and not data.firstSpecies then table.insert(details, "NEW INDEX VARIANT") end
	if data.rarity and data.rarity ~= "Common" then table.insert(details, data.rarity:upper()) end
	self.Detail.Text = table.concat(details, "  •  ")
	self.Detail.TextColor3 = accent
	if self.portrait then self.portrait:Destroy() end
	self.portrait = Portrait.new(self.PortraitHost, data, true, UDim2.fromScale(1, 1), UDim2.new())
	self.Root.Visible = true
	self.Scale.Scale = self.baseScale * 0.78
	TweenService:Create(self.Scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = self.baseScale }):Play()
	Effects.Burst(self.Root, accent, special and 10 or 6)
	Audio.Reward(data.golden, data.firstSpecies or data.firstVariant)
	local origin = self.Root.AbsolutePosition + self.Root.AbsoluteSize / 2
	local destination = self.bagButton.AbsolutePosition + self.bagButton.AbsoluteSize / 2
	Effects.Fly(self.surface, S.Icons.Bag, origin - self.surface.AbsolutePosition, destination - self.surface.AbsolutePosition)
	task.delay(data.firstSpecies and 2.35 or special and 2.05 or 1.75, function()
		if self.Root.Parent and version == self.version then self.Root.Visible = false end
	end)
end

return Reward
