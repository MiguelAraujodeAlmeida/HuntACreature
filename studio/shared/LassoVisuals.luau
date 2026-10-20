-- Objetos visuais sem colisão; usados para carregar, voar, recolher e confirmar impacto.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(script.Parent.CaptureConfig)
local V = {}
local function part(parent, name, size, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = parent
	return p
end
function V.Loop(parent)
	local model = Instance.new("Model")
	model.Name = "LacoArremessado"
	local center = part(model, "Centro", Vector3.new(0.1, 0.1, 0.1), Color3.new(1, 1, 1))
	center.Transparency = 1
	model.PrimaryPart = center
	for i = 1, 20 do
		local angle = i * math.pi / 10
		local piece = part(model, "Corda", Vector3.new(0.14, 0.38, 0.14), Color3.fromRGB(255, 205, 70))
		piece.Material = Enum.Material.SmoothPlastic
		piece.CFrame = CFrame.new(math.cos(angle) * Config.LoopRadius, math.sin(angle) * Config.LoopRadius, 0) * CFrame.Angles(0, 0, angle)
	end
	model.Parent = parent
	return model
end
function V.Flight(model, power)
	local center = model.PrimaryPart
	local a = Instance.new("Attachment")
	a.Position = Vector3.new(-Config.LoopRadius * 0.8, 0, 0)
	a.Parent = center
	local b = Instance.new("Attachment")
	b.Position = Vector3.new(Config.LoopRadius * 0.8, 0, 0)
	b.Parent = center
	local trail = Instance.new("Trail")
	trail.Name = "TrilhaDoArremesso"
	trail.Attachment0, trail.Attachment1 = a, b
	trail.Lifetime = 0.12 + power * 0.1
	trail.MinLength = 0.4
	trail.FaceCamera = true
	trail.LightEmission = 0.4
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 228, 143), Color3.fromRGB(255, 191, 65))
	trail.Transparency = NumberSequence.new(0.25, 1)
	trail.Parent = center
end
function V.Returning(model, line)
	local trail = model.PrimaryPart:FindFirstChild("TrilhaDoArremesso")
	if trail then
		trail.Lifetime = 0.1
		trail.Color = ColorSequence.new(Color3.fromRGB(88, 220, 255), Color3.fromRGB(143, 244, 255))
	end
	for _, child in ipairs(model:GetChildren()) do
		if child.Name == "Corda" then
			child.Color = Color3.fromRGB(103, 213, 236)
			child.Transparency = 0.24
		end
	end
	if line then
		line.beam.Color = ColorSequence.new(Color3.fromRGB(105, 222, 244))
		line.beam.Width0, line.beam.Width1 = 0.09, 0.09
	end
end
function V.Line(character, part)
	local hand = character
		and (
			character:FindFirstChild("RightHand")
			or character:FindFirstChild("Right Arm")
			or character:FindFirstChild("HumanoidRootPart")
		)
	if not hand then
		return nil
	end
	local from = Instance.new("Attachment")
	from.Name = "HACLacoOrigem"
	from.Parent = hand
	local to = Instance.new("Attachment")
	to.Name = "HACLacoPonta"
	to.Parent = part
	local beam = Instance.new("Beam")
	beam.Name = "CordaDoLaco"
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.Width0 = 0.12
	beam.Width1 = 0.12
	beam.FaceCamera = true
	beam.Segments = 12
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 218, 100))
	beam.LightEmission = 0.2
	beam.Parent = from
	return { from = from, to = to, beam = beam }
end
function V.CleanupLine(line)
	if not line then
		return
	end
	line.from:Destroy()
	line.to:Destroy()
end
function V.Burst(parent, position, color, count)
	for i = 1, count do
		local angle = math.pi * 2 * i / count
		local spark = part(parent, "ImpactoLaco", Vector3.new(0.16, 0.16, 0.16), color)
		spark.Shape = Enum.PartType.Ball
		spark.Material = Enum.Material.Neon
		spark.Position = position
		TweenService:Create(spark, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = position + Vector3.new(math.cos(angle) * 1.7, 0.4 + (i % 3) * 0.25, math.sin(angle) * 1.7),
			Transparency = 1,
			Size = Vector3.new(0.03, 0.03, 0.03),
		}):Play()
		Debris:AddItem(spark, 0.35)
	end
end
return V

