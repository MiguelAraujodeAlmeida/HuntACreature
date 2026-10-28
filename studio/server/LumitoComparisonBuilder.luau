-- Rebuildable, non-gameplay comparison display for [Testing] Hunt a Creature.
-- The source template is cloned; no species, spawn, profile or save is created.
local Builder = {}
local RigBuilder = require(script.Parent.LumitoRigBuilder)
local ROOT_NAME = "LumitoRigComparison"
local ARENA_CENTER = Vector3.new(181, 2, 0)
local LANE_Z = {Original = -10, Rig = 10}
local LANE_SURFACE_Y = 4
local FOOT_CLEARANCE = 0.06

local PALETTES = {
	Normal = {
		Main = Color3.fromRGB(12, 211, 255), Secondary = Color3.fromRGB(196, 248, 255),
		Accent = Color3.fromRGB(0, 112, 168), Ink = Color3.fromRGB(3, 12, 40),
		Glint = Color3.new(1, 1, 1),
	},
	Gold = {
		Main = Color3.fromRGB(255, 220, 86), Secondary = Color3.fromRGB(255, 252, 240),
		Accent = Color3.fromRGB(214, 142, 28), Ink = Color3.fromRGB(3, 12, 40),
		Glint = Color3.new(1, 1, 1),
	},
}

local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position = name, size, position
	p.Anchored, p.CanCollide = true, true
	p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function label(parent, text, size, offset, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "ComparisonLabel"
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffsetWorldSpace = offset
	gui.MaxDistance = 90
	gui.AlwaysOnTop = true
	gui.Parent = parent
	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.fromScale(1, 1)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.FredokaOne
	value.TextScaled = true
	value.TextColor3 = color
	value.TextStrokeColor3 = Color3.fromRGB(8, 18, 42)
	value.TextStrokeTransparency = 0
	value.Text = text
	value.Parent = gui
	return value
end

local function makeActor(folder, kind, scale, golden)
	local template = assert(game.ReplicatedStorage:FindFirstChild("HACLumitoTemplate"), "Lumito template missing")
	local model = template:Clone()
	model.Name = kind
	model:SetAttribute("CreatureScale", scale)
	model:SetAttribute("ComparisonOnly", true)
	model:SetAttribute("ComparisonVariant", kind)
	model.PrimaryPart = assert(model:FindFirstChild("Root"), "Lumito Root missing")
	model:ScaleTo(scale)
	model:PivotTo(CFrame.new(181, LANE_SURFACE_Y + (1.625 + FOOT_CLEARANCE) * scale, LANE_Z[kind]))
	local palette = PALETTES[golden and "Gold" or "Normal"]
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BasePart") then
			if item:IsA("UnionOperation") then item.UsePartColor = true end
			item.Color = palette[item:GetAttribute("ColorRole") or "Main"] or palette.Main
			item.Material = Enum.Material.SmoothPlastic
			item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
		end
	end
	if kind == "Rig" then RigBuilder.Build(model) end
	model.Parent = folder
	return model
end

function Builder.RebuildActors(arena, scale, golden)
	for _, name in ipairs({"Original", "Rig"}) do
		local old = arena:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local original = makeActor(arena, "Original", scale, golden)
	local proposed = makeActor(arena, "Rig", scale, golden)
	arena:SetAttribute("DisplayScale", scale)
	arena:SetAttribute("DisplayGold", golden)
	local board = arena:FindFirstChild("ModeBoard")
	local text = board and board:FindFirstChild("ComparisonLabel") and board.ComparisonLabel:FindFirstChild("Value")
	if text then text.Text = (golden and "GOLD" or "NORMAL") .. "   " .. tostring(scale) .. "x" end
	return original, proposed
end

function Builder.Build()
	local world = assert(workspace:FindFirstChild("HuntACreature"), "HuntACreature world missing")
	local old = world:FindFirstChild(ROOT_NAME)
	if old then old:Destroy() end
	local arena = Instance.new("Folder")
	arena.Name = ROOT_NAME
	arena:SetAttribute("ComparisonOnly", true)
	arena.Parent = world
	part(arena, "Platform", Vector3.new(52, 3.8, 40), ARENA_CENTER,
		Color3.fromRGB(31, 120, 113), Enum.Material.SmoothPlastic)
	for _, name in ipairs({"Original", "Rig"}) do
		local z = LANE_Z[name]
		part(arena, name .. "Lane", Vector3.new(40, 0.14, 14), Vector3.new(182, LANE_SURFACE_Y - 0.07, z),
			name == "Rig" and Color3.fromRGB(65, 213, 238) or Color3.fromRGB(92, 229, 162),
			Enum.Material.SmoothPlastic)
		local sign = part(arena, name .. "Sign", Vector3.new(1, 2.4, 7), Vector3.new(158.5, 5.3, z),
			Color3.fromRGB(10, 22, 43))
		label(sign, name == "Rig" and "RIG" or "ORIGINAL", Vector2.new(240, 54),
			Vector3.new(0, 2.5, 0), name == "Rig" and Color3.fromRGB(66, 226, 255) or Color3.fromRGB(153, 255, 150))
	end
	local board = part(arena, "ModeBoard", Vector3.new(1.2, 2.3, 5), Vector3.new(157.5, 5.2, 0),
		Color3.fromRGB(10, 22, 43))
	label(board, "NORMAL   1x", Vector2.new(260, 50), Vector3.new(0, 2.5, 0), Color3.new(1, 1, 1))
	Builder.RebuildActors(arena, 1, false)
	return arena
end

return Builder
