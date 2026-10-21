-- Passeio -> visão -> pânico por tempo limitado -> cansaço -> passeio.
-- Movimento cinemático: os modelos de peças ancoradas não dependem de Humanoid/física.
local Behavior = {}
local Gameplay = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Animator = require(script.Parent.LumitoAnimator)
Behavior.__index = Behavior
local ANGLES = { 0, 35, -35, 70, -70, 110, -110, 180 }
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function unit(v, fallback)
	v = flat(v)
	return v.Magnitude > 0.001 and v.Unit or fallback
end

function Behavior.new(model, profile, service)
	local self = setmetatable({}, Behavior)
	self.model, self.profile, self.service = model, profile, service
	self.random = Random.new()
	self.scale = model:GetAttribute("CreatureScale") or 1
	self.radius = profile.BodyRadius * self.scale
	self.height = profile.RootHeight * self.scale
	self.bodySize = Vector3.new(self.radius * 2, 2.8 * self.scale, self.radius * 2)
	self.position = model.PrimaryPart.Position
	self.home = self.position
	self.facing = CFrame.Angles(0, self.random:NextNumber(-math.pi, math.pi), 0)
	self.direction = self.facing.LookVector
	self.moveDirection = Vector3.zero
	self.thinkIn, self.phase = self.random:NextNumber(0, profile.ThinkInterval), 0
	self.pause, self.walkTime = 0, 0
	self.walkFactor = 1
	self.stateTime = 0
	self.animator = Animator.new(model)
	self.cast = RaycastParams.new()
	self.cast.FilterType = Enum.RaycastFilterType.Exclude
	self.cast.RespectCanCollide = true
	self.overlap = OverlapParams.new()
	self.overlap.FilterType = Enum.RaycastFilterType.Exclude
	self.overlap.RespectCanCollide = true
	self.overlap.MaxParts = 1
	self.vision = RaycastParams.new()
	self.vision.FilterType = Enum.RaycastFilterType.Exclude
	self.vision.FilterDescendantsInstances = { service.wildFolder, service.effectsFolder }
	self:_refreshFilters()
	local grounded = self:_groundAt(self.position)
	if grounded then self.position, self.home = grounded, grounded end
	self:_setState("Wandering")
	model:PivotTo(CFrame.new(self.position) * self.facing)
	return self
end

function Behavior:_setState(state)
	if self.state == state then return end
	self.state, self.stateTime, self.thinkIn = state, 0, 0
	self.moveDirection = Vector3.zero
	if state == "Wandering" then
		self.goal = nil
		self:_pauseWalk()
	end
	self.model:SetAttribute("BehaviorState", state)
	-- Sinal curto no nome já existente; nenhuma nova janela/tutorial.
	local label = self.model.PrimaryPart:FindFirstChild("Identificacao")
	local text = label and label:FindFirstChildOfClass("TextLabel")
	if text then
		text.Text = self.model.Name .. (state == "Panicking" and "  !" or state == "Tired" and "  …" or "")
	end
end

function Behavior:_refreshFilters()
	local excluded = { self.service.wildFolder, self.service.effectsFolder }
	for _, actor in ipairs(self.service.actors) do table.insert(excluded, actor.character) end
	self.cast.FilterDescendantsInstances = excluded
	self.overlap.FilterDescendantsInstances = excluded
end

function Behavior:_inside(position)
	local ground = self.service.ground
	local localPoint = ground.CFrame:PointToObjectSpace(position)
	local margin = self.radius + self.profile.EdgeMargin
	return math.abs(localPoint.X) < ground.Size.X / 2 - margin
		and math.abs(localPoint.Z) < ground.Size.Z / 2 - margin
end

function Behavior:_groundAt(position)
	if not self:_inside(position) then return nil end
	-- The ray must still reach the floor when the root is several studs above it.
	local reach = math.max(9, self.height * 2 + 5)
	local hit = workspace:Raycast(position + Vector3.new(0, 3, 0), Vector3.new(0, -reach, 0), self.cast)
	if not hit or hit.Normal.Y < 0.85 then return nil end
	local y = hit.Position.Y + self.height
	if math.abs(y - self.position.Y) > self.profile.MaxStepHeight then return nil end
	return Vector3.new(position.X, y, position.Z)
end

function Behavior:_separated(position)
	-- Não empurrar personagens nem sobrepor outros Lumitos. Permite sair de uma
	-- sobreposição provocada pelo próprio jogador, em vez de prender a criatura.
	local function clear(otherPosition, gap, otherHeight)
		if math.abs(position.Y - otherPosition.Y) > self.height + otherHeight then return true end
		local nextDistance = flat(position - otherPosition).Magnitude
		local currentDistance = flat(self.position - otherPosition).Magnitude
		local movement = flat(position - self.position)
		if currentDistance < gap then
			return nextDistance > currentDistance + 0.01 and movement:Dot(flat(self.position - otherPosition)) >= 0
		end
		local lengthSquared = movement:Dot(movement)
		local t = lengthSquared > 0 and math.clamp(flat(otherPosition - self.position):Dot(movement) / lengthSquared, 0, 1) or 0
		return flat(self.position + movement * t - otherPosition).Magnitude >= gap
	end
	for model, other in pairs(self.service.agents) do
		if other ~= self and model.Parent == self.service.wildFolder then
			if not clear(other.position, self.radius + other.radius, other.height) then return false end
		end
	end
	for _, actor in ipairs(self.service.actors) do
		if actor.root.Parent and not clear(actor.root.Position, self.radius + 1.1, 3) then return false end
	end
	return true
end

function Behavior:_canStep(direction, distance)
	local destination = self:_groundAt(self.position + direction * distance)
	if not destination or not self:_separated(destination) then return nil end
	local offset = Vector3.new(0, 0.15, 0)
	-- Varredura do volume, mais sobreposição no destino: Blockcast sozinho não
	-- detecta obstáculos que já intersectam a forma inicial.
	if workspace:Blockcast(CFrame.new(self.position + offset), self.bodySize, destination - self.position, self.cast) then
		return nil
	end
	if #workspace:GetPartBoundsInBox(CFrame.new(destination + offset), self.bodySize, self.overlap) > 0 then
		return nil
	end
	return destination
end

function Behavior:_visibleThreat()
	local closest, best = nil, self.profile.ViewDistance
	local eye = self.position + Vector3.new(0, 0.45 * self.scale, 0)
	local forward = self.facing.LookVector
	local cosine = math.cos(math.rad(self.profile.ViewAngle / 2))
	for _, actor in ipairs(self.service.actors) do
		if actor.root.Parent and actor.humanoid.Health > 0 then
			local delta = actor.root.Position - eye
			local distance = delta.Magnitude
			if distance < best and forward:Dot(unit(delta, forward)) >= cosine then
				local hit = workspace:Raycast(eye, delta, self.vision)
				if not hit or hit.Instance:IsDescendantOf(actor.character) then
					closest, best = actor.root.Position, distance
				end
			end
		end
	end
	return closest
end

function Behavior:_wanderGoal()
	local angle = self.random:NextNumber(-math.pi, math.pi)
	local distance = self.random:NextNumber(4, self.profile.WanderRadius)
	local goal = self.home + Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance
	-- Alvos de passeio sempre ficam dentro da ilha, inclusive spawns próximos da borda.
	local ground = self.service.ground
	local p = ground.CFrame:PointToObjectSpace(goal)
	local margin = self.radius + self.profile.EdgeMargin + 1
	p = Vector3.new(math.clamp(p.X, -ground.Size.X / 2 + margin, ground.Size.X / 2 - margin), p.Y,
		math.clamp(p.Z, -ground.Size.Z / 2 + margin, ground.Size.Z / 2 - margin))
	self.goal = ground.CFrame:PointToWorldSpace(p)
end

function Behavior:_pauseWalk()
	local p = self.profile
	local long = self.random:NextNumber() < p.LongPauseChance
	self.pause = self.random:NextNumber(long and p.LongPauseMin or p.PauseMin, long and p.LongPauseMax or p.PauseMax)
	self.walkTime = 0
	self.moveDirection = Vector3.zero
end

function Behavior:_resumeWalk()
	if not self.goal or flat(self.goal - self.position).Magnitude < 1.5
		or self.random:NextNumber() >= self.profile.ResumeSameGoalChance then
		self:_wanderGoal()
	end
	self.walkTime = self.random:NextNumber(self.profile.WalkBurstMin, self.profile.WalkBurstMax)
	self.walkFactor = self.random:NextNumber(self.profile.WalkSpeedMinFactor, self.profile.WalkSpeedMaxFactor)
end

function Behavior:_chooseDirection(preferred, speed)
	local bestDirection, bestScore = Vector3.zero, -math.huge
	local lookAhead = math.max(2, speed * 0.35)
	for _, degrees in ipairs(ANGLES) do
		local direction = CFrame.Angles(0, math.rad(degrees), 0):VectorToWorldSpace(preferred)
		if self:_canStep(direction, lookAhead) then
			local score = direction:Dot(preferred) * 2 + direction:Dot(self.direction) * 0.45
			if score > bestScore then bestDirection, bestScore = direction, score end
		end
	end
	return bestDirection
end

function Behavior:_think()
	self:_refreshFilters()
	local threat = self:_visibleThreat()
	if threat then
		self.lastThreat = threat
		if self.state == "Wandering" then self:_setState("Panicking") end
	end
	local preferred
	if self.state == "Wandering" then
		local attractor = self.service.attractor and self.service.attractor(self.position, self.vision)
		if attractor then
			self.goal = Vector3.new(attractor.X, self.position.Y, attractor.Z)
			self.pause, self.walkTime = 0, math.max(self.walkTime, 1)
		end
		if self.pause > 0 then self.moveDirection = Vector3.zero; return end
		if self.walkTime <= 0 then self:_resumeWalk() end
		if flat(self.goal - self.position).Magnitude < 1.5 then
			self:_pauseWalk()
			return
		end
		preferred = unit(self.goal - self.position, self.direction)
	else
		-- Ao perder visão, foge da última posição vista; não acompanha através de paredes.
		preferred = self.lastThreat and unit(self.position - self.lastThreat, self.direction) or self.direction
	end
	self.moveDirection = self:_chooseDirection(preferred, self:_speed())
	if self.moveDirection.Magnitude < 0.01 and self.state == "Wandering" then
		self.goal = nil
		self:_pauseWalk()
	end
end

function Behavior:_speed()
	local speed = self.state == "Panicking" and self.profile.PanicSpeed
		or self.state == "Tired" and self.profile.TiredSpeed or self.profile.WalkSpeed * self.walkFactor
	return speed * ((self.model:GetAttribute("SlowedUntil") or 0) > os.clock() and Gameplay.Items.Armadilha.Slow or 1)
end

function Behavior:Step(dt)
	if self.model:GetAttribute("BusyUserId") ~= nil then
		if self.state ~= "Capturing" then
			self:_setState("Capturing")
		end
		self.phase += dt * (self.model:GetAttribute("CapturePhase") == "resist" and 15 or 9)
		self:_pose(false, dt)
		return -- A criatura resiste no lugar, sem consumir o timer de fuga.
	elseif self.state == "Capturing" then
		self:_setState("Tired") -- Escapou do laço: oferece janela lenta, sem sprint imediato.
	end
	self.stateTime += dt
	if self.state == "Wandering" then
		if self.pause > 0 then
			self.pause = math.max(0, self.pause - dt)
		elseif self.walkTime > 0 then
			self.walkTime -= dt
			if self.walkTime <= 0 then self:_pauseWalk() end
		end
	end
	if self.state == "Panicking" and self.stateTime >= self.profile.PanicSeconds then
		self:_setState("Tired")
	elseif self.state == "Tired" and self.stateTime >= self.profile.RecoverySeconds then
		self.lastThreat, self.goal = nil, nil
		self:_setState("Wandering")
	end
	self.thinkIn -= dt
	if self.thinkIn <= 0 then
		self:_think()
		self.thinkIn = self.profile.ThinkInterval
	end
	local moving = self.moveDirection.Magnitude > 0.01
	if moving then
		local destination = self:_canStep(self.moveDirection, self:_speed() * dt)
		if destination then
			self.position = destination
			self.direction = self.moveDirection
			local facing = CFrame.lookAt(Vector3.zero, self.direction)
			self.facing = self.facing:Lerp(facing, 1 - math.exp(-dt * 12))
		else
			moving = false
			self.moveDirection = Vector3.zero
			self.thinkIn = 0
		end
	end
	self.phase += dt * (self.state == "Panicking" and 18 or 7)
	self:_pose(moving, dt)
end

function Behavior:_pose(moving, dt)
	local slow = (self.model:GetAttribute("SlowedUntil") or 0) > os.clock()
	if self.wasSlowed ~= slow then
		self.wasSlowed = slow
		local label = self.model.PrimaryPart:FindFirstChild("Identificacao")
		local text = label and label:FindFirstChildOfClass("TextLabel")
		if text then text.Text = self.model.Name .. (slow and " • SLOWED" or self.state == "Panicking" and " !" or self.state == "Tired" and " …" or "") end
	end
	self.animator:Step(dt, CFrame.new(self.position) * self.facing, self.state,
		moving and self:_speed() or 0, self.lastThreat, self.model:GetAttribute("CapturePhase"))
end

return Behavior
