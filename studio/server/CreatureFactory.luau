local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Style = require(ReplicatedStorage.HACShared.VisualStyle)
local C = require(ReplicatedStorage.HACShared.GameplayConfig)
local Colors = Style.Colors
local Factory = {}

local PALETTES = {
	Normal = {
		Main = Color3.fromRGB(12, 211, 255),
		Secondary = Color3.fromRGB(196, 248, 255),
		Accent = Color3.fromRGB(0, 112, 168),
		Ink = Color3.fromRGB(3, 12, 40),
		Glint = Color3.fromRGB(255, 255, 255),
	},
	Golden = {
		Main = Colors.Gold,
		Secondary = Colors.White,
		Accent = Color3.fromRGB(214, 142, 28),
		Ink = Color3.fromRGB(3, 12, 40),
		Glint = Color3.fromRGB(255, 255, 255),
	},
}

local FALLBACK_PARTS = {
	{ name = "Pe", role = "Main", side = "L", sz = Vector3.new(0.7928, 0.3542, 1.0747), pos = Vector3.new(0.5260, -1.3889, -0.1212) },
	{ name = "Sole_L", role = "Accent", side = "L", sz = Vector3.new(0.8849, 0.0826, 1.1863), pos = Vector3.new(0.5195, -1.5837, -0.1416) },
	{ name = "Stud_Foot_L", role = "Main", side = "L", sz = Vector3.new(0.3026, 0.0972, 0.3026), pos = Vector3.new(0.5293, -1.1632, -0.0715) },
	{ name = "Pe", role = "Main", side = "R", sz = Vector3.new(0.7928, 0.3542, 1.0747), pos = Vector3.new(-0.5260, -1.3889, -0.1212) },
	{ name = "Sole_R", role = "Accent", side = "R", sz = Vector3.new(0.8849, 0.0826, 1.1863), pos = Vector3.new(-0.5195, -1.5837, -0.1416) },
	{ name = "Stud_Foot_R", role = "Main", side = "R", sz = Vector3.new(0.3026, 0.0972, 0.3026), pos = Vector3.new(-0.5293, -1.1632, -0.0715) },
	{ name = "Torso", role = "Main", side = "", sz = Vector3.new(1.4447, 0.8500, 1.1692), pos = Vector3.new(0.0000, -0.9403, 0.0785) },
	{ name = "Belly", role = "Secondary", side = "", sz = Vector3.new(0.9277, 0.5809, 0.1810), pos = Vector3.new(0.0000, -0.9568, -0.4316) },
	{ name = "Arm_L", role = "Main", side = "", sz = Vector3.new(0.4367, 0.5879, 0.4809), pos = Vector3.new(0.7193, -0.9839, -0.2122) },
	{ name = "Arm_R", role = "Main", side = "", sz = Vector3.new(0.4367, 0.5879, 0.4809), pos = Vector3.new(-0.7193, -0.9839, -0.2122) },
	{ name = "Tail", role = "Main", side = "", sz = Vector3.new(0.4457, 0.5140, 0.5416), pos = Vector3.new(0.0000, -0.9912, 0.7190) },
	{ name = "Tail_Tip", role = "Accent", side = "", sz = Vector3.new(0.3279, 0.4074, 0.4043), pos = Vector3.new(0.0000, -0.7412, 1.0091) },
	{ name = "Head", role = "Main", side = "", sz = Vector3.new(2.6311, 1.9104, 2.1911), pos = Vector3.new(-0.1795, 0.1770, -0.2343) },
	{ name = "Snout", role = "Secondary", side = "", sz = Vector3.new(1.1858, 0.6233, 0.5159), pos = Vector3.new(0.0753, -0.3858, -0.7570) },
	{ name = "Mouth", role = "Ink", side = "", sz = Vector3.new(0.5079, 0.1111, 0.2520), pos = Vector3.new(0.0865, -0.4403, -0.7997) },
	{ name = "Fang", role = "Glint", side = "", sz = Vector3.new(0.1464, 0.1426, 0.1489), pos = Vector3.new(0.0019, -0.5545, -0.7573) },
	{ name = "Eye_L", role = "Ink", side = "", sz = Vector3.new(0.3529, 0.4326, 0.2633), pos = Vector3.new(0.4913, 0.2356, -0.9994) },
	{ name = "EyeGlint_L", role = "Glint", side = "", sz = Vector3.new(0.1171, 0.1248, 0.0956), pos = Vector3.new(0.4320, 0.3056, -1.1144) },
	{ name = "Eye_R", role = "Ink", side = "", sz = Vector3.new(0.3917, 0.1704, 0.1986), pos = Vector3.new(-0.4383, 0.0144, -1.1688) },
	{ name = "Crest_Top", role = "Accent", side = "", sz = Vector3.new(0.7433, 0.3179, 1.2340), pos = Vector3.new(-0.3083, 0.9009, -0.3630) },
	{ name = "Stud_Crest_0", role = "Accent", side = "", sz = Vector3.new(0.3041, 0.1621, 0.3060), pos = Vector3.new(-0.2592, 0.9574, -0.7222) },
	{ name = "Stud_Crest_1", role = "Accent", side = "", sz = Vector3.new(0.3041, 0.1621, 0.3060), pos = Vector3.new(-0.3293, 0.9933, -0.3769) },
	{ name = "Stud_Crest_2", role = "Accent", side = "", sz = Vector3.new(0.3041, 0.1621, 0.3060), pos = Vector3.new(-0.3993, 1.0292, -0.0316) },
	{ name = "Crest_BackUpper", role = "Accent", side = "", sz = Vector3.new(0.5534, 0.4243, 0.3406), pos = Vector3.new(-0.4345, 0.8032, 0.4933) },
	{ name = "Crest_BackMid", role = "Accent", side = "", sz = Vector3.new(0.6241, 0.7688, 0.2545), pos = Vector3.new(-0.3297, 0.3214, 0.6727) },
	{ name = "Ear_L_Base", role = "Main", side = "", sz = Vector3.new(0.8082, 0.6324, 0.4958), pos = Vector3.new(0.4499, 1.2411, -0.1094) },
	{ name = "Ear_L_Inner", role = "Accent", side = "", sz = Vector3.new(0.4871, 0.5333, 0.1476), pos = Vector3.new(0.4946, 1.2550, -0.2901) },
	{ name = "Ear_L_Tip", role = "Main", side = "", sz = Vector3.new(0.6835, 0.5744, 0.4260), pos = Vector3.new(0.4799, 1.7348, -0.0584) },
	{ name = "Ear_L_TipInner", role = "Accent", side = "", sz = Vector3.new(0.4238, 0.4490, 0.2036), pos = Vector3.new(0.5123, 1.7166, -0.1834) },
	{ name = "Ear_R_Base", role = "Main", side = "", sz = Vector3.new(0.8471, 0.7824, 0.4076), pos = Vector3.new(-1.1703, 0.8346, -0.3820) },
	{ name = "Ear_R_Inner", role = "Accent", side = "", sz = Vector3.new(0.6047, 0.6165, 0.1279), pos = Vector3.new(-1.1571, 0.8471, -0.5814) },
	{ name = "Ear_R_Tip", role = "Main", side = "", sz = Vector3.new(0.6171, 0.6554, 0.3746), pos = Vector3.new(-1.5303, 1.0224, -0.4529) },
	{ name = "Ear_R_TipInner", role = "Accent", side = "", sz = Vector3.new(0.4549, 0.4193, 0.1901), pos = Vector3.new(-1.4571, 1.0322, -0.5984) },
}

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
	local palette = golden and PALETTES.Golden or PALETTES.Normal
	local template = ReplicatedStorage:FindFirstChild("HACLumitoTemplate")
	local model
	if template then
		model = template:Clone()
		local root = model:FindFirstChild("Root") or model.PrimaryPart
		local baseOrigin = root and root.CFrame or CFrame.new()
		for _, child in ipairs(model:GetDescendants()) do
			if child:IsA("BasePart") then
				local role = child:GetAttribute("ColorRole") or "Main"
				if child:IsA("UnionOperation") then
					child.UsePartColor = true
				end
				child.Color = palette[role] or palette.Main
				child.Material = Enum.Material.SmoothPlastic
				child.Anchored = true
				child.CanCollide = false
				if child.Name == "Root" then
					child.Transparency = 1
					child.CanTouch = false
					child.CanQuery = false
					child.CFrame = CFrame.new(position)
				elseif child.Name == "Corpo" then
					child.Transparency = 1
					child.CanTouch = false
					child.CanQuery = false
					child.CastShadow = false
					child.Size = Vector3.new(3.3, 2.8, 2.6) * scale
					child.CFrame = CFrame.new(position)
				else
					local rel = baseOrigin:ToObjectSpace(child.CFrame)
					child.Size = child.Size * scale
					child.CFrame = CFrame.new(position + rel.Position * scale) * rel.Rotation
				end
			end
		end
		if root then
			model.PrimaryPart = root
		end
	else
		model = Instance.new("Model")
		local root = part(model, "Root", Vector3.one, CFrame.new(position), palette.Main)
		root.Transparency = 1
		root.CanTouch = false
		root.CanQuery = false
		root:SetAttribute("ColorRole", "Main")
		model.PrimaryPart = root
		local corpo = part(model, "Corpo", Vector3.new(3.3, 2.8, 2.6) * scale, CFrame.new(position), palette.Main)
		corpo.Transparency = 1
		corpo.CanTouch = false
		corpo.CanQuery = false
		corpo.CastShadow = false
		corpo:SetAttribute("ColorRole", "Main")
		for _, d in ipairs(FALLBACK_PARTS) do
			local p = part(
				model,
				d.name,
				d.sz * scale,
				CFrame.new(position + d.pos * scale),
				palette[d.role] or palette.Main,
				Enum.Material.SmoothPlastic
			)
			p:SetAttribute("ColorRole", d.role)
			if d.side ~= "" then
				p:SetAttribute("FootSide", d.side)
			end
		end
	end
	model.Name = golden and "Golden Lumito" or "Lumito"
	model:SetAttribute("Golden", golden)
	model:SetAttribute("CreatureScale", scale)
	model.Parent = parent
	return model
end

local function addWildLabel(model, scale)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Identificacao"
	gui.Adornee = model.PrimaryPart
	gui.Size = UDim2.fromOffset(230, 46)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.25 * scale + 1.5, 0)
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
	return {
		id = HttpService:GenerateGUID(false),
		species = "Lumito",
		rarity = C.Species.Lumito.Rarity,
		size = C.RollSize(random),
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
		addWildLabel(model, item.size)
	end
	return model
end

Factory.Part = part
return Factory
