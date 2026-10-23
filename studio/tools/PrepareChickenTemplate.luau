-- Run once through Studio MCP in Edit after importing Chicken_Base_v01.fbx.
-- Rebuilds the runtime copy; keep the source FBX/Blend under version control.
local source = assert(workspace:FindFirstChild("Chicken_Base_v01"), "Import Chicken_Base_v01.fbx first")
local storage = game:GetService("ReplicatedStorage")
assert(not storage:FindFirstChild("HACChickenTemplate"), "Existing template: review before replacing")
local template = Instance.new("Model")
template.Name = "HACChickenTemplate"
local root = Instance.new("Part")
root.Name, root.Size, root.CFrame = "Root", Vector3.new(.5, .5, .5), CFrame.new()
root.Transparency, root.Anchored = 1, true
root.CanCollide, root.CanTouch, root.CanQuery = false, false, false
root.Parent, template.PrimaryPart = template, root
local body = Instance.new("Part")
body.Name, body.Size, body.CFrame = "Corpo", Vector3.new(1.65, 2, 1.45), CFrame.new()
body.Transparency, body.Anchored = 1, true
body.CanCollide, body.CanTouch, body.CanQuery = false, false, false
body.Parent = template
local colors = {
	Main = Color3.fromRGB(247, 231, 204), Secondary = Color3.fromRGB(255, 248, 229),
	Accent = Color3.fromRGB(235, 52, 67), Extra_1 = Color3.fromRGB(255, 181, 28),
	Extra_2 = Color3.fromRGB(137, 79, 36), Ink = Color3.fromRGB(21, 27, 37),
	Glint = Color3.new(1, 1, 1),
}
local function role(name)
	if name == "Body" or name:match("^Wing_") then return "Main" end
	if name == "Head" or name == "Breast" or name:match("^Tail_") then return "Secondary" end
	if name:match("^Comb_") or name == "Wattle" then return "Accent" end
	if name:match("^Sole_") then return "Extra_2" end
	if name:match("^Eye_") then return "Ink" end
	if name:match("^Glint_") then return "Glint" end
	return "Extra_1"
end
local origin, count = source:GetPivot(), 0
for _, imported in ipairs(source:GetDescendants()) do
	if imported:IsA("MeshPart") then
		local part = imported:Clone()
		local offset = origin:ToObjectSpace(imported.CFrame)
		part.Size = imported.Size * .01
		part.CFrame = CFrame.new(offset.Position * .01 - Vector3.new(0, 1.35, 0)) * offset.Rotation
		part.Material = Enum.Material.SmoothPlastic
		local colorRole = role(part.Name)
		part.Color = colors[colorRole]
		part:SetAttribute("ColorRole", colorRole)
		local side = part.Name:match("^Foot_([LR])$") or part.Name:match("^Sole_([LR])$")
		if side then part:SetAttribute("FootSide", side) end
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, true
		part.Parent = template
		count += 1
	end
end
assert(count == 25, "Expected 25 chicken meshes, got " .. count)
template:SetAttribute("ImportedAsset", "Chicken_Base_v01.fbx")
template.Parent = storage
source:Destroy()
return template
