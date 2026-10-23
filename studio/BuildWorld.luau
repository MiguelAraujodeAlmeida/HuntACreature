-- Execute uma vez no modo Edit do Roblox Studio.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
game:GetService("StarterGui").ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor

local previous = Workspace:FindFirstChild("HuntACreature")
if previous then previous:Destroy() end
local world = Instance.new("Folder")
world.Name = "HuntACreature"
world.Parent = Workspace

local oldRemote = ReplicatedStorage:FindFirstChild("HuntACreatureRemote")
if oldRemote then oldRemote:Destroy() end
local remote = Instance.new("RemoteEvent")
remote.Name = "HuntACreatureRemote"
remote.Parent = ReplicatedStorage

local function part(parent, name, size, position, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

local function label(parent, text, size, offset, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Adornee = parent
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffsetWorldSpace = offset
	gui.AlwaysOnTop = true
	gui.MaxDistance = 110
	gui.Parent = parent
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	t.TextStrokeColor3 = Color3.fromRGB(20, 35, 40)
	t.TextStrokeTransparency = 0.35
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.Parent = gui
	return t
end

local ocean = Workspace:FindFirstChild("Baseplate")
if ocean and ocean:IsA("BasePart") then
	ocean.Name = "Oceano"
	ocean.Size = Vector3.new(310, 2, 190)
	ocean.Position = Vector3.new(48, -10, 0)
	ocean.Color = Color3.fromRGB(33, 141, 172)
	ocean.Material = Enum.Material.SmoothPlastic
	ocean.Transparency = 0.12
	ocean.CanCollide = false
end
Workspace.FallenPartsDestroyHeight = -40

local hub = Instance.new("Folder")
hub.Name = "Hub"
hub.Parent = world
local hunt = Instance.new("Folder")
hunt.Name = "IlhaCaca"
hunt.Parent = world
part(hub, "Terra", Vector3.new(90, 4, 78), Vector3.new(0, 1, 0), Color3.fromRGB(210, 145, 79), Enum.Material.SmoothPlastic)
local hubTop = part(hub, "Gramado", Vector3.new(90, 1, 78), Vector3.new(0, 3.5, 0), Color3.fromRGB(117, 222, 94), Enum.Material.SmoothPlastic)
hubTop.TopSurface = Enum.SurfaceType.Studs
part(hunt, "Terra", Vector3.new(90, 4, 78), Vector3.new(110, 1, 0), Color3.fromRGB(218, 153, 82), Enum.Material.SmoothPlastic)
local huntTop = part(hunt, "Gramado", Vector3.new(90, 1, 78), Vector3.new(110, 3.5, 0), Color3.fromRGB(126, 219, 90), Enum.Material.SmoothPlastic)
huntTop.TopSurface = Enum.SurfaceType.Studs
part(world, "Ponte", Vector3.new(22, 1, 13), Vector3.new(55, 3.5, 0), Color3.fromRGB(248, 188, 100), Enum.Material.SmoothPlastic)
for _, x in ipairs({46, 64}) do
	part(world, "PostePonte", Vector3.new(1, 4, 1), Vector3.new(x, 6, -6), Color3.fromRGB(210, 128, 75), Enum.Material.SmoothPlastic)
	part(world, "PostePonte", Vector3.new(1, 4, 1), Vector3.new(x, 6, 6), Color3.fromRGB(210, 128, 75), Enum.Material.SmoothPlastic)
end
part(hub, "Caminho", Vector3.new(79, 0.18, 9), Vector3.new(3, 4.09, 0), Color3.fromRGB(255, 235, 168), Enum.Material.SmoothPlastic)
part(hunt, "Caminho", Vector3.new(75, 0.18, 8), Vector3.new(104, 4.09, 0), Color3.fromRGB(255, 235, 168), Enum.Material.SmoothPlastic)

local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then
	spawn.Position = Vector3.new(-36, 4.6, 0)
	spawn.Size = Vector3.new(7, 1, 7)
	spawn.Color = Color3.fromRGB(245, 230, 164)
	spawn.Transparency = 0.35
	spawn.Neutral = true
end

local sign = part(hub, "PlacaHub", Vector3.new(10, 5, 0.8), Vector3.new(27, 7, -16), Color3.fromRGB(29, 39, 70), Enum.Material.SmoothPlastic)
label(sign, "HUB  •  BASES", Vector2.new(260, 54), Vector3.new(0, 4, 0), Color3.fromRGB(255, 244, 190))
local huntSign = part(hunt, "PlacaCaca", Vector3.new(10, 5, 0.8), Vector3.new(73, 7, -16), Color3.fromRGB(29, 39, 70), Enum.Material.SmoothPlastic)
label(huntSign, "ILHA DE CAÇA", Vector2.new(260, 54), Vector3.new(0, 4, 0), Color3.fromRGB(255, 244, 190))

local bases = Instance.new("Folder")
bases.Name = "Bases"
bases.Parent = hub
for i, x in ipairs({-31, -10, 11, 32}) do
	local base = Instance.new("Model")
	base.Name = "Base" .. i
	base:SetAttribute("Index", i)
	base.Parent = bases
	local z = i % 2 == 0 and 25 or -25
	local platform = part(base, "Plataforma", Vector3.new(18, 0.8, 17), Vector3.new(x, 4.4, z), Color3.fromRGB(45, 95, 115), Enum.Material.SmoothPlastic)
	local accent = part(base, "Tapete", Vector3.new(15, 0.16, 14), Vector3.new(x, 4.89, z), Color3.fromRGB(79, 210, 241), Enum.Material.SmoothPlastic)
	accent.CanCollide = false
	local outer = z < 0 and z - 18.5 or z + 18.5
	local training = part(base, "Esteira", Vector3.new(5, 0.5, 6), Vector3.new(x + 4.2, 5.05, outer), Color3.fromRGB(29, 39, 70), Enum.Material.SmoothPlastic)
	local belt = part(base, "FaixaEsteira", Vector3.new(3.8, 0.08, 4.8), Vector3.new(x + 4.2, 5.34, outer), Color3.fromRGB(35, 154, 156), Enum.Material.SmoothPlastic)
	belt.CanCollide = false
	local slots = Instance.new("Folder")
	slots.Name = "CriaturasInstaladas"
	slots.Parent = base
	for n = 1, 3 do
		local px = x - 4 + (n - 1) * 4
		local marker = part(base, "Lugar" .. n, Vector3.new(3.2, 0.12, 3.2), Vector3.new(px, 5.02, z + 3), Color3.fromRGB(228, 199, 117), Enum.Material.Neon)
		marker.CanCollide = false
	end
end

local spawns = Instance.new("Folder")
spawns.Name = "PontosCriaturas"
spawns.Parent = hunt
for i, pos in ipairs({Vector3.new(80, 4.2, 21), Vector3.new(103, 4.2, -21), Vector3.new(128, 4.2, 19), Vector3.new(145, 4.2, -18)}) do
	local p = part(spawns, "Ponto" .. i, Vector3.new(1, 1, 1), pos, Color3.fromRGB(255, 255, 255))
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
end

for _, pos in ipairs({Vector3.new(75, 4, -27), Vector3.new(91, 4, 28), Vector3.new(119, 4, -29), Vector3.new(146, 4, 26)}) do
	part(hunt, "Tronco", Vector3.new(2, 8, 2), pos + Vector3.new(0, 4, 0), Color3.fromRGB(210, 128, 75), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	part(hunt, "Copa", Vector3.new(10, 10, 10), pos + Vector3.new(0, 10, 0), Color3.fromRGB(47, 161, 91), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
end
for _, pos in ipairs({Vector3.new(82, 4, -12), Vector3.new(134, 4, 5), Vector3.new(150, 4, -5)}) do
	part(hunt, "Rocha", Vector3.new(5, 3, 4), pos + Vector3.new(0, 1, 0), Color3.fromRGB(146, 103, 224), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
end

local lighting = game:GetService("Lighting")
lighting.ClockTime = 14
lighting.Brightness = 2.5
lighting.Ambient = Color3.fromRGB(135, 160, 152)

local starterPack = game:GetService("StarterPack")
local oldTool = starterPack:FindFirstChild("Laço de treino")
if oldTool then oldTool:Destroy() end
local tool = Instance.new("Tool")
tool.Name = "Laço de treino"
tool.ToolTip = "Equipe para capturar Lumitos"
tool.CanBeDropped = false
tool.Parent = starterPack
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.35, 2.8, 0.35)
handle.Color = Color3.fromRGB(139, 86, 48)
handle.Material = Enum.Material.Wood
handle.CanCollide = false
handle.Massless = true
handle.Parent = tool
for n = 1, 12 do
	local angle = n * math.pi / 6
	local segment = Instance.new("Part")
	segment.Name = "Corda"
	segment.Size = Vector3.new(0.16, 0.75, 0.16)
	segment.Color = Color3.fromRGB(242, 213, 146)
	segment.Material = Enum.Material.Fabric
	segment.CanCollide = false
	segment.Massless = true
	segment.CFrame = CFrame.new(math.cos(angle) * 1.1, 2.1 + math.sin(angle) * 1.1, 0) * CFrame.Angles(0, 0, angle)
	segment.Parent = tool
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = segment
	weld.Parent = segment
end
print("Hunt A Creature: cenário de protótipo criado")
