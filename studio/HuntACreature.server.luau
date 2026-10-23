-- Integração do ciclo: regras de dados, captura, IA e apresentação ficam em módulos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local C = require(ReplicatedStorage.HACShared.GameplayConfig)
local Rank = require(ReplicatedStorage.HACShared.HunterProgression)
local Modules = script.Parent.HACServer
local Data = require(Modules.ProfileData)
local ToolInventory = require(Modules.ToolInventory)
local Stations = require(Modules.WorldStations)
local Profiles = require(Modules.ProfileService).new()
local Factory = require(Modules.CreatureFactory)
local world = workspace:WaitForChild("HuntACreature")
local remote = ReplicatedStorage:WaitForChild("HuntACreatureRemote")
local presentation = require(Modules.WorldPresentation).new(world)
local function folder(name, parent)
	local result = Instance.new("Folder")
	result.Name, result.Parent = name, parent
	return result
end
local wild = folder("CriaturasSelvagens", world.IlhaCaca)
local effects = folder("EfeitosDeCaca", world)
local creatures = require(Modules.CreatureBehaviorService).new({
	wildFolder = wild,
	effectsFolder = effects,
	ground = world.IlhaCaca.Gramado,
})
local spawnPoints = world.IlhaCaca.PontosCriaturas:GetChildren()
table.sort(spawnPoints, function(a, b)
	return a.Name < b.Name
end)
local random, wildData, owners, training, requests, passiveElapsed = Random.new(), {}, {}, {}, {}, {}
local capture, huntingTools
local publish, spawnWild
local closing = false
local function notice(player, message)
	if player.Parent and message then
		remote:FireClient(player, "Notice", message)
	end
end
local function baseOf(player)
	local index = player:GetAttribute("BaseIndex")
	return index and presentation.bases:FindFirstChild("Base" .. index)
end
local function aliveRoot(player)
	local character = player.Character
	local h = character and character:FindFirstChildOfClass("Humanoid")
	return h and h.Health > 0 and character:FindFirstChild("HumanoidRootPart")
end
local function near(player, part, distance)
	local root = aliveRoot(player)
	return root and part and (root.Position - part.Position).Magnitude <= distance
end
local function setLabel(base, owner)
	local marker = base and base:FindFirstChild("OwnerMarker")
	local gui = marker and marker:FindFirstChild("OwnerBillboard")
	if not gui then return end
	gui.Enabled = owner ~= nil
	if owner then
		gui.OwnerName.Text = owner.DisplayName
		gui.Portrait.Image = "rbxthumb://type=AvatarHeadShot&id=" .. owner.UserId .. "&w=150&h=150"
	end
end
local function stopTraining(player)
	training[player] = nil
	local p = Profiles:Get(player)
	presentation:StopTraining(player, p and C.Stat(p, "Velocidade"))
	player:SetAttribute("Treinando", false)
	player:SetAttribute("TrainingStartedAt", nil)
end
local function busy(player)
	return training[player] or capture.sessions[player] or capture.projectiles[player] or capture.charges[player]
end
publish = function(player)
	local p = Profiles:Get(player)
	if not p or not player.Parent then
		return
	end
	local income = 0
	for _, item in pairs(p.creatures) do
		if item.location == "base" then
			income += C.Value(item, "Income")
		end
	end
	player:SetAttribute("Carregando", Data.Count(p, "bag"))
	player:SetAttribute("Instaladas", Data.Count(p, "base"))
	player:SetAttribute("BagCapacity", C.Stat(p, "Bolsa"))
	player:SetAttribute("BaseCapacity", C.Stat(p, "Base"))
	player:SetAttribute("Renda", income * Rank.GoldMultiplier(p.xp))
	player:SetAttribute("Forca", p.strength)
	local level = Rank.Level(p.xp)
	local previousRank = player:GetAttribute("HunterRank")
	player:SetAttribute("HunterRank", level)
	if previousRank and level > previousRank then
		remote:FireClient(player, "HunterRankUp", { from = previousRank, to = level })
	end
	player:SetAttribute("ProfileReady", true)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Gold.Value, stats.XP.Value, stats.Rank.Value = p.gold, p.xp, level
	end
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h and not training[player] then
		h.WalkSpeed = C.Stat(p, "Velocidade")
	end
	local base = baseOf(player)
	if base then
		presentation:RenderBase(base, p)
	end
	ToolInventory.Sync(player, p)
	remote:FireClient(
		player,
		"Profile",
		{ profile = Data.Copy(p), rotation = C.Rotation(os.time()), temporary = Profiles.memory }
	)
end
spawnWild = function(index)
	local point = spawnPoints[index]
	if not point or not world.Parent or closing then
		return
	end
	local reservedSpecies = C.SpawnReservations[point.Name] or "Lumito"
	local item = Factory.Roll(random, reservedSpecies)
	local rootHeight = C.Species[item.species].RootHeight or 1.68
	local model = Factory.Build(wild, point.Position + Vector3.new(0, rootHeight * item.size, 0), item, false)
	wildData[model] = item
	model:SetAttribute("SpawnIndex", index)
	model.Destroying:Once(function()
		wildData[model] = nil
	end)
	creatures:Add(model, item.species)
end
capture = require(Modules.CaptureService).new({
	remote = remote,
	wildFolder = wild,
	effectsFolder = effects,
	notice = notice,
	canCarry = function(player)
		local p = Profiles:Get(player)
		return p ~= nil and Data.Count(p, "bag") < C.Stat(p, "Bolsa")
	end,
	onCaptured = function(player, model)
		local item = wildData[model]
		if not item then
			return false
		end
		local firstSpecies, firstVariant
		local ok, message = Profiles:Change(player, function(p)
			firstSpecies = not p.discoveries[item.species]
			firstVariant = not (p.variantDiscoveries and p.variantDiscoveries[C.VariantKey(item)])
			return Data.Capture(p, item)
		end)
		if not ok then
			notice(player, message)
			return false
		end
		local index = model:GetAttribute("SpawnIndex")
		model:Destroy()
		publish(player)
		task.delay(C.RespawnSeconds, function()
			spawnWild(index)
		end)
		return true, {
			name = C.Name(item),
			species = item.species,
			mutations = item.mutations,
			rarity = C.RarityNames[item.rarity] or item.rarity,
			golden = table.find(item.mutations, "Dourado") ~= nil,
			firstSpecies = firstSpecies,
			firstVariant = firstVariant,
			goldPerSecond = C.Value(item, "Income"),
			xpEarned = Rank.CaptureReward(item, firstSpecies, firstVariant),
			passiveXP = Rank.ResearchValue(item),
			passiveSeconds = Rank.PassiveSeconds,
		}
	end,
})
huntingTools = require(Modules.HuntingTools).new({
	profiles = Profiles,
	capture = capture,
	creatures = creatures,
	ground = world.IlhaCaca.Gramado,
	effects = effects,
	wild = wild,
})
creatures.attractor = function(pos, vision)
	return huntingTools:Attractor(pos, vision)
end
local function toggleTraining(player, base)
	if training[player] then
		stopTraining(player)
		return
	end
	local board = Stations.FindBoard(base, "Treino")
	if baseOf(player) ~= base or not near(player, board, C.Boards.Distance) or not Profiles:Get(player) then
		return
	end
	if busy(player) then
		notice(player, "Finish your hunt before training.")
		return
	end
	if presentation:StartTraining(player, base, effects) then
		training[player] = os.clock()
		player:SetAttribute("TrainingStartedAt", workspace:GetServerTimeNow())
		player:SetAttribute("Treinando", true)
	end
end
local function openCounter(player, anchor, distance, page)
	if not near(player, anchor, distance) then
		return
	end
	if busy(player) then
		notice(player, "Finish hunting or leave training first.")
		return
	end
	publish(player)
	remote:FireClient(player, "OpenCollection", page)
end
local zonePresence, zoneClock = {}, 0
local function inside(root, zone)
	if not root or not zone then return false end
	local delta = root.Position - zone.Position
	return math.abs(delta.Y) < 7 and Vector2.new(delta.X, delta.Z).Magnitude <= (zone:GetAttribute("Radius") or 3)
end
RunService.Heartbeat:Connect(function(dt)
	zoneClock += dt
	if zoneClock < 0.15 then return end
	zoneClock = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local root = aliveRoot(player)
		local base = baseOf(player)
		local trainZone = base and base:FindFirstChild("TrainZone")
		local shopZone = world.Hub:FindFirstChild("ShopZone")
		local sellZone = world.Hub:FindFirstChild("SellZone")
		local zones = {
			training = trainZone and trainZone:FindFirstChild("Center"),
			shop = shopZone and shopZone:FindFirstChild("Center"),
			sell = sellZone and sellZone:FindFirstChild("Center"),
		}
		local previous = zonePresence[player] or {}
		for kind, zone in pairs(zones) do
			local active = inside(root, zone)
			if active and not previous[kind] then
				if kind == "training" then toggleTraining(player, base)
				elseif kind == "shop" then openCounter(player, presentation.shop, C.Shop.Distance, "Loja")
				else openCounter(player, presentation.seller, C.Sell.Distance, "Venda") end
			elseif not active and previous[kind] then
				if kind == "shop" then remote:FireClient(player, "CloseZoneCollection", "Loja")
				elseif kind == "sell" then remote:FireClient(player, "CloseZoneCollection", "Venda") end
			end
			previous[kind] = active
		end
		zonePresence[player] = previous
	end
end)
for index = 1, #spawnPoints do
	spawnWild(index)
end

local function assignBase(player)
	for i = 1, #presentation.bases:GetChildren() do
		if not owners[i] then
			owners[i] = player
			player:SetAttribute("BaseIndex", i)
			setLabel(baseOf(player), player)
			return true
		end
	end
	return false
end
local function attachCharacter(player, character)
	stopTraining(player)
	capture:PlayerRemoving(player)
	huntingTools:RemovePlayer(player)
	local h = character:WaitForChild("Humanoid", 10)
	if not h then
		return
	end
	h.Died:Once(function()
		stopTraining(player)
		capture:_finish(player, false, "Capture interrupted.")
		capture:PlayerRemoving(player)
		huntingTools:RemovePlayer(player)
	end)
	local p = Profiles:Get(player)
	if p then
		h.WalkSpeed = C.Stat(p, "Velocidade")
		ToolInventory.Sync(player, p)
	end
	-- O laço existente continua em StarterPack; nenhuma cópia de Tool é gerada pelo cliente.
end
local function playerAdded(player)
	player:SetAttribute("ProfileReady", false)
	player:SetAttribute("Treinando", false)
	local stats = Instance.new("Folder")
	stats.Name, stats.Parent = "leaderstats", player
	for _, name in ipairs({ "Gold", "XP", "Rank" }) do
		local v = Instance.new("IntValue")
		v.Name, v.Parent = name, stats
	end
	player.CharacterAdded:Connect(function(character)
		attachCharacter(player, character)
	end)
	if player.Character then
		task.spawn(attachCharacter, player, player.Character)
	end
	local p = Profiles:Load(player)
	if not p then
		player:Kick("Could not load your progress. Please try again. In Studio, check API access.")
		return
	end
	if not player.Parent or closing then
		Profiles:Save(player, true)
		return
	end
	if not assignBase(player) then
		Profiles:Save(player, true)
		player:Kick("All bases are occupied. Try another server.")
		return
	end
	publish(player)
	if Profiles.memory then
		notice(player, "Temporary test: progress will not be saved.")
	end
end
local function playerRemoving(player)
	stopTraining(player)
	capture:PlayerRemoving(player)
	huntingTools:RemovePlayer(player)
	requests[player] = nil
	zonePresence[player] = nil
	passiveElapsed[player] = nil
	local base = baseOf(player)
	if base then
		base.CriaturasInstaladas:ClearAllChildren()
		setLabel(base, nil)
		owners[player:GetAttribute("BaseIndex")] = nil
	end
	Profiles:Save(player, true)
end
Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(playerAdded, p)
end

remote.OnServerEvent:Connect(function(player, action, args)
	if type(action) ~= "string" then
		return
	end
	local now = os.clock()
	local request = requests[player] or { time = now, tokens = 40, lastAction = 0 }
	request.tokens = math.min(40, request.tokens + (now - request.time) * 20)
	request.time = now
	requests[player] = request
	if request.tokens < 1 then
		return
	end
	request.tokens -= 1
	if action == "ToggleTraining" then
		local base = baseOf(player)
		if base then
			toggleTraining(player, base)
		end
		return
	end
	if action == "StopTraining" then
		stopTraining(player)
		return
	end
	if action == "CancelCapture" then
		capture:_finish(player, false, "Lasso released.")
		return
	end
	if action == "RequestProfile" then
		if now - request.lastAction > 0.5 then
			request.lastAction = now
			publish(player)
		end
		return
	end
	if action == "ChargeStart" or action == "ChargeCancel" or action == "Throw" or action == "Hold" then
		if Profiles:Get(player) then
			capture:HandleRemote(player, action, args)
		end
		return
	end
	if action ~= "CollectionAction" or type(args) ~= "table" then
		return
	end
	if now - request.lastAction < 0.15 then
		return
	end
	request.lastAction = now
	local p = Profiles:Get(player)
	if not p then
		return
	end
	if args.revision ~= p.revision then
		notice(player, "Collection updated. Try again.")
		publish(player)
		return
	end
	if type(args.action) ~= "string" or type(args.id) ~= "string" or #args.id > 100 then
		return
	end
	local ok, message
	if args.action == "Use" then
		ok, message = huntingTools:Use(player, args.id, args.position)
	elseif args.action == "SetSetting" then
		ok, message = Profiles:Change(player, function(nextProfile)
			return Data.Action(nextProfile, args.action, args, C.Rotation(os.time()))
		end)
	elseif not busy(player) then
		if not aliveRoot(player) then
			return
		end
		if args.action == "Buy" and not near(player, presentation.shop, C.Shop.Distance) then
			notice(player, "Move closer to the hunting shop.")
			return
		end
		if args.action == "Upgrade" and args.id ~= "Bolsa" then
			local board = Stations.FindBoard(baseOf(player), args.id)
			if not board or not near(player, board, C.Boards.Distance) then
				notice(player, "Move closer to your upgrade board.")
				return
			end
		end
		if args.action == "Sell" and not near(player, presentation.seller, C.Sell.Distance) then
			notice(player, "Visit the Creature Market to sell.")
			return
		end
		ok, message = Profiles:Change(player, function(nextProfile)
			return Data.Action(nextProfile, args.action, args, C.Rotation(os.time()))
		end)
	else
		message = "Finish hunting or leave training first."
	end
	notice(player, message)
	if ok then
		if args.action == "Equip" or args.action == "Unequip" then
			passiveElapsed[player] = 0
		end
		remote:FireClient(player, "ActionFeedback", args.action)
	end
	publish(player)
end)

local incomeClock = 0
local rotationId = C.Rotation(os.time()).id
RunService.Heartbeat:Connect(function(dt)
	incomeClock += dt
	for player, started in pairs(training) do
		if not aliveRoot(player) or not Profiles:Get(player) then
			stopTraining(player)
		elseif os.clock() - started >= C.TrainingSeconds then
			training[player] = os.clock()
			local credited = 0
			Profiles:Change(player, function(p)
				local amount = C.TrainingGain(p) * Rank.TrainingMultiplier(p.xp) + p.strengthCarry
				local whole = math.floor(amount)
				credited = whole
				p.strength += whole
				p.strengthCarry = amount - whole
				return true
			end, true)
			player:SetAttribute("TrainingGain", credited)
			player:SetAttribute("TrainingPulse", workspace:GetServerTimeNow())
			publish(player)
		end
	end
	if incomeClock < C.IncomeSeconds then
		return
	end
	local elapsed = incomeClock
	incomeClock = 0
	local nextRotation = C.Rotation(os.time()).id
	local rotated = nextRotation ~= rotationId
	rotationId = nextRotation
	for _, player in ipairs(Players:GetPlayers()) do
		local p = Profiles:Get(player)
		if p then
			local income, active, research = 0, 0, 0
			for _, item in pairs(p.creatures) do
				if item.location == "base" then
					income += C.Value(item, "Income")
					active += 1
					research += Rank.ResearchValue(item)
				end
			end
			passiveElapsed[player] = active > 0 and (passiveElapsed[player] or 0) + elapsed or 0
			local passiveDue = passiveElapsed[player] >= Rank.PassiveSeconds
			if passiveDue then
				passiveElapsed[player] %= Rank.PassiveSeconds
			end
			if income > 0 or passiveDue and active > 0 then
				Profiles:Change(player, function(profile)
					Rank.CreditGold(profile, income)
					if passiveDue then
						profile.xp += Rank.PassiveReward(research, profile.xp)
					end
					return true
				end, true)
			end
			if income > 0 or passiveDue and active > 0 or rotated then
				publish(player)
			end
		elseif Profiles.sessions[player] then
			player:SetAttribute("ProfileReady", false)
			stopTraining(player)
			capture:_finish(player, false, "Capture stopped to protect your progress.")
			player:Kick("Saving is unavailable. Your progress is protected; please rejoin.")
		end
	end
end)
task.spawn(function()
	while not closing do
		task.wait(45)
		if closing then
			break
		end
		for player in pairs(Profiles.sessions) do
			task.spawn(function()
				Profiles:Save(player, not player.Parent)
			end)
		end
	end
end)
game:BindToClose(function()
	closing = true
	local pending = 0
	for player in pairs(Profiles.sessions) do
		pending += 1
		task.spawn(function()
			stopTraining(player)
			Profiles:Save(player, true)
			pending -= 1
		end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)
