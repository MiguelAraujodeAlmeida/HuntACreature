-- Apenas este módulo decide carga, trajetória, acerto e resultado da captura.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(game:GetService("ReplicatedStorage").HACShared.CaptureConfig)

local CaptureService = {}
CaptureService.__index = CaptureService

local function finiteVector(value)
	return typeof(value) == "Vector3"
		and value.X == value.X and value.Y == value.Y and value.Z == value.Z
		and math.abs(value.X) < 100000 and math.abs(value.Y) < 100000 and math.abs(value.Z) < 100000
end

local function playerRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil end
	return character:FindFirstChild("HumanoidRootPart")
end

local function equippedLasso(player)
	local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	return tool and Config.Lassos[tool.Name], tool and tool.Name
end

local function wildCreatureFromHit(instance, wildFolder)
	local current = instance
	while current and current.Parent ~= wildFolder do current = current.Parent end
	return current and current:IsA("Model") and current or nil
end

local function ropeLoop(parent)
	local model = Instance.new("Model")
	model.Name = "LacoArremessado"
	local center = Instance.new("Part")
	center.Name = "Centro"
	center.Size = Vector3.new(0.2, 0.2, 0.2)
	center.Transparency = 1
	center.Anchored = true
	center.CanCollide = false
	center.CanQuery = false
	center.Parent = model
	model.PrimaryPart = center
	for i = 1, 12 do
		local angle = i * math.pi / 6
		local piece = Instance.new("Part")
		piece.Name = "Corda"
		piece.Size = Vector3.new(0.18, 0.58, 0.18)
		piece.CFrame = CFrame.new(math.cos(angle) * 0.94, math.sin(angle) * 0.94, 0) * CFrame.Angles(0, 0, angle)
		piece.Color = Color3.fromRGB(255, 226, 141)
		piece.Material = Enum.Material.SmoothPlastic
		piece.Anchored = true
		piece.CanCollide = false
		piece.CanTouch = false
		piece.CanQuery = false
		piece.Parent = model
	end
	model.Parent = parent
	return model
end

local function tether(player, creature)
	local character = player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") or character:FindFirstChild("HumanoidRootPart"))
	local target = creature.PrimaryPart
	if not hand or not target then return nil end
	local from = Instance.new("Attachment")
	from.Name = "HACLacoOrigem"
	from.Parent = hand
	local to = Instance.new("Attachment")
	to.Name = "HACLacoAlvo"
	to.Parent = target
	local beam = Instance.new("Beam")
	beam.Name = "LacoEmDisputa"
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.Width0 = 0.16
	beam.Width1 = 0.16
	beam.Segments = 10
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 220, 122))
	beam.Transparency = NumberSequence.new(0.12)
	beam.Parent = from
	return {from = from, to = to, beam = beam}
end

local function rewardBurst(parent, position, golden)
	local colors = golden
		and {Color3.fromRGB(255, 220, 75), Color3.fromRGB(255, 247, 190), Color3.fromRGB(255, 146, 75)}
		or {Color3.fromRGB(68, 222, 242), Color3.fromRGB(255, 219, 102), Color3.fromRGB(111, 238, 160)}
	for i = 1, golden and 20 or 14 do
		local angle = i * math.pi * 2 / (golden and 20 or 14)
		local spark = Instance.new("Part")
		spark.Name = "BrilhoCaptura"
		spark.Shape = Enum.PartType.Ball
		spark.Size = Vector3.new(0.42, 0.42, 0.42)
		spark.Color = colors[(i - 1) % #colors + 1]
		spark.Material = Enum.Material.Neon
		spark.Anchored = true
		spark.CanCollide = false
		spark.CanTouch = false
		spark.CanQuery = false
		spark.Position = position
		spark.Parent = parent
		local distance = golden and 5.5 or 3.8
		TweenService:Create(spark, TweenInfo.new(0.72, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = position + Vector3.new(math.cos(angle) * distance, 1.2 + (i % 3) * 0.8, math.sin(angle) * distance),
			Size = Vector3.new(0.08, 0.08, 0.08),
			Transparency = 1,
		}):Play()
		Debris:AddItem(spark, 0.8)
	end
end

function CaptureService.new(options)
	local self = setmetatable({}, CaptureService)
	self.remote = options.remote
	self.wildFolder = options.wildFolder
	self.effectsFolder = options.effectsFolder
	self.canCarry = options.canCarry
	self.onCaptured = options.onCaptured
	self.notice = options.notice
	self.charges = {}
	self.projectiles = {}
	self.sessions = {}
	self.cooldowns = {}
	self.random = Random.new()
	self.connection = RunService.Heartbeat:Connect(function(dt) self:_step(dt) end)
	return self
end

function CaptureService:_finish(player, success, message)
	local session = self.sessions[player]
	if not session then return end
	self.sessions[player] = nil
	if session.tether then
		session.tether.from:Destroy()
		session.tether.to:Destroy()
	end
	if session.creature and session.creature.Parent then
		session.creature:SetAttribute("BusyUserId", nil)
	end
	if success and session.creature and session.creature.Parent then
		rewardBurst(self.effectsFolder, session.creature.PrimaryPart.Position, session.golden)
		self.onCaptured(player, session.creature)
	end
	self.remote:FireClient(player, "CaptureEnd", success, message, session.golden)
end

function CaptureService:_beginCapture(player, creature, lasso)
	if self.sessions[player] or not creature.Parent or creature.Parent ~= self.wildFolder then
		return false, "A criatura não está mais disponível."
	end
	if creature:GetAttribute("BusyUserId") then
		return false, "Esse Lumito já está sendo capturado."
	end
	if not self.canCarry(player) then
		return false, "Bolsa cheia: instale suas criaturas na base."
	end
	local root = playerRoot(player)
	if not root or not equippedLasso(player) or (root.Position - creature.PrimaryPart.Position).Magnitude > lasso.MaximumRange + 10 then
		return false, "A criatura saiu do alcance."
	end
	creature:SetAttribute("BusyUserId", player.UserId)
	local golden = creature:GetAttribute("Golden") == true
	self.sessions[player] = {
		creature = creature,
		golden = golden,
		started = os.clock(),
		zone = 0.5,
		zoneVelocity = 0,
		target = 0.5,
		goal = 0.5,
		goalTimer = 0,
		progress = 0.16,
		maxDistance = lasso.MaximumRange + 10,
		streak = 0,
		tether = tether(player, creature),
		holding = false,
		sendTime = 0,
	}
	self.remote:FireClient(player, "CaptureStart", creature.Name, golden)
	return true
end

function CaptureService:_miss(player, reason)
	local projectile = self.projectiles[player]
	if not projectile then return end
	projectile.visual:Destroy()
	self.projectiles[player] = nil
	self.remote:FireClient(player, "ThrowMiss", reason or "O laço errou o alvo.")
end

function CaptureService:_startCharge(player)
	local function deny(message)
		self.remote:FireClient(player, "ChargeDenied", message)
	end
	if self.charges[player] or self.projectiles[player] or self.sessions[player] then deny("Aguarde o laço terminar."); return end
	if os.clock() < (self.cooldowns[player] or 0) then deny("Espere um instante para lançar de novo."); return end
	if player:GetAttribute("Treinando") then deny("Encerre o treino antes de caçar."); return end
	local lasso, lassoName = equippedLasso(player)
	if not playerRoot(player) or not lasso then deny("Equipe o laço para caçar."); return end
	if not self.canCarry(player) then
		deny("Bolsa cheia: volte à sua base.")
		return
	end
	self.charges[player] = {started = os.clock(), lassoName = lassoName}
	self.remote:FireClient(player, "ChargeReady")
end

function CaptureService:_throw(player, aimRay)
	local charge = self.charges[player]
	self.charges[player] = nil
	if not charge or self.projectiles[player] or self.sessions[player] then return end
	local root = playerRoot(player)
	local lasso, lassoName = equippedLasso(player)
	if not root or not lasso or lassoName ~= charge.lassoName or player:GetAttribute("Treinando") then return end
	if typeof(aimRay) ~= "table" or not finiteVector(aimRay.origin) or not finiteVector(aimRay.direction)
		or (aimRay.origin - root.Position).Magnitude > Config.MaximumCameraDistance
		or aimRay.direction.Magnitude < 0.9 or aimRay.direction.Magnitude > 1.1 then
		self.remote:FireClient(player, "ThrowMiss", "Mira inválida.")
		return
	end
	local cameraParams = RaycastParams.new()
	cameraParams.FilterType = Enum.RaycastFilterType.Exclude
	cameraParams.FilterDescendantsInstances = {player.Character, self.effectsFolder}
	local cameraHit = workspace:Raycast(aimRay.origin, aimRay.direction.Unit * Config.AimLimit, cameraParams)
	local aimPoint = cameraHit and cameraHit.Position or aimRay.origin + aimRay.direction.Unit * Config.AimLimit
	local origin = root.Position + Vector3.new(0, 1.3, 0)
	local aimDelta = aimPoint - origin
	local aimDistance = aimDelta.Magnitude
	if aimDistance < 1 then
		self.remote:FireClient(player, "ThrowMiss", "Mira muito próxima.")
		return
	end
	local direction = aimDelta.Unit
	local chargeTime = math.clamp(os.clock() - charge.started, Config.MinimumChargeSeconds, lasso.ChargeSeconds)
	local power = math.clamp(chargeTime / lasso.ChargeSeconds, 0, 1)
	local range = lasso.MinimumRange + (lasso.MaximumRange - lasso.MinimumRange) * power
	local distance = math.min(aimDistance, range)
	local endPosition = origin + direction * distance
	local candidate = cameraHit and wildCreatureFromHit(cameraHit.Instance, self.wildFolder)
	local creature
	local targetPart
	local localHitPoint
	if candidate and aimDistance <= range + 0.01 then
		creature = candidate
		targetPart = cameraHit.Instance
		localHitPoint = targetPart.CFrame:PointToObjectSpace(cameraHit.Position)
	end
	local visual = ropeLoop(self.effectsFolder)
	visual:PivotTo(CFrame.lookAt(origin, endPosition))
	self.projectiles[player] = {
		visual = visual,
		startPosition = origin,
		endPosition = endPosition,
		direction = direction,
		duration = math.clamp(distance / lasso.ProjectileSpeed, 0.12, 1.1),
		elapsed = 0,
		lasso = lasso,
		creature = creature,
		targetPart = targetPart,
		localHitPoint = localHitPoint,
		missReason = candidate and aimDistance > range and "Alvo fora do alcance." or nil,
	}
	self.cooldowns[player] = os.clock() + lasso.CooldownSeconds
	self.remote:FireClient(player, "ThrowLaunched", power)
end

function CaptureService:HandleRemote(player, action, value)
	if action == "ChargeStart" then
		self:_startCharge(player)
	elseif action == "ChargeCancel" then
		self.charges[player] = nil
	elseif action == "Throw" then
		self:_throw(player, value)
	elseif action == "Hold" and typeof(value) == "boolean" then
		local session = self.sessions[player]
		if session then session.holding = value end
	end
end

function CaptureService:_stepProjectile(player, projectile, dt)
	if not playerRoot(player) then
		self:_miss(player, "Lançamento interrompido.")
		return
	end
	projectile.elapsed = math.min(projectile.duration, projectile.elapsed + dt)
	local t = projectile.elapsed / projectile.duration
	local position = projectile.startPosition:Lerp(projectile.endPosition, t)
	projectile.visual:PivotTo(CFrame.lookAt(position, position + projectile.direction) * CFrame.Angles(0, 0, t * 8))
	if t < 1 then return end
	local creature = projectile.creature
	local targetPart = projectile.targetPart
	if creature and creature.Parent == self.wildFolder and targetPart and targetPart:IsDescendantOf(creature)
		and (targetPart.CFrame:PointToWorldSpace(projectile.localHitPoint) - projectile.endPosition).Magnitude <= Config.MovingTargetTolerance then
		projectile.visual:Destroy()
		self.projectiles[player] = nil
		local captured, reason = self:_beginCapture(player, creature, projectile.lasso)
		if not captured then self.remote:FireClient(player, "ThrowMiss", reason) end
	else
		self:_miss(player, projectile.missReason)
	end
end

function CaptureService:_stepSession(player, session, dt)
	local creature = session.creature
	local root = playerRoot(player)
	if not root or not creature.Parent or not equippedLasso(player)
		or (root.Position - creature.PrimaryPart.Position).Magnitude > session.maxDistance then
		self:_finish(player, false, "O laço perdeu a criatura. Tente novamente.")
		return
	end
	local elapsed = os.clock() - session.started
	if elapsed > Config.CaptureTimeLimit then
		self:_finish(player, false, "O Lumito escapou. Tente outra vez!")
		return
	end
	session.goalTimer -= dt
	if session.goalTimer <= 0 then
		session.goal = self.random:NextNumber(0.18, 0.82)
		session.goalTimer = self.random:NextNumber(session.golden and 0.5 or 0.65, session.golden and 0.85 or 1.05)
	end
	local targetSpeed = session.golden and 2.7 or 2.15
	session.target += (session.goal - session.target) * math.min(1, dt * targetSpeed)
	local desiredVelocity = session.holding and Config.ZoneMaxSpeed or -Config.ZoneMaxSpeed * 0.86
	session.zoneVelocity += (desiredVelocity - session.zoneVelocity) * math.min(1, dt * Config.ZoneFriction)
	session.zone = math.clamp(session.zone + session.zoneVelocity * dt, 0.06, 0.94)
	if session.zone == 0.06 or session.zone == 0.94 then session.zoneVelocity = 0 end
	local strength = math.min(player:GetAttribute("Forca") or 0, 15)
	local radius = Config.ZoneRadius + strength * 0.003
	local overlap = math.abs(session.target - session.zone) <= radius
	if session.tether then
		session.tether.beam.Width0 = overlap and 0.23 or 0.16
		session.tether.beam.Width1 = session.tether.beam.Width0
	end
	local gain = session.golden and Config.GoldenGain or Config.NormalGain
	session.streak = math.clamp(session.streak + (overlap and 1 or -2) * dt, 0, 1.5)
	session.progress = math.clamp(session.progress + (overlap and gain * (1 + session.streak * 0.35) or -Config.MissDecay) * dt, 0, 1)
	session.sendTime += dt
	if session.sendTime >= Config.StateInterval then
		session.sendTime = 0
		self.remote:FireClient(player, "CaptureState", {
			target = session.target,
			zone = session.zone,
			progress = session.progress,
			overlap = overlap,
			streak = session.streak,
			timeLeft = Config.CaptureTimeLimit - elapsed,
		})
	end
	if session.progress >= 1 then
		self:_finish(player, true, "Lumito capturado!")
	end
end

function CaptureService:_step(dt)
	dt = math.min(dt, 0.08)
	for player, projectile in pairs(self.projectiles) do self:_stepProjectile(player, projectile, dt) end
	for player, session in pairs(self.sessions) do self:_stepSession(player, session, dt) end
end

function CaptureService:PlayerRemoving(player)
	self.charges[player] = nil
	self.cooldowns[player] = nil
	local projectile = self.projectiles[player]
	if projectile then projectile.visual:Destroy(); self.projectiles[player] = nil end
	local session = self.sessions[player]
	if session and session.tether then
		session.tether.from:Destroy()
		session.tether.to:Destroy()
	end
	if session and session.creature.Parent then session.creature:SetAttribute("BusyUserId", nil) end
	self.sessions[player] = nil
end

return CaptureService
