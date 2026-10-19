local TweenService = game:GetService("TweenService")
local Storage = game:GetService("ReplicatedStorage")
local C = require(Storage.HACShared.GameplayConfig)
local Portrait = {}
function Portrait.new(parent, item, discovered, size, position)
	local view = Instance.new("ViewportFrame")
	view.Name, view.Size, view.Position = "CreaturePortrait", size, position
	view.BackgroundTransparency = 1
	view.Ambient = Color3.fromRGB(205, 222, 255)
	view.LightColor, view.LightDirection = Color3.fromRGB(255, 247, 211), Vector3.new(-1, -1, -2)
	view.ZIndex = parent.ZIndex + 1
	view.Parent = parent
	local camera = Instance.new("Camera")
	camera.FieldOfView = 32
	camera.Parent, view.CurrentCamera = view, camera
	local world = Instance.new("WorldModel")
	world.Parent = view
	local waiting, tween
	local function populate()
		local folder = Storage:FindFirstChild("HACCreaturePreviews")
		local template = folder and folder:FindFirstChild(C.VariantKey(item))
		if not template or not view.Parent then
			return false
		end
		local model = template:Clone()
		model.Parent = world
		model:PivotTo(CFrame.new())
		if not discovered then
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Color = Color3.fromRGB(12, 18, 40)
					part.Material = Enum.Material.SmoothPlastic
				end
			end
		end
		local cf, bounds = model:GetBoundingBox()
		local distance = math.max(bounds.X, bounds.Y, bounds.Z) * 2.5
		local target = cf.Position
		local normal = CFrame.lookAt(target + Vector3.new(distance * 0.22, distance * 0.12, -distance), target)
		camera.CFrame = normal
		local function pose(hover)
			if tween then
				tween:Cancel()
			end
			tween = TweenService:Create(camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				CFrame = hover and CFrame.lookAt(
					target + Vector3.new(-distance * 0.15, distance * 0.16, -distance * 0.88),
					target
				) or normal,
			})
			tween:Play()
		end
		view.MouseEnter:Connect(function()
			pose(true)
		end)
		view.MouseLeave:Connect(function()
			pose(false)
		end)
		view:GetAttributeChangedSignal("Hovered"):Connect(function()
			pose(view:GetAttribute("Hovered") == true)
		end)
		return true
	end
	if not populate() then
		waiting = Storage.DescendantAdded:Connect(function(object)
			if object.Name == C.VariantKey(item) or object.Name == "HACCreaturePreviews" then
				task.defer(function()
					if waiting and populate() then
						waiting:Disconnect()
						waiting = nil
					end
				end)
			end
		end)
	end
	view.Destroying:Connect(function()
		if waiting then
			waiting:Disconnect()
		end
		if tween then
			tween:Cancel()
		end
	end)
	return view
end
return Portrait
