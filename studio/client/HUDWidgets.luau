-- Primitivos visuais v4: arte, texto editável e superfícies compartilhadas.
local S = require(game.ReplicatedStorage.HACShared.VisualStyle)
local W = { Style = S }
function W.frame(parent, name, size, pos, color, radius)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color or S.UI.Ink
	f.BackgroundTransparency = color and 0 or 1
	f.Parent = parent
	if radius then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius)
		c.Parent = f
	end
	return f
end
function W.stroke(parent, color, width)
	local s = Instance.new("UIStroke")
	s.Color = color or S.UI.Ink
	s.Thickness = width or 2
	s.Parent = parent
	return s
end
function W.gradient(parent, top, bottom)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(top, bottom)
	g.Rotation = 90
	g.Parent = parent
	return g
end
function W.text(parent, name, value, size, pos, fontSize, color, align)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.Size = size
	t.Position = pos
	t.BackgroundTransparency = 1
	t.Font = S.DisplayFont
	t.Text = value
	t.TextSize = fontSize or 24
	t.TextColor3 = color or S.UI.White
	t.TextXAlignment = align or Enum.TextXAlignment.Center
	t.TextWrapped = true
	t.Parent = parent
	W.stroke(t, S.UI.Ink, fontSize and fontSize >= 30 and 3 or 2)
	return t
end
function W.icon(parent, name, asset, size, pos)
	local i = Instance.new("ImageLabel")
	i.Name = name
	i.Size = size
	i.Position = pos
	i.BackgroundTransparency = 1
	i.Image = asset
	i.ScaleType = Enum.ScaleType.Fit
	i.Parent = parent
	return i
end
function W.panel(parent, name, size, pos, color)
	local i = W.icon(parent, name, S.Skins.Panel, size, pos)
	i.ScaleType = Enum.ScaleType.Slice
	i.SliceCenter = S.PanelSlice
	i.SliceScale = S.PanelSliceScale
	i.ImageColor3 = color or S.UI.Cyan
	return i
end
function W.bar(parent, name, size, pos, color)
	local back = W.frame(parent, name, size, pos, S.UI.Ink, 9)
	W.stroke(back, Color3.fromRGB(24, 72, 125), 2)
	local fill = W.frame(back, "Fill", UDim2.fromScale(0, 1), UDim2.fromScale(0, 0), S.UI.White, 9)
	W.gradient(fill, color, color:Lerp(S.UI.Ink, 0.28))
	local shine = W.frame(fill, "Reflexo", UDim2.new(1, -6, 0.35, 0), UDim2.fromOffset(3, 2), S.UI.White, 4)
	shine.BackgroundTransparency = 0.5
	return back, fill
end
return W
