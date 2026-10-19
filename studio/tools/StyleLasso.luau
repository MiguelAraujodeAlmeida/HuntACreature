-- Execute em Edit. Preserva uma cópia do Tool anterior no ServerStorage.
local tool = game.StarterPack:FindFirstChild("Laço de treino")
assert(tool and tool:IsA("Tool"), "Laço de treino não encontrado")
local storage = game:GetService("ServerStorage")
if not storage:FindFirstChild("HAC_LassoBeforePolish") then
	local backup = tool:Clone()
	backup.Name = "HAC_LassoBeforePolish"
	backup.Parent = storage
end
for _, child in ipairs(tool:GetChildren()) do
	if child:IsA("BasePart") then
		child:Destroy()
	end
end
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.2, 0.2, 0.2)
handle.Transparency = 1
handle.CanCollide = false
handle.CanTouch = false
handle.CanQuery = false
handle.Massless = true
handle.Parent = tool
for layer = 1, 3 do
	for i = 1, 16 do
		local angle = i * math.pi / 8
		local piece = Instance.new("Part")
		piece.Name = "Corda"
		piece.Size = Vector3.new(0.13, 0.23, 0.13)
		piece.CFrame = CFrame.new(math.cos(angle) * 0.48, (layer - 2) * 0.14, math.sin(angle) * 0.48)
			* CFrame.Angles(math.pi / 2, 0, angle)
		piece.Color = Color3.fromRGB(255, 207, 74)
		piece.Material = Enum.Material.SmoothPlastic
		piece.CanCollide = false
		piece.CanTouch = false
		piece.CanQuery = false
		piece.Massless = true
		piece.Parent = tool
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = piece
		weld.Parent = piece
	end
end
tool.TextureId = require(game.ReplicatedStorage.HACShared.VisualStyle).Icons.Lasso
return "Laço de mão: corda enrolada; cópia anterior preservada."
