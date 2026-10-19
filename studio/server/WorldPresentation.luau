local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Factory = require(script.Parent.CreatureFactory)
local Visuals = require(game.ReplicatedStorage.HACShared.LassoVisuals)
local Stations = require(script.Parent.WorldStations)
local World = {}
World.__index = World
function World.new(world)
	local self = setmetatable(
		{ world = world, bases = world.Hub.Bases, dummies = {}, exercise = {}, upgradePrompts = {} },
		World
	)
	for _, base in ipairs(self.bases:GetChildren()) do
		local first = base:FindFirstChild("Lugar1")
		if first then
			for slot = 1, math.max(table.unpack(C.Upgrades.Base.Values)) do
				if not base:FindFirstChild("Lugar" .. slot) then
					local marker = first:Clone()
					marker.Name = "Lugar" .. slot
					local layout = C.BaseLayout
					local offset = Vector3.new(
						(slot - 1) % layout.Columns * layout.ColumnSpacing,
						0,
						math.floor((slot - 1) / layout.Columns) * layout.RowSpacing
					)
					marker.CFrame = first.CFrame + base.Plataforma.CFrame:VectorToWorldSpace(offset)
					marker.Parent = base
				end
			end
		end
		local station = base:FindFirstChild("Esteira")
		if station then
			station.Color = Color3.fromRGB(58, 143, 167)
			local stripe = base:FindFirstChild("FaixaEsteira")
			if stripe then
				stripe.Transparency = 1
			end
			local dummy = Instance.new("Model")
			dummy.Name, dummy.Parent = "Manequim", base
			local center = station.Position + Vector3.new(0, 2, -1.5)
			local body =
				Factory.Part(dummy, "Alvo", Vector3.new(1.4, 2.2, 1), CFrame.new(center), Color3.fromRGB(234, 183, 111))
			Factory.Part(
				dummy,
				"Cabeca",
				Vector3.one,
				CFrame.new(center + Vector3.new(0, 1.6, 0)),
				Color3.fromRGB(255, 220, 160),
				nil,
				Enum.PartType.Ball
			)
			Factory.Part(
				dummy,
				"Bracos",
				Vector3.new(3, 0.5, 0.6),
				CFrame.new(center + Vector3.new(0, 0.5, 0)),
				body.Color
			)
			dummy.PrimaryPart = body
			self.dummies[base] = dummy
			station.Treinar.ActionText, station.Treinar.ObjectText = "Treinar / sair", "Manequim de laço"
		end
	end
	local shop = Factory.Part(
		world.Hub,
		"LojaDeCaca",
		Vector3.new(5, 3, 3),
		CFrame.new(-20, 5.7, 9),
		Color3.fromRGB(56, 161, 185)
	)
	shop.CanCollide = true
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name, prompt.ActionText, prompt.ObjectText = "AbrirLoja", "Comprar", "Loja de caça"
	prompt.MaxActivationDistance, prompt.HoldDuration, prompt.Parent = 12, 0, shop
	prompt.RequiresLineOfSight, prompt.ClickablePrompt = false, true
	local sign = Instance.new("BillboardGui")
	sign.Size, sign.StudsOffset, sign.AlwaysOnTop, sign.Parent =
		UDim2.fromOffset(200, 40), Vector3.new(0, 3, 0), true, shop
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency, label.Text, label.TextSize = UDim2.fromScale(1, 1), 1, "LOJA DE CAÇA", 23
	label.Font, label.TextColor3, label.TextStrokeTransparency, label.Parent =
		Enum.Font.FredokaOne, Color3.new(1, 1, 1), 0, sign
	self.shop, self.prompt = shop, prompt
	self.seller = Stations.Ensure(world)
	return self
end
function World:RenderBase(base, profile)
	local folder = base.CriaturasInstaladas
	local byId = {}
	for _, model in ipairs(folder:GetChildren()) do
		byId[model:GetAttribute("CreatureId") or ""] = model
	end
	for id, item in pairs(profile.creatures) do
		if item.location == "base" then
			local marker = base:FindFirstChild("Lugar" .. item.slot)
			if marker then
				local model = byId[id]
				local position = marker.Position + Vector3.new(0, 1.68 * item.size * 0.72, 0)
				if not model then
					model = Factory.Build(folder, position, item, true)
				else
					model:PivotTo(CFrame.new(position))
				end
				byId[id] = nil
			end
		end
	end
	for _, model in pairs(byId) do
		model:Destroy()
	end
	for _, marker in ipairs(base:GetChildren()) do
		local slot = tonumber(marker.Name:match("^Lugar(%d+)$"))
		if slot and marker:IsA("BasePart") then
			marker.Transparency = slot <= C.Stat(profile, "Base") and 0.15 or 1
		end
	end
	local dummy = self.dummies[base]
	if dummy then
		dummy.Alvo.Color = Color3.fromRGB(234, 183, 111):Lerp(
			Color3.fromRGB(255, 219, 62),
			(profile.upgrades.Treino or 0) / math.max(1, #C.Upgrades.Treino.Values - 1)
		)
		base.Esteira.Treinar.ObjectText = "Manequim "
			.. ((profile.upgrades.Treino or 0) + 1)
			.. " • +"
			.. C.TrainingGain(profile)
			.. " força / "
			.. C.TrainingSeconds
			.. " s"
	end
end
function World:StopTraining(player, speed)
	local state = self.exercise[player]
	if not state then
		return
	end
	self.exercise[player] = nil
	Visuals.CleanupLine(state.line)
	state.loop:Destroy()
	if state.root.Parent then
		state.root.Anchored = state.anchored
	end
	if state.humanoid.Parent then
		state.humanoid.WalkSpeed = speed or state.speed
		state.humanoid.AutoRotate = state.autoRotate
	end
end
function World:StartTraining(player, base, effects)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local dummy = self.dummies[base]
	if not root or not humanoid or humanoid.Health <= 0 or not dummy then
		return false
	end
	local state = {
		root = root,
		humanoid = humanoid,
		anchored = root.Anchored,
		autoRotate = humanoid.AutoRotate,
		speed = humanoid.WalkSpeed,
		target = dummy.Alvo,
		started = os.clock(),
	}
	root.CFrame = CFrame.lookAt(base.Esteira.Position + Vector3.new(0, 3.2, 1.7), dummy.Alvo.Position)
	root.Anchored, humanoid.WalkSpeed, humanoid.AutoRotate = true, 0, false
	state.loop = Visuals.Loop(effects)
	state.line = Visuals.Line(character, state.loop.PrimaryPart)
	self.exercise[player] = state
	return true
end
function World:AnimateTraining()
	for _, state in pairs(self.exercise) do
		if state.root.Parent and state.target.Parent then
			local phase = (os.clock() - state.started) % C.TrainingSeconds / C.TrainingSeconds
			local from = state.root.Position + Vector3.new(1, 0.4, 0)
			local t = phase < 0.65 and phase / 0.65 or (1 - phase) / 0.35
			local pos = from:Lerp(state.target.Position, t)
			state.loop:PivotTo(CFrame.lookAt(pos, pos + state.root.CFrame.LookVector))
		end
	end
end
return World
