-- Small original geometric symbols, readable without another image dependency.
local W = require(script.Parent.HUDWidgets)
local Glyph = {}
function Glyph.new(parent, kind)
	local root = W.frame(parent, "Glyph", UDim2.fromOffset(26, 26), UDim2.new(0, 7, 0.5, -13))
	if kind == "gear" then
		for i = 0, 7 do
			local angle = i * math.pi / 4
			local tooth = W.frame(
				root,
				"Tooth",
				UDim2.fromOffset(8, 8),
				UDim2.fromOffset(13 + math.cos(angle) * 9, 13 + math.sin(angle) * 9),
				Color3.fromRGB(208, 230, 255),
				2
			)
			tooth.AnchorPoint = Vector2.new(0.5, 0.5)
			tooth.Rotation = i * 45
		end
		local outer = W.frame(
			root,
			"Gear",
			UDim2.fromOffset(21, 21),
			UDim2.fromOffset(2.5, 2.5),
			Color3.fromRGB(208, 230, 255),
			20
		)
		W.gradient(outer, Color3.new(1, 1, 1), Color3.fromRGB(118, 157, 200))
		local center = W.frame(root, "Center", UDim2.fromOffset(9, 9), UDim2.fromOffset(8.5, 8.5), W.Style.UI.Ink, 10)
		W.stroke(center, W.Style.UI.Cyan, 1)
	else
		local book =
			W.frame(root, "Book", UDim2.fromOffset(22, 25), UDim2.fromOffset(2, 0), Color3.fromRGB(255, 231, 143), 4)
		W.stroke(book, W.Style.UI.Ink, 2)
		W.frame(book, "Spine", UDim2.new(0, 4, 1, -2), UDim2.fromOffset(1, 1), Color3.fromRGB(200, 123, 43), 2)
		W.text(book, "Emblem", "★", UDim2.fromOffset(16, 19), UDim2.fromOffset(5, 1), 15, W.Style.UI.Gold)
	end
	return root
end
return Glyph
