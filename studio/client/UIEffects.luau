-- Efeitos curtos disparados por eventos. Sem loops permanentes ou avisos redundantes.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local W = require(script.Parent.HUDWidgets)
local E = {}
function E.Burst(parent, color, count)
	for i = 1, count or 5 do
		local t = W.text(parent, "ParticulaUI", "✦", UDim2.fromOffset(16, 16), UDim2.fromScale(0.5, 0.5), 16, color)
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t:FindFirstChildOfClass("UIStroke").Enabled = false
		t.ZIndex = parent.ZIndex + 3
		local angle = math.pi * 2 * i / (count or 5)
		TweenService:Create(t, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(angle) * 45, 0.5, math.sin(angle) * 36),
			TextTransparency = 1,
			Rotation = i * 60,
		}):Play()
		Debris:AddItem(t, 0.42)
	end
end
function E.Fly(gui, asset, from, to)
	local icon = W.icon(gui, "RecompensaVoando", asset, UDim2.fromOffset(42, 42), UDim2.fromOffset(from.X, from.Y))
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.ZIndex = 48
	local tween = TweenService:Create(icon, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Position = UDim2.fromOffset(to.X, to.Y),
		Size = UDim2.fromOffset(16, 16),
		Rotation = 25,
	})
	tween:Play()
	Debris:AddItem(icon, 0.55)
end
return E

