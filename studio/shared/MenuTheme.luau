-- Presentation only. GameplayConfig remains the authority for rules and prices.
local S = require(script.Parent.VisualStyle)
local T = {
	Studs = "rbxassetid://133050717017276",
	Ink = Color3.fromRGB(8, 14, 31),
	Body = Color3.fromRGB(28, 35, 56),
	Surface = Color3.fromRGB(43, 56, 78),
	Muted = Color3.fromRGB(178, 203, 224),
	White = S.UI.White,
	HeaderHeight = 78,
	FooterHeight = 34,
	Padding = 16,
	Gap = 12,
	SplitWidth = 740,
	Pages = {
		Index = { Accent = S.UI.Cyan, Tag = "FIELD JOURNAL", Width = 1000, Height = 660 },
		HunterRank = { Accent = S.UI.Purple, Tag = "HUNTER LICENSE", Width = 790, Height = 660 },
		Criaturas = { Accent = S.UI.Cyan, Tag = "YOUR COMPANIONS", Width = 1000, Height = 660 },
		Venda = { Accent = S.UI.Gold, Tag = "CREATURE MARKET", Width = 1000, Height = 660 },
		Loja = { Accent = S.UI.Green, Tag = "HUNTER SUPPLIES", Width = 1000, Height = 660 },
		Settings = { Accent = Color3.fromRGB(178, 218, 249), Tag = "MAKE IT YOURS", Width = 800, Height = 450 },
	},
	Rarity = {
		Comum = Color3.fromRGB(102, 183, 131),
		Rara = Color3.fromRGB(34, 150, 255),
		["Épica"] = Color3.fromRGB(190, 81, 255),
		["Mítica"] = Color3.fromRGB(255, 89, 160),
		["Lendária"] = S.UI.Gold,
		Secreta = Color3.fromRGB(239, 88, 62),
		Divina = Color3.fromRGB(235, 238, 255),
	},
	Tools = {
		Isca = { Accent = Color3.fromRGB(255, 188, 54), Tag = "LURE" },
		Armadilha = { Accent = S.UI.Cyan, Tag = "CONTROL" },
		Pocao = { Accent = S.UI.Purple, Tag = "CALM" },
		LacoTreino = { Accent = S.UI.Gold, Tag = "STARTER" },
	},
}
function T.Page(id)
	return T.Pages[id] or T.Pages.Criaturas
end
function T.Creature(item)
	if table.find(item.mutations or {}, "Dourado") then
		return S.UI.Gold
	end
	return T.Rarity[item.rarity] or T.Rarity.Comum
end
return T
