-- Linguagem visual do protótipo. Centralizar mudanças de fonte e paleta aqui.
local Style = {}

Style.Font = Enum.Font.FredokaOne
Style.DisplayFont = Enum.Font.FredokaOne
Style.Colors = {
	Ink = Color3.fromRGB(19, 30, 43),
	White = Color3.fromRGB(255, 252, 240),
	Sun = Color3.fromRGB(255, 205, 72),
	Orange = Color3.fromRGB(240, 143, 67),
	Coral = Color3.fromRGB(229, 104, 74),
	Sky = Color3.fromRGB(57, 190, 211),
	Teal = Color3.fromRGB(24, 150, 153),
	Grass = Color3.fromRGB(105, 206, 120),
	DeepGrass = Color3.fromRGB(37, 140, 101),
	Purple = Color3.fromRGB(137, 120, 214),
	Gold = Color3.fromRGB(255, 220, 86),
	Rope = Color3.fromRGB(247, 214, 142),
}

-- Assets v4: imagens independentes, sem recortes da arte anterior.
Style.Icons = {
	Coin = "rbxassetid://137147969134175",
	XP = "rbxassetid://90531108912513",
	Strength = "rbxassetid://111581776806956",
	Bag = "rbxassetid://84667354571821",
	Lasso = "rbxassetid://117254148917574",
	HunterRank = "rbxassetid://94003376835794",
}
Style.Skins = { Tile = "rbxassetid://93505871377958", Panel = "rbxassetid://130734564577623" }
-- A importação do Roblox reduz o painel de 2172x724 para 1024x341.
Style.PanelSlice = Rect.new(150, 140, 874, 200)
Style.PanelSliceScale = 0.18
Style.UI = {
	Gold = Color3.fromRGB(255, 203, 20),
	Cyan = Color3.fromRGB(12, 211, 255),
	Purple = Color3.fromRGB(211, 108, 255),
	Green = Color3.fromRGB(59, 246, 29),
	Red = Color3.fromRGB(255, 72, 81),
	Ink = Color3.fromRGB(3, 12, 40),
	White = Color3.fromRGB(255, 255, 255),
	HoverScale = 1.06,
	PressScale = 0.94,
}
return Style

