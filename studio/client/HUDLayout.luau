-- Todas as medidas usam a área segura real do ScreenGui, em pixels de UI.
local Layout = {}
function Layout.Resolve(view, touch)
	local w, h = math.max(280, view.X), math.max(200, view.Y)
	local narrow = w < 560
	local short = h < 430
	local margin = short and 10 or 16
	local desktop = not touch and w >= 1000 and h >= 560
	local slot = short and 60 or 76
	local reserve = touch and not narrow and math.clamp(w * 0.17, 110, 170) or margin
	local centerWidth = math.min(610, w - reserve * 2)
	local panelHeight = short and 108 or 126
	local bottom = margin + slot + 12
	-- Em retrato, deixar os dois polegares livres abaixo da disputa.
	if touch and narrow then bottom = math.max(bottom, 176) end
	return {
		width = w, height = h, margin = margin, narrow = narrow, short = short,
		desktop = desktop, touch = touch, slot = slot,
		bag = short and 64 or (narrow and 68 or 86),
		centerWidth = centerWidth, captureHeight = panelHeight,
		captureBottom = bottom, chargeBottom = bottom,
		resourceMode = desktop and "stack" or (narrow and "narrow" or "row"),
		resourceHeight = short and 44 or 52,
	}
end
return Layout
