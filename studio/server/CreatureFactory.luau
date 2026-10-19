local Style = require(game.ReplicatedStorage.HACShared.VisualStyle)
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local HttpService = game:GetService("HttpService")
local Colors = Style.Colors
local Factory = {}
local function part(parent, name, size, cframe, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = false
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

local function makeCreature(parent, position, golden, scale)
	local model = Instance.new("Model")
	model.Name = golden and "Golden Lumito" or "Lumito"
	model:SetAttribute("Golden", golden)
	model:SetAttribute("CreatureScale", scale)
	model.Parent = parent
	local mainColor = golden and Colors.Gold or Colors.Sky
	local bellyColor = golden and Colors.White or Color3.fromRGB(191, 255, 242)
	local root = part(model, "Root", Vector3.one, CFrame.new(position), mainColor)
	root.Transparency = 1
	model.PrimaryPart = root
	part(
		model,
		"Corpo",
		Vector3.new(3.3, 2.8, 2.6) * scale,
		CFrame.new(position),
		mainColor,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	part(
		model,
		"Barriga",
		Vector3.new(2.5, 1.65, 0.35) * scale,
		CFrame.new(position + Vector3.new(0, -0.35 * scale, -1.18 * scale)),
		bellyColor,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	for _, side in ipairs({ -1, 1 }) do
		part(
			model,
			"Orelha",
			Vector3.new(0.75, 1.6, 0.7) * scale,
			CFrame.new(position + Vector3.new(side * 1.02 * scale, 1.44 * scale, 0)),
			mainColor,
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
		part(
			model,
			"Olho",
			Vector3.new(0.37, 0.48, 0.2) * scale,
			CFrame.new(position + Vector3.new(side * 0.63 * scale, 0.34 * scale, -1.22 * scale)),
			Colors.Ink,
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
		part(
			model,
			"BrilhoOlho",
			Vector3.new(0.13, 0.15, 0.08) * scale,
			CFrame.new(position + Vector3.new(side * 0.58 * scale, 0.46 * scale, -1.34 * scale)),
			Colors.White,
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		part(
			model,
			"Pe",
			Vector3.new(0.9, 0.55, 0.9) * scale,
			CFrame.new(position + Vector3.new(side * 0.85 * scale, -1.35 * scale, -0.45 * scale)),
			mainColor,
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
		part(
			model,
			"Bochecha",
			Vector3.new(0.34, 0.18, 0.08) * scale,
			CFrame.new(position + Vector3.new(side * 0.95 * scale, -0.22 * scale, -1.12 * scale)),
			Colors.Coral,
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
	end
	part(
		model,
		"Nariz",
		Vector3.new(0.32, 0.25, 0.2) * scale,
		CFrame.new(position + Vector3.new(0, -0.08 * scale, -1.35 * scale)),
		Colors.Ink,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	return model
end

local function addWildLabel(model)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Identificacao"
	gui.Adornee = model.PrimaryPart
	gui.Size = UDim2.fromOffset(230, 46)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 65
	gui.Parent = model.PrimaryPart
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = model.Name
	text.TextColor3 = model:GetAttribute("Golden") and Colors.Gold or Colors.White
	text.TextStrokeColor3 = Colors.Ink
	text.TextStrokeTransparency = 0
	text.TextScaled = true
	text.Font = Style.Font
	text.Parent = gui
end

function Factory.Roll(random)
	local roll, size = random:NextInteger(1, 100), C.Sizes[2]
	for _, entry in ipairs(C.Sizes) do
		roll -= entry.Weight
		if roll <= 0 then
			size = entry
			break
		end
	end
	return {
		id = HttpService:GenerateGUID(false),
		species = "Lumito",
		rarity = C.Species.Lumito.Rarity,
		size = size.Scale,
		mutations = random:NextNumber() < C.Mutations.Dourado.Chance and { "Dourado" } or {},
		location = "bag",
	}
end
function Factory.Build(parent, position, item, installed)
	local golden = table.find(item.mutations, "Dourado") ~= nil
	local model = makeCreature(parent, position, golden, item.size * (installed and 0.72 or 1))
	model.Name = C.Name(item)
	model:SetAttribute("CreatureId", item.id)
	model:SetAttribute("Species", item.species)
	model:SetAttribute("MinimumStrength", C.MinimumStrength(item.species))
	model:SetAttribute("Rarity", item.rarity)
	model:SetAttribute("SizeFactor", item.size)
	model:SetAttribute("Difficulty", (golden and C.Mutations.Dourado.Difficulty or 1) * (0.9 + item.size * 0.1))
	if not installed then
		addWildLabel(model)
	end
	return model
end
Factory.Part = part
return Factory
