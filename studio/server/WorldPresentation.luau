local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Factory = require(script.Parent.CreatureFactory)
local Visuals = require(game.ReplicatedStorage.HACShared.LassoVisuals)
local Stations = require(script.Parent.WorldStations)
local TrainingDummies = require(script.Parent.TrainingDummies)
local World = {}
World.__index = World
function World.new(world)
	local self = setmetatable(
		{ world = world, bases = world.Hub.Bases, dummies = {}, exercise = {}, upgradePrompts = {} },
		World
	)
	self.roaming = require(script.Parent.BaseRoamingService).new(world)
	require(script.Parent.CatalogPresentation).Build()
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
		for _, marker in ipairs(base:GetChildren()) do
			if marker:IsA("BasePart") and marker.Name:match("^Lugar%d+$") then
				marker.Transparency, marker.CanCollide, marker.CanTouch, marker.CanQuery = 1, false, false, false
			end
		end
		local station = base:FindFirstChild("Esteira")
		if station then
			station.Color = Color3.fromRGB(58, 143, 167)
			local stripe = base:FindFirstChild("FaixaEsteira")
			if stripe then
				stripe.Transparency = 1
			end
			self.dummies[base] = TrainingDummies.Build(base, 1, 1)
			station.Treinar.ActionText, station.Treinar.ObjectText = "Train / leave", "Training dummy"
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
	prompt.Name, prompt.ActionText, prompt.ObjectText = "AbrirLoja", "Shop", "Hunting Shop"
	prompt.MaxActivationDistance, prompt.HoldDuration, prompt.Parent = 12, 0, shop
	prompt.RequiresLineOfSight, prompt.ClickablePrompt = false, true
	local sign = Instance.new("BillboardGui")
	sign.Size, sign.StudsOffset, sign.AlwaysOnTop, sign.Parent =
		UDim2.fromOffset(200, 40), Vector3.new(0, 3, 0), true, shop
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency, label.Text, label.TextSize = UDim2.fromScale(1, 1), 1, "HUNTING SHOP", 23
	label.Font, label.TextColor3, label.TextStrokeTransparency, label.Parent =
		Enum.Font.FredokaOne, Color3.new(1, 1, 1), 0, sign
	self.shop, self.prompt = shop, prompt
	self.seller = Stations.Ensure(world)
	return self
end
function World:RenderBase(base, profile)
	self.roaming:Sync(base, profile)
	local dummy = self.dummies[base]
	if dummy then
		local level = (profile.upgrades.Treino or 0) + 1
		local efficiency = (profile.upgrades.Multiplicador or 0) + 1
		if dummy:GetAttribute("TrainingLevel") ~= level or base.Esteira:GetAttribute("EfficiencyLevel") ~= efficiency then
			self.dummies[base] = TrainingDummies.Build(base, level, efficiency)
			base.Esteira:SetAttribute("EfficiencyLevel", efficiency)
			for _, state in pairs(self.exercise) do
				if state.base == base then state.target = self.dummies[base].Alvo end
			end
		end
		base.Esteira.Treinar.ObjectText = "Dummy "
			.. ((profile.upgrades.Treino or 0) + 1)
			.. " • +"
			.. C.TrainingGain(profile)
			.. " strength / "
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
		base = base,
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
	self.exercise[player] = state
	return true
end
return World
