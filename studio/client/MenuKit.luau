-- Shared menu grammar: surfaces, hierarchy, input feedback. No game rules or remotes.
local TweenService = game:GetService("TweenService")
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local Audio = require(script.Parent.AudioFeedback)
local T = require(game.ReplicatedStorage.HACShared.MenuTheme)
local Kit = { Theme = T }

function Kit.Label(parent, name, value, size, position, fontSize, color, align)
	local label = W.text(parent, name, value, size, position, fontSize or 20, color, align)
	label.ZIndex = parent.ZIndex + 2
	return label
end

function Kit.Surface(parent, name, size, position, color)
	local surface = W.frame(parent, name, size, position, color or T.Surface, 8)
	surface.ZIndex = (parent:IsA("GuiObject") and parent.ZIndex or 0) + 1
	W.stroke(surface, T.Ink, 3)
	W.gradient(surface, Color3.new(1, 1, 1), Color3.fromRGB(135, 155, 180))
	local studs = W.icon(surface, "Studs", T.Studs, UDim2.new(1, -4, 1, -4), UDim2.fromOffset(2, 2))
	studs.ScaleType, studs.TileSize = Enum.ScaleType.Tile, UDim2.fromOffset(128, 128)
	studs.ImageTransparency = 0.88
	studs.ZIndex = surface.ZIndex
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 7), studs
	return surface
end

function Kit.Scroller(parent, name)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name, scroll.BackgroundTransparency, scroll.BorderSizePixel = name, 1, 0
	scroll.AutomaticCanvasSize, scroll.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
	scroll.ScrollBarThickness, scroll.ScrollBarImageColor3 = 5, W.Style.UI.Cyan
	scroll.ZIndex, scroll.Parent = parent.ZIndex + 1, parent
	local padding = Instance.new("UIPadding")
	padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 4), UDim.new(0, 8)
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 4), UDim.new(0, 10)
	padding.Parent = scroll
	local list = Instance.new("UIListLayout")
	list.Padding, list.SortOrder, list.Parent = UDim.new(0, T.Gap), Enum.SortOrder.LayoutOrder, scroll
	return scroll
end

function Kit.Action(parent, key, caption, callback, size, position, color)
	local skin = Button.new(parent, {
		name = key,
		text = caption,
		textSize = 20,
		size = size or UDim2.new(1, 0, 0, 48),
		position = position or UDim2.new(),
		color = color or W.Style.UI.Green,
		zIndex = parent.ZIndex + 3,
	})
	skin.Root:SetAttribute("FocusKey", key)
	skin.Root.Activated:Connect(callback)
	return skin
end

function Kit.Window(parent, close)
	local root = Kit.Surface(parent, "CollectionWindow", UDim2.fromOffset(1000, 660), UDim2.fromScale(0.5, 0.5), T.Body)
	root.AnchorPoint, root.ZIndex, root.Visible = Vector2.new(0.5, 0.5), 22, false
	local header =
		Kit.Surface(root, "Header", UDim2.new(1, -12, 0, T.HeaderHeight), UDim2.fromOffset(6, 6), W.Style.UI.Cyan)
	header.ClipsDescendants = true
	for i = 1, 3 do
		local slash = W.frame(header, "Ribbon", UDim2.fromOffset(36, 180), UDim2.new(0.55, i * 68, 0, -50), T.White)
		slash.Rotation, slash.BackgroundTransparency, slash.ZIndex = 34, 0.87, header.ZIndex + 1
	end
	local title = Kit.Label(
		header,
		"Title",
		"",
		UDim2.new(1, -100, 0, 44),
		UDim2.fromOffset(16, 22),
		36,
		nil,
		Enum.TextXAlignment.Left
	)
	title.TextScaled = true
	local cap = Instance.new("UITextSizeConstraint")
	cap.MinTextSize, cap.MaxTextSize, cap.Parent = 20, 36, title
	local tag = Kit.Label(
		header,
		"Tag",
		"",
		UDim2.new(1, -90, 0, 18),
		UDim2.fromOffset(18, 7),
		12,
		T.White,
		Enum.TextXAlignment.Left
	)
	local closeButton =
		Kit.Action(header, "Close", "X", close, UDim2.fromOffset(58, 58), UDim2.new(1, -67, 0, 10), W.Style.UI.Red)
	closeButton.caption:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize = 35
	local scroll = Kit.Scroller(root, "Content")
	local detail = Kit.Scroller(root, "Detail")
	detail.Visible = false
	local footer = Kit.Label(root, "Footer", "", UDim2.new(1, -32, 0, 26), UDim2.new(0, 16, 1, -30), 14, T.Muted)
	return {
		root = root,
		header = title,
		headerSurface = header,
		tag = tag,
		close = closeButton,
		scroll = scroll,
		detail = detail,
		footer = footer,
	}
end

function Kit.Layout(ui, split)
	local wide = split and ui.root.Size.X.Offset >= T.SplitWidth
	local top, bottom = T.HeaderHeight + 20, T.FooterHeight + 4
	ui.scroll.Position = UDim2.fromOffset(T.Padding, top)
	ui.scroll.Size = wide and UDim2.new(0.62, -22, 1, -top - bottom) or UDim2.new(1, -T.Padding * 2, 1, -top - bottom)
	ui.detail.Visible = wide
	ui.detail.Position, ui.detail.Size = UDim2.new(0.62, 0, 0, top), UDim2.new(0.38, -T.Padding, 1, -top - bottom)
	ui.contentWidth = wide and ui.root.Size.X.Offset * 0.62 - 36 or ui.root.Size.X.Offset - T.Padding * 2 - 14
	return wide
end

function Kit.Detail(ui)
	if Kit.Layout(ui, true) then
		return ui.detail
	end
	-- Compact screens keep the selected actions immediately above the gallery.
	local host = W.frame(ui.scroll, "SelectedDetails", UDim2.new(1, -2, 0, 0), UDim2.new())
	host.AutomaticSize, host.LayoutOrder, host.ZIndex = Enum.AutomaticSize.Y, 3, ui.scroll.ZIndex
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, T.Gap), Enum.SortOrder.LayoutOrder, host
	return host
end

function Kit.Grid(parent, count, width, minWidth, height, order)
	local columns = math.max(1, math.floor((width + T.Gap) / (minWidth + T.Gap)))
	local grid =
		W.frame(parent, "Gallery", UDim2.new(1, -2, 0, math.ceil(count / columns) * (height + T.Gap)), UDim2.new())
	grid.LayoutOrder, grid.ZIndex = order or 4, parent.ZIndex
	local layout = Instance.new("UIGridLayout")
	layout.CellSize, layout.CellPadding = UDim2.new(1 / columns, -T.Gap, 0, height), UDim2.fromOffset(T.Gap, T.Gap)
	layout.SortOrder, layout.Parent = Enum.SortOrder.LayoutOrder, grid
	return grid
end

function Kit.Badge(parent, name, value, size, position, color)
	local box = W.frame(parent, name, size, position, T.Ink, 6)
	box.ZIndex, box.BackgroundTransparency = parent.ZIndex + 3, 0.12
	Kit.Label(box, "Value", value, UDim2.new(1, -8, 1, 0), UDim2.fromOffset(4, 0), 14, color or T.White)
	return box
end

function Kit.Stat(parent, name, icon, value, x, y, width)
	local card = Kit.Surface(parent, name, UDim2.new(width or 0.5, -12, 0, 49), UDim2.new(x, 6, 0, y), T.Body)
	local pic = W.icon(card, "Icon", icon, UDim2.fromOffset(34, 34), UDim2.fromOffset(6, 7))
	pic.ZIndex = card.ZIndex + 1
	local label = Kit.Label(card, "Value", value, UDim2.new(1, -48, 1, -4), UDim2.fromOffset(43, 2), 18)
	label.TextScaled = true
	local cap = Instance.new("UITextSizeConstraint")
	cap.MinTextSize, cap.MaxTextSize, cap.Parent = 12, 19, label
	return card
end

function Kit.Selectable(tile, key, selected, callback, portrait)
	local rim = tile:FindFirstChildOfClass("UIStroke") or W.stroke(tile)
	rim.Color, rim.Thickness = selected and W.Style.UI.Gold or T.Ink, selected and 3 or 2
	local click = Instance.new("TextButton")
	click.Name, click.Text, click.BackgroundTransparency = "Select", "", 1
	click.Size, click.ZIndex, click.AutoButtonColor = UDim2.fromScale(1, 1), tile.ZIndex + 10, false
	click:SetAttribute("FocusKey", key)
	click.Parent = tile
	local tween
	local function hover(active)
		if portrait then
			portrait:SetAttribute("Hovered", active)
		end
		if tween then
			tween:Cancel()
		end
		tween = TweenService:Create(rim, TweenInfo.new(0.15), {
			Color = active and T.White or selected and W.Style.UI.Gold or T.Ink,
			Thickness = active and 4 or selected and 3 or 2,
		})
		tween:Play()
	end
	click.MouseEnter:Connect(function()
		hover(true)
	end)
	click.MouseLeave:Connect(function()
		hover(false)
	end)
	click.SelectionGained:Connect(function()
		hover(true)
	end)
	click.SelectionLost:Connect(function()
		hover(false)
	end)
	click.Activated:Connect(function()
		Audio.Play("Click")
		callback()
	end)
	tile.Destroying:Connect(function()
		if tween then
			tween:Cancel()
		end
	end)
	return click
end

function Kit.Empty(parent, title, subtitle)
	local panel = Kit.Surface(parent, "EmptyState", UDim2.new(1, -2, 0, 190), UDim2.new(), T.Body)
	panel.LayoutOrder = 5
	local art = W.icon(panel, "Bag", W.Style.Icons.Bag, UDim2.fromOffset(78, 78), UDim2.new(0.5, -39, 0, 10))
	art.ZIndex = panel.ZIndex + 1
	Kit.Label(panel, "Title", title, UDim2.new(1, -24, 0, 36), UDim2.fromOffset(12, 90), 24)
	Kit.Label(panel, "Subtitle", subtitle or "", UDim2.new(1, -32, 0, 50), UDim2.fromOffset(16, 128), 16, T.Muted)
end

return Kit
