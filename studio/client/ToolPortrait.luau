-- Small toy-like shop previews. Decorative only; never creates gameplay tools.
local TweenService = game:GetService("TweenService")
local W = require(script.Parent.HUDWidgets)
local Art = {}
function Art.new(parent, id, size, position)
	if id == "LacoTreino" then
		local icon = W.icon(parent, "LassoArt", W.Style.Icons.Lasso, size, position)
		icon.ZIndex = parent.ZIndex + 1
		return icon
	end
	local view = Instance.new("ViewportFrame")
	view.Name, view.Size, view.Position, view.BackgroundTransparency = "ToolArt", size, position, 1
	view.ZIndex, view.Parent = parent.ZIndex + 1, parent
	view.Ambient, view.LightColor = Color3.fromRGB(210, 218, 243), Color3.fromRGB(255, 249, 222)
	view.LightDirection = Vector3.new(-1, -1, -2)
	local world = Instance.new("WorldModel")
	world.Parent = view
	local function part(name, shape, scale, cf, color)
		local p = Instance.new("Part")
		p.Name, p.Shape, p.Size, p.CFrame = name, shape, scale, cf
		p.Color, p.Material = color, Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.Parent = world
		return p
	end
	local ball, block, cylinder = Enum.PartType.Ball, Enum.PartType.Block, Enum.PartType.Cylinder
	local gold, purple, cyan = W.Style.UI.Gold, W.Style.UI.Purple, W.Style.UI.Cyan
	if id == "Isca" then
		part(
			"Bowl",
			cylinder,
			Vector3.new(0.45, 2.6, 2.6),
			CFrame.new(0, -0.7, 0) * CFrame.Angles(0, 0, math.pi / 2),
			gold
		)
		for i = 1, 5 do
			local a = i * math.pi * 2 / 5
			part(
				"Berry",
				ball,
				Vector3.new(1.05, 1.05, 1.05),
				CFrame.new(math.cos(a) * 0.65, -0.05, math.sin(a) * 0.65),
				Color3.fromRGB(255, 111 + i * 12, 44)
			)
		end
		part(
			"Leaf",
			ball,
			Vector3.new(1.1, 0.25, 0.5),
			CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, 0.4),
			W.Style.UI.Green
		)
	elseif id == "Armadilha" then
		part(
			"Plate",
			cylinder,
			Vector3.new(0.35, 3.1, 3.1),
			CFrame.new(0, -0.8, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(45, 78, 110)
		)
		part(
			"Trigger",
			cylinder,
			Vector3.new(0.4, 1.5, 1.5),
			CFrame.new(0, -0.45, 0) * CFrame.Angles(0, 0, math.pi / 2),
			gold
		)
		for i = 1, 8 do
			local a = i * math.pi / 4
			part(
				"Gripper",
				block,
				Vector3.new(0.4, 0.9, 0.65),
				CFrame.new(math.cos(a) * 1.15, -0.12, math.sin(a) * 1.15) * CFrame.Angles(0, -a, 0),
				cyan
			)
		end
	else
		part("Bottle", ball, Vector3.new(2, 2.2, 2), CFrame.new(0, -0.15, 0), purple)
		part(
			"Neck",
			cylinder,
			Vector3.new(0.9, 0.95, 0.95),
			CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(204, 163, 255)
		)
		part(
			"Cork",
			cylinder,
			Vector3.new(0.4, 1.05, 1.05),
			CFrame.new(0, 1.57, 0) * CFrame.Angles(0, 0, math.pi / 2),
			gold
		)
		part("Label", ball, Vector3.new(0.9, 0.95, 0.15), CFrame.new(0, -0.15, -0.98), Color3.fromRGB(255, 247, 217))
		part("Star", ball, Vector3.new(0.28, 0.3, 0.2), CFrame.new(0, -0.15, -1.07), purple)
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = 32
	local normal = CFrame.lookAt(Vector3.new(3.3, 2.8, -6.7), Vector3.new(0, 0.2, 0))
	camera.CFrame, camera.Parent, view.CurrentCamera = normal, view, camera
	local tween
	local function hover(active)
		if tween then
			tween:Cancel()
		end
		tween = TweenService:Create(
			camera,
			TweenInfo.new(0.25),
			{ CFrame = active and CFrame.lookAt(Vector3.new(1.8, 2.4, -6), Vector3.new(0, 0.2, 0)) or normal }
		)
		tween:Play()
	end
	view.MouseEnter:Connect(function()
		hover(true)
	end)
	view.MouseLeave:Connect(function()
		hover(false)
	end)
	view.Destroying:Connect(function()
		if tween then
			tween:Cancel()
		end
	end)
	return view
end
return Art
