-- Linguagem visual do protótipo. Centralizar mudanças de fonte e paleta aqui.
local Style = {}

Style.Font = Enum.Font.GothamBold
Style.DisplayFont = Enum.Font.GothamBlack
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

Style.ResourceIconSheet = "rbxassetid://107528171876427"
Style.SatchelIcon = "rbxassetid://129286908163718"
-- Roblox reduz esta textura de 2172x724 para 1024x341 na importação.
Style.IconCellSize = Vector2.new(341, 341)
Style.Outline = 2
Style.Corner = 12

-- Botões: acabamento e movimento independentes das regras de jogo.
Style.Button = {
	Font = Enum.Font.FredokaOne,
	Outline = Color3.fromRGB(5, 16, 47),
	HoverScale = 1.055,
	PressScale = 0.94,
	HoverSeconds = 0.16,
	ReleaseSeconds = 0.26,
	Palettes = {
		Cyan = {
			Rim = Color3.fromRGB(10, 238, 255),
			Top = Color3.fromRGB(29, 218, 255),
			Bottom = Color3.fromRGB(0, 105, 240),
			Edge = Color3.fromRGB(22, 77, 203),
			Plate = Color3.fromRGB(8, 35, 100),
		},
		Gold = {
			Rim = Color3.fromRGB(255, 244, 102),
			Top = Color3.fromRGB(255, 231, 39),
			Bottom = Color3.fromRGB(255, 146, 0),
			Edge = Color3.fromRGB(177, 80, 8),
			Plate = Color3.fromRGB(91, 43, 6),
		},
		Coral = {
			Rim = Color3.fromRGB(255, 185, 164),
			Top = Color3.fromRGB(255, 115, 104),
			Bottom = Color3.fromRGB(218, 43, 76),
			Edge = Color3.fromRGB(128, 29, 53),
			Plate = Color3.fromRGB(91, 22, 47),
		},
	},
}
return Style
