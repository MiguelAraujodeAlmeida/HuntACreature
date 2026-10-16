-- Mundo, bases e economia. A captura vive em HACServer/CaptureService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Style = require(ReplicatedStorage.HACShared.VisualStyle)
local CaptureService = require(script.Parent.HACServer.CaptureService)
local Colors = Style.Colors
local world = workspace:WaitForChild("HuntACreature")
local remote = ReplicatedStorage:WaitForChild("HuntACreatureRemote")
local basesFolder = world.Hub.Bases
local spawnPoints = world.IlhaCaca.PontosCriaturas:GetChildren()
table.sort(spawnPoints, function(a, b) return a.Name < b.Name end)

local wildFolder = Instance.new("Folder")
wildFolder.Name = "CriaturasSelvagens"
wildFolder.Parent = world.IlhaCaca
local effectsFolder = Instance.new("Folder")
effectsFolder.Name = "EfeitosDeCaca"
effectsFolder.Parent = world

local MAX_CARRIED = 3
local MAX_INSTALLED = 3
local INCOME_SECONDS = 5
local RESPAWN_SECONDS = 7
local bases = {}
local carried = {}
local installed = {}
local training = {}
local random = Random.new()

local function notice(player, message)
	remote:FireClient(player, "Notice", message)
end

local function closeEnough(player, position, limit)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - position).Magnitude <= limit
end

local function part(parent, name, size, cframe, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = false
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

local function makeCreature(parent, position, golden, scale)
	local model = Instance.new("Model")
	model.Name = golden and "Lumito Dourado" or "Lumito"
	model:SetAttribute("Golden", golden)
	model.Parent = parent
	local mainColor = golden and Colors.Gold or Colors.Sky
	local bellyColor = golden and Colors.White or Color3.fromRGB(191, 255, 242)
	local root = part(model, "Root", Vector3.one, CFrame.new(position), mainColor)
	root.Transparency = 1
	model.PrimaryPart = root
	part(model, "Corpo", Vector3.new(3.3, 2.8, 2.6) * scale, CFrame.new(position), mainColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	part(model, "Barriga", Vector3.new(2.5, 1.65, 0.35) * scale, CFrame.new(position + Vector3.new(0, -0.35 * scale, -1.18 * scale)), bellyColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	for _, side in ipairs({-1, 1}) do
		part(model, "Orelha", Vector3.new(0.75, 1.6, 0.7) * scale, CFrame.new(position + Vector3.new(side * 1.02 * scale, 1.44 * scale, 0)), mainColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		part(model, "Olho", Vector3.new(0.37, 0.48, 0.2) * scale, CFrame.new(position + Vector3.new(side * 0.63 * scale, 0.34 * scale, -1.22 * scale)), Colors.Ink, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		part(model, "BrilhoOlho", Vector3.new(0.13, 0.15, 0.08) * scale, CFrame.new(position + Vector3.new(side * 0.58 * scale, 0.46 * scale, -1.34 * scale)), Colors.White, Enum.Material.Neon, Enum.PartType.Ball)
		part(model, "Pe", Vector3.new(0.9, 0.55, 0.9) * scale, CFrame.new(position + Vector3.new(side * 0.85 * scale, -1.35 * scale, -0.45 * scale)), mainColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		part(model, "Bochecha", Vector3.new(0.34, 0.18, 0.08) * scale, CFrame.new(position + Vector3.new(side * 0.95 * scale, -0.22 * scale, -1.12 * scale)), Colors.Coral, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
	part(model, "Nariz", Vector3.new(0.32, 0.25, 0.2) * scale, CFrame.new(position + Vector3.new(0, -0.08 * scale, -1.35 * scale)), Colors.Ink, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
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

local spawnWild
spawnWild = function(index)
	local point = spawnPoints[index]
	if not point or not point.Parent then return end
	local golden = random:NextNumber() < 0.18
	local model = makeCreature(wildFolder, point.Position + Vector3.new(0, 1.7, 0), golden, golden and 1.13 or 1)
	model:SetAttribute("SpawnIndex", index)
	addWildLabel(model)
	if golden then
		local glow = Instance.new("Highlight")
		glow.Name = "BrilhoRaro"
		glow.FillColor = Colors.Gold
		glow.FillTransparency = 0.7
		glow.OutlineColor = Colors.White
		glow.OutlineTransparency = 0.2
		glow.Parent = model
	end
end

local capture = CaptureService.new({
	remote = remote,
	wildFolder = wildFolder,
	effectsFolder = effectsFolder,
	notice = notice,
	canCarry = function(player)
		return carried[player] ~= nil and #carried[player] < MAX_CARRIED
	end,
	onCaptured = function(player, creature)
		local bag = carried[player]
		if not bag or #bag >= MAX_CARRIED then return end
		local golden = creature:GetAttribute("Golden") == true
		local index = creature:GetAttribute("SpawnIndex")
		creature:Destroy()
		table.insert(bag, {golden = golden})
		player:SetAttribute("Carregando", #bag)
		remote:FireClient(player, "Reward", golden, golden and "LUMITO DOURADO!" or "LUMITO CAPTURADO!")
		task.delay(RESPAWN_SECONDS, function()
			if world.Parent then spawnWild(index) end
		end)
	end,
})

local function findBase(player)
	local index = player:GetAttribute("BaseIndex")
	return index and basesFolder:FindFirstChild("Base" .. index)
end

local function updateBaseLabel(base, message)
	local label = base.Totem:FindFirstChild("Label")
	local text = label and label:FindFirstChild("Text")
	if text then text.Text = message end
end

local function deposit(player, base)
	if findBase(player) ~= base then notice(player, "Esta base pertence a outro jogador."); return end
	local bag = carried[player]
	local pets = installed[player]
	if not bag or not pets then return end
	if #bag == 0 then notice(player, "Capture um Lumito na Ilha de Caça primeiro."); return end
	if #pets >= MAX_INSTALLED then notice(player, "Sua base está cheia neste protótipo."); return end
	local count = 0
	while #bag > 0 and #pets < MAX_INSTALLED do
		local item = table.remove(bag, 1)
		table.insert(pets, item)
		local marker = base:FindFirstChild("Lugar" .. #pets)
		local visual = makeCreature(base.CriaturasInstaladas, marker.Position + Vector3.new(0, 1.55, 0), item.golden, 0.72)
		visual.Name = "Criatura" .. #pets
		count += 1
	end
	player:SetAttribute("Carregando", #bag)
	player:SetAttribute("Instaladas", #pets)
	local income = 0
	for _, item in ipairs(pets) do income += item.golden and 3 or 1 end
	player:SetAttribute("Renda", income)
	notice(player, count .. " criatura(s) instalada(s)! Sua base agora produz ouro e XP.")
end

local function setTraining(player, base)
	if findBase(player) ~= base then notice(player, "Use a esteira da sua base."); return end
	training[player] = not training[player]
	player:SetAttribute("Treinando", training[player])
	notice(player, training[player] and "Treino iniciado. Fique perto da esteira." or "Treino encerrado.")
end

local function assignBase(player)
	for index = 1, 4 do
		if not bases[index] then
			bases[index] = player
			player:SetAttribute("BaseIndex", index)
			updateBaseLabel(basesFolder:FindFirstChild("Base" .. index), "BASE DE " .. string.upper(player.DisplayName))
			return
		end
	end
	notice(player, "As quatro bases do protótipo estão ocupadas.")
end

for _, base in ipairs(basesFolder:GetChildren()) do
	base.Totem.Depositar.Triggered:Connect(function(player) deposit(player, base) end)
	base.Esteira.Treinar.Triggered:Connect(function(player) setTraining(player, base) end)
end
for index = 1, #spawnPoints do spawnWild(index) end

Players.PlayerAdded:Connect(function(player)
	carried[player] = {}
	installed[player] = {}
	training[player] = false
	player:SetAttribute("Carregando", 0)
	player:SetAttribute("Instaladas", 0)
	player:SetAttribute("Renda", 0)
	player:SetAttribute("Forca", 0)
	player:SetAttribute("Treinando", false)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	local gold = Instance.new("IntValue")
	gold.Name = "Ouro"
	gold.Parent = stats
	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Parent = stats
	assignBase(player)
end)

Players.PlayerRemoving:Connect(function(player)
	capture:PlayerRemoving(player)
	local base = findBase(player)
	if base then
		base.CriaturasInstaladas:ClearAllChildren()
		updateBaseLabel(base, "BASE LIVRE")
		bases[player:GetAttribute("BaseIndex")] = nil
	end
	carried[player] = nil
	installed[player] = nil
	training[player] = nil
end)

remote.OnServerEvent:Connect(function(player, action, value)
	capture:HandleRemote(player, action, value)
end)

local incomeClock = 0
local trainingClock = 0
RunService.Heartbeat:Connect(function(dt)
	incomeClock += dt
	trainingClock += dt
	if incomeClock >= INCOME_SECONDS then
		incomeClock = 0
		for player, pets in pairs(installed) do
			local stats = player:FindFirstChild("leaderstats")
			if stats then
				for _, item in ipairs(pets) do
					stats.Ouro.Value += item.golden and 3 or 1
					stats.XP.Value += item.golden and 2 or 1
				end
			end
		end
	end
	if trainingClock >= 2 then
		trainingClock = 0
		for player, active in pairs(training) do
			if active then
				local base = findBase(player)
				if base and closeEnough(player, base.Esteira.Position, 9) then
					player:SetAttribute("Forca", (player:GetAttribute("Forca") or 0) + 1)
				else
					training[player] = false
					player:SetAttribute("Treinando", false)
				end
			end
		end
	end
end)
