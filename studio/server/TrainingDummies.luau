-- Visual catalogue. Add a new entry for each future dummy level; economy stays in GameplayConfig.
local Dummies = {}
local tiers = {
	{ name = "Hay Scout", main = Color3.fromRGB(237, 190, 80), accent = Color3.fromRGB(119, 77, 47), head = Enum.PartType.Ball },
	{ name = "Wood Ranger", main = Color3.fromRGB(167, 101, 54), accent = Color3.fromRGB(255, 200, 78), head = Enum.PartType.Block },
	{ name = "Iron Guard", main = Color3.fromRGB(92, 126, 148), accent = Color3.fromRGB(255, 173, 54), head = Enum.PartType.Block },
	{ name = "Clockwork Champion", main = Color3.fromRGB(53, 155, 195), accent = Color3.fromRGB(255, 213, 59), head = Enum.PartType.Ball },
}

local function piece(model, name, size, cf, color, shape)
	local part = Instance.new("Part")
	part.Name, part.Size, part.CFrame = name, size, cf
	part.Color, part.Shape = color, shape or Enum.PartType.Block
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.CastShadow = false
	part.Parent = model
	return part
end

function Dummies.Build(base, level, efficiency)
	local station = base.Esteira
	local existing = base:FindFirstChild("Manequim")
	if existing then existing:Destroy() end
	local tier = tiers[math.clamp(level, 1, #tiers)]
	local model = Instance.new("Model")
	model.Name = "Manequim"
	model:SetAttribute("TrainingLevel", level)
	local center = station.Position + Vector3.new(0, 2, -1.5)
	local anchor = CFrame.new(center)
	local body = piece(model, "Alvo", Vector3.new(1.4, 2.15, 0.85), anchor, tier.main)
	model.PrimaryPart = body
	local head = piece(model, "Cabeca", level == 1 and Vector3.new(1.3, 1.2, 1.15) or Vector3.new(1.15, 1.15, 1.15),
		anchor * CFrame.new(0, 1.64, 0), tier.accent, tier.head)
	for side = -1, 1, 2 do
		piece(model, "Arm" .. side, Vector3.new(0.58, 1.55, 0.58),
			anchor * CFrame.new(side * 1.08, 0.15, 0) * CFrame.Angles(0, 0, side * 0.18), tier.main)
		piece(model, "Foot" .. side, Vector3.new(0.64, 1.05, 0.72),
			anchor * CFrame.new(side * 0.43, -1.57, 0), tier.accent)
	end
	if level == 1 then
		piece(model, "StrawHat", Vector3.new(1.8, 0.19, 1.55), head.CFrame * CFrame.new(0, 0.65, 0), tier.accent)
		piece(model, "Patch", Vector3.new(0.55, 0.55, 0.1), anchor * CFrame.new(0.3, 0.1, -0.47), tier.accent)
	elseif level == 2 then
		piece(model, "WoodCap", Vector3.new(1.42, 0.34, 1.3), head.CFrame * CFrame.new(0, 0.62, 0), tier.accent)
		for side = -1, 1, 2 do
			piece(model, "Joint" .. side, Vector3.new(0.55, 0.55, 0.55), anchor * CFrame.new(side * 0.8, 0.65, -0.08), tier.accent, Enum.PartType.Ball)
		end
	elseif level == 3 then
		piece(model, "ChestPlate", Vector3.new(1.6, 1.4, 0.24), anchor * CFrame.new(0, 0.1, -0.53), tier.accent)
		piece(model, "Helmet", Vector3.new(1.42, 0.5, 1.3), head.CFrame * CFrame.new(0, 0.46, 0), tier.main)
		piece(model, "Shield", Vector3.new(0.95, 1.28, 0.25), anchor * CFrame.new(1.28, 0.18, -0.47), tier.accent)
	else
		piece(model, "Core", Vector3.new(0.78, 0.78, 0.2), anchor * CFrame.new(0, 0.13, -0.52), tier.accent, Enum.PartType.Ball).Material = Enum.Material.Neon
		piece(model, "Crown", Vector3.new(1.36, 0.3, 1.25), head.CFrame * CFrame.new(0, 0.66, 0), tier.accent)
		for side = -1, 1, 2 do
			piece(model, "Gear" .. side, Vector3.new(0.68, 0.68, 0.25), anchor * CFrame.new(side * 0.91, 0.65, -0.08), tier.accent, Enum.PartType.Cylinder)
		end
	end
	local face = piece(model, "Face", Vector3.new(0.85, 0.16, 0.12), head.CFrame * CFrame.new(0, 0.02, -0.6), Color3.fromRGB(18, 29, 49))
	face.Material = Enum.Material.SmoothPlastic
	model.Parent = base
	local old = station:FindFirstChild("TrainingPlatformVisual")
	if old then old:Destroy() end
	local platform = piece(station, "TrainingPlatformVisual", Vector3.new(4.1, 0.16, 4.1),
		station.CFrame * CFrame.new(0, station.Size.Y / 2 + 0.1, -1), tier.accent)
	platform.Material = efficiency > 1 and Enum.Material.Neon or Enum.Material.SmoothPlastic
	platform.Transparency = efficiency > 2 and 0.15 or 0.4
	local oldRig = station:FindFirstChild("EfficiencyRig")
	if oldRig then oldRig:Destroy() end
	local equipment = Instance.new("Model")
	equipment.Name = "EfficiencyRig"
	equipment.Parent = station
	if efficiency >= 2 then
		for side = -1, 1, 2 do
			piece(equipment, "GuidePost" .. side, Vector3.new(0.24, 2.1, 0.24),
				station.CFrame * CFrame.new(side * 2.1, 1.05, -1), tier.accent)
		end
	end
	if efficiency >= 3 then
		piece(equipment, "PracticeArch", Vector3.new(4.2, 0.22, 0.32),
			station.CFrame * CFrame.new(0, 2.15, -1), tier.accent)
	end
	if efficiency >= 4 then
		for side = -1, 1, 2 do
			local lamp = piece(equipment, "FocusLamp" .. side, Vector3.new(0.52, 0.52, 0.52),
				station.CFrame * CFrame.new(side * 2.1, 2.3, -1), Color3.fromRGB(255, 215, 88), Enum.PartType.Ball)
			lamp.Material = Enum.Material.Neon
		end
	end
	return model, tier
end

return Dummies
