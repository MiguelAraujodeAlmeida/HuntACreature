-- Owned creatures stay inside their base. Anchored visuals never push avatars.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Factory = require(script.Parent.CreatureFactory)
local Motion = require(game.ReplicatedStorage.HACShared.LumitoMotionConfig)
local Roaming = {}
Roaming.__index = Roaming
function Roaming.new(world)
	local self = setmetatable({ agents = {}, random = Random.new(), elapsed = 0 }, Roaming)
	self.connection = RunService.Heartbeat:Connect(function(dt)
		self.elapsed += dt
		if self.elapsed < C.BaseRoaming.Interval then
			return
		end
		local step = math.min(self.elapsed, 0.1)
		self.elapsed = 0
		self:Step(step)
	end)
	world.Destroying:Connect(function()
		self.connection:Disconnect()
	end)
	return self
end
function Roaming:Free(agent, point)
	local floor = agent.base.Plataforma
	local localPoint = floor.CFrame:PointToObjectSpace(point)
	local margin = agent.radius + C.BaseRoaming.Margin
	if math.abs(localPoint.X) > floor.Size.X / 2 - margin or math.abs(localPoint.Z) > floor.Size.Z / 2 - margin then
		return false
	end
	for _, name in ipairs({ "Esteira" }) do
		local obstacle = agent.base:FindFirstChild(name)
		if obstacle then
			local offset = obstacle.CFrame:PointToObjectSpace(point)
			if
				math.abs(offset.X) < obstacle.Size.X / 2 + margin
				and math.abs(offset.Z) < obstacle.Size.Z / 2 + margin
			then
				return false
			end
		end
	end
	for _, other in pairs(self.agents) do
		if other ~= agent and other.base == agent.base and other.model.Parent then
			if
				(Vector2.new(point.X, point.Z) - Vector2.new(other.position.X, other.position.Z)).Magnitude
				< agent.radius + other.radius
			then
				return false
			end
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if
			root
			and math.abs(root.Position.Y - point.Y) < 5
			and (Vector2.new(point.X, point.Z) - Vector2.new(root.Position.X, root.Position.Z)).Magnitude
				< agent.radius + 1.2
		then
			return false
		end
	end
	return true
end
function Roaming:Choose(agent)
	local floor = agent.base.Plataforma
	for _ = 1, 30 do
		local offset = Vector3.new(
			self.random:NextNumber(-0.5, 0.5) * floor.Size.X,
			0,
			self.random:NextNumber(-0.5, 0.5) * floor.Size.Z
		)
		local point = floor.CFrame:PointToWorldSpace(offset)
		point = Vector3.new(point.X, agent.height, point.Z)
		if self:Free(agent, point) then
			return point
		end
	end
	return nil
end
function Roaming:Sync(base, profile)
	local folder = base.CriaturasInstaladas
	local live = {}
	for _, model in ipairs(folder:GetChildren()) do
		local id = model:GetAttribute("CreatureId")
		if id and model:IsA("Model") then
			live[id] = model
		end
	end
	for id, item in pairs(profile.creatures) do
		if item.location == "base" then
			local model = live[id]
			if model and not self.agents[model] then
				model:Destroy()
				model = nil
			end
			if not model then
				local floor = base:FindFirstChild("Tapete") or base.Plataforma
				local agent = {
					base = base,
					radius = (C.Species[item.species].BodyRadius or 1.7) * item.size * 0.72,
					height = floor.Position.Y + floor.Size.Y / 2 + (C.Species[item.species].RootHeight or 1.625) * item.size * 0.72,
					pause = self.random:NextNumber(0, 1.5),
					phase = self.random:NextNumber(0, 6),
					direction = Vector3.new(0, 0, -1),
				}
				agent.position = self:Choose(agent)
				if not agent.position then
					-- The current base cannot fit several giant footprints. Keep the owned
					-- creature visible and still, rather than silently dropping its model.
					local center = floor.CFrame:PointToWorldSpace(Vector3.new(0, 0, floor.Size.Z * 0.12))
					agent.position = Vector3.new(center.X, agent.height, center.Z)
					agent.stationary = true
				end
				if agent.position then
					model = Factory.Build(folder, agent.position, item, true)
					agent.model = model
					local animatorName = item.species == "Chicken" and "ChickenAnimator" or "LumitoAnimator"
					agent.animator = require(script.Parent[animatorName]).new(model)
					agent.attentionClock = 0
					for _, part in ipairs(model:GetDescendants()) do
						if part:IsA("BasePart") then
							part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
						end
					end
					self.agents[model] = agent
				end
			end
			live[id] = nil
		end
	end
	for _, model in pairs(live) do
		self.agents[model] = nil
		model:Destroy()
	end
end
function Roaming:Step(dt)
	for model, agent in pairs(self.agents) do
		if not model.Parent or not agent.base.Parent then
			self.agents[model] = nil
			continue
		end
		agent.pause -= dt
		local moving = false
		if agent.pause <= 0 and not agent.stationary then
			agent.target = agent.target or self:Choose(agent)
			if agent.target then
				local delta = agent.target - agent.position
				if delta.Magnitude < 0.12 then
					agent.target = nil
					agent.pause = self.random:NextNumber(C.BaseRoaming.PauseMin, C.BaseRoaming.PauseMax)
				else
					local nextPoint = agent.position + delta.Unit * math.min(delta.Magnitude, C.BaseRoaming.Speed * dt)
					if self:Free(agent, nextPoint) then
						agent.position = nextPoint
						agent.direction = agent.direction:Lerp(delta.Unit, math.min(1, dt * 7))
						if agent.direction.Magnitude < 0.1 then
							agent.direction = delta.Unit
						end
						moving = true
					else
						agent.target, agent.pause = nil, self.random:NextNumber(0.3, 0.9)
					end
				end
			else
				agent.pause = 0.5
			end
		end
		agent.attentionClock -= dt
		if agent.attentionClock <= 0 then
			agent.attentionClock = Motion.AttentionInterval
			agent.attention = nil
			local best = Motion.AttentionDistance
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 then
					local distance = (root.Position - agent.position).Magnitude
					if distance < best then best, agent.attention = distance, root.Position end
				end
			end
		end
		agent.animator:Step(dt, CFrame.lookAt(agent.position, agent.position + agent.direction),
			"AtBase", moving and C.BaseRoaming.Speed or 0, not moving and agent.attention or nil)
	end
end
return Roaming
