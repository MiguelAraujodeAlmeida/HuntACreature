-- Protótipo: estado de captura, recursos e treino pertencem ao servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local world = workspace:WaitForChild("HuntACreature")
local remote = ReplicatedStorage:WaitForChild("HuntACreatureRemote")
local basesFolder = world.Hub.Bases
local spawnPoints = world.IlhaCaca.PontosCriaturas:GetChildren()
table.sort(spawnPoints, function(a, b) return a.Name < b.Name end)
local wildFolder = Instance.new("Folder")
wildFolder.Name = "CriaturasSelvagens"
wildFolder.Parent = world.IlhaCaca

local MAX_CARRIED = 3
local MAX_INSTALLED = 3
local TICK_SECONDS = 5
local RESPAWN_SECONDS = 7
local bases = {}
local sessions = {}
local carried = {}
local installed = {}
local training = {}
local rng = Random.new()

local function notice(player, message)
	remote:FireClient(player, "Notice", message)
end

local function rootOf(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function closeEnough(player, position, limit)
	local root = rootOf(player)
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
	local blue = golden and Color3.fromRGB(255, 202, 70) or Color3.fromRGB(74, 207, 217)
	local belly = golden and Color3.fromRGB(255, 238, 162) or Color3.fromRGB(171, 251, 239)
	local root = part(model, "Root", Vector3.one, CFrame.new(position), blue)
	root.Transparency = 1
	model.PrimaryPart = root
	part(model, "Corpo", Vector3.new(3.3, 2.8, 2.6) * scale, CFrame.new(position), blue, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	part(model, "Barriga", Vector3.new(2.5, 1.65, 0.35) * scale, CFrame.new(position + Vector3.new(0, -0.35 * scale, -1.18 * scale)), belly, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	for _, side in ipairs({-1, 1}) do
		part(model, "Orelha", Vector3.new(0.75, 1.6, 0.7) * scale, CFrame.new(position + Vector3.new(side * 1.02 * scale, 1.44 * scale, 0)), blue, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		part(model, "Olho", Vector3.new(0.37, 0.48, 0.2) * scale, CFrame.new(position + Vector3.new(side * 0.63 * scale, 0.34 * scale, -1.22 * scale)), Color3.fromRGB(28, 47, 57), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		part(model, "BrilhoOlho", Vector3.new(0.13, 0.15, 0.08) * scale, CFrame.new(position + Vector3.new(side * 0.67 * scale - 0.07 * scale, 0.46 * scale, -1.34 * scale)), Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball)
		part(model, "Pe", Vector3.new(0.9, 0.55, 0.9) * scale, CFrame.new(position + Vector3.new(side * 0.85 * scale, -1.35 * scale, -0.45 * scale)), blue, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
	part(model, "Nariz", Vector3.new(0.32, 0.25, 0.2) * scale, CFrame.new(position + Vector3.new(0, -0.08 * scale, -1.35 * scale)), Color3.fromRGB(56, 67, 72), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	return model
end

local function addWildLabel(model)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Identificacao"
	gui.Adornee = model.PrimaryPart
	gui.Size = UDim2.fromOffset(210, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 65
	gui.Parent = model.PrimaryPart
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = model.Name
	text.TextColor3 = model:GetAttribute("Golden") and Color3.fromRGB(255, 222, 111) or Color3.fromRGB(220, 255, 252)
	text.TextStrokeTransparency = 0.25
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = gui
end

local spawnWild
local function endSession(player, success, message)
	local session = sessions[player]
	if not session then return end
	sessions[player] = nil
	local creature = session.creature
	if creature and creature.Parent then
		creature:SetAttribute("BusyUserId", nil)
	end
	if success and creature and creature.Parent then
		local golden = creature:GetAttribute("Golden") == true
		creature:Destroy()
		table.insert(carried[player], {golden = golden})
		player:SetAttribute("Carregando", #carried[player])
		local index = session.spawnIndex
		task.delay(RESPAWN_SECONDS, function()
			if world.Parent then spawnWild(index) end
		end)
	end
	remote:FireClient(player, "End", success, message)
end

local function beginCapture(player, creature, spawnIndex)
	if sessions[player] then return end
	if creature:GetAttribute("BusyUserId") then
		notice(player, "Outro caçador já lançou o laço neste Lumito.")
		return
	end
	if #carried[player] >= MAX_CARRIED then
		notice(player, "Você já carrega 3 criaturas. Volte à sua base.")
		return
	end
	if not closeEnough(player, creature.PrimaryPart.Position, 13) then return end
	local equipped = player.Character and player.Character:FindFirstChild("Laço de treino")
	if not equipped then
		notice(player, "Equipe o Laço de treino na barra inferior.")
		return
	end
	creature:SetAttribute("BusyUserId", player.UserId)
	local golden = creature:GetAttribute("Golden") == true
	sessions[player] = {
		creature = creature,
		spawnIndex = spawnIndex,
		golden = golden,
		started = os.clock(),
		zone = 0.5,
		progress = 0.08,
		holding = false,
		phase = rng:NextNumber(0, 6.28),
	}
	remote:FireClient(player, "Start", creature.Name)
end

spawnWild = function(index)
	local spawnPoint = spawnPoints[index]
	if not spawnPoint or not spawnPoint.Parent then return end
	local golden = rng:NextNumber() < 0.18
	local model = makeCreature(wildFolder, spawnPoint.Position + Vector3.new(0, 1.7, 0), golden, golden and 1.13 or 1)
	model:SetAttribute("SpawnIndex", index)
	addWildLabel(model)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Capturar"
	prompt.ActionText = "Lançar laço"
	prompt.ObjectText = model.Name
	prompt.MaxActivationDistance = 11
	prompt.HoldDuration = 0.2
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if carried[player] then beginCapture(player, model, index) end
	end)
end

local function findBase(player)
	local index = player:GetAttribute("BaseIndex")
	return index and basesFolder:FindFirstChild("Base" .. index)
end

local function updateBaseLabel(base, text)
	local label = base.Totem:FindFirstChild("Label")
	local t = label and label:FindFirstChild("Text")
	if t then t.Text = text end
end

local function deposit(player, base)
	if findBase(player) ~= base then
		notice(player, "Esta base pertence a outro jogador.")
		return
	end
	local bag = carried[player]
	local pets = installed[player]
	if not bag or not pets then return end
	if #bag == 0 then
		notice(player, "Capture um Lumito na Ilha de Caça primeiro.")
		return
	end
	if #pets >= MAX_INSTALLED then
		notice(player, "Sua base está cheia neste protótipo.")
		return
	end
	local installedNow = 0
	while #bag > 0 and #pets < MAX_INSTALLED do
		local item = table.remove(bag, 1)
		table.insert(pets, item)
		local slot = #pets
		local marker = base:FindFirstChild("Lugar" .. slot)
		local visual = makeCreature(base.CriaturasInstaladas, marker.Position + Vector3.new(0, 1.55, 0), item.golden, 0.72)
		visual.Name = "Criatura" .. slot
		installedNow += 1
	end
	player:SetAttribute("Carregando", #bag)
	player:SetAttribute("Instaladas", #pets)
	local income = 0
	for _, item in ipairs(pets) do income += item.golden and 3 or 1 end
	player:SetAttribute("Renda", income)
	notice(player, installedNow .. " criatura(s) instalada(s)! Ouro e XP a cada 5 s.")
end

local function setTraining(player, base)
	if findBase(player) ~= base then
		notice(player, "Use a esteira da sua base.")
		return
	end
	training[player] = not training[player]
	player:SetAttribute("Treinando", training[player])
	notice(player, training[player] and "Treino iniciado. Fique perto da esteira." or "Treino encerrado.")
end

local function assignBase(player)
	for index = 1, 4 do
		if not bases[index] then
			bases[index] = player
			player:SetAttribute("BaseIndex", index)
			local base = basesFolder:FindFirstChild("Base" .. index)
			updateBaseLabel(base, "BASE DE " .. string.upper(player.DisplayName))
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
	if sessions[player] then endSession(player, false, "Caça encerrada.") end
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
	if action == "Hold" and typeof(value) == "boolean" then
		local session = sessions[player]
		if session then session.holding = value end
	end
end)

local simulationTime = 0
local incomeTime = 0
local trainingTime = 0
RunService.Heartbeat:Connect(function(dt)
	simulationTime += dt
	incomeTime += dt
	trainingTime += dt
	if simulationTime >= 0.1 then
		local step = math.min(simulationTime, 0.2)
		simulationTime = 0
		for player, session in pairs(sessions) do
			local creature = session.creature
			if not creature.Parent or not closeEnough(player, creature.PrimaryPart.Position, 17) then
				endSession(player, false, "A criatura escapou: você se afastou.")
			elseif os.clock() - session.started > 18 then
				endSession(player, false, "A criatura escapou. Tente novamente!")
			else
				session.zone = math.clamp(session.zone + (session.holding and 0.62 or -0.48) * step, 0.07, 0.93)
				local elapsed = os.clock() - session.started
				local speed = session.golden and 2.45 or 1.65
				local target = math.clamp(0.5 + 0.31 * math.sin(elapsed * speed + session.phase) + 0.09 * math.sin(elapsed * 3.2 + session.phase * 2), 0.09, 0.91)
				local overlap = math.abs(target - session.zone) < 0.16 + math.min(player:GetAttribute("Forca") or 0, 12) * 0.004
				session.progress = math.clamp(session.progress + (overlap and (session.golden and 0.26 or 0.35) or -0.14) * step, 0, 1)
				remote:FireClient(player, "State", target, session.zone, session.progress)
				if session.progress >= 1 then
					endSession(player, true, "Captura concluída! Volte à sua base para instalar.")
				end
			end
		end
	end
	if incomeTime >= TICK_SECONDS then
		incomeTime = 0
		for player, pets in pairs(installed) do
			local gold = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Ouro")
			local xp = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("XP")
			if gold and xp then
				for _, item in ipairs(pets) do
					gold.Value += item.golden and 3 or 1
					xp.Value += item.golden and 2 or 1
				end
			end
		end
	end
	if trainingTime >= 2 then
		trainingTime = 0
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
