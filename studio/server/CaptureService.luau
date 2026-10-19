-- Apenas este módulo decide carga, trajetória, acerto e resultado da captura.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(game:GetService("ReplicatedStorage").HACShared.CaptureConfig)

local Aim = require(game.ReplicatedStorage.HACShared.LassoAim)
local Visuals = require(game.ReplicatedStorage.HACShared.LassoVisuals)
local Collision = require(script.Parent.LassoCollision)
local Gameplay = require(game.ReplicatedStorage.HACShared.GameplayConfig)

local CaptureService = {}
CaptureService.__index = CaptureService

local function finiteVector(value)
	return typeof(value) == "Vector3"
		and value.X == value.X
		and value.Y == value.Y
		and value.Z == value.Z
		and math.abs(value.X) < 100000
		and math.abs(value.Y) < 100000
		and math.abs(value.Z) < 100000
end

local function playerRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function equippedLasso(player)
	local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	return tool and Config.Lassos[tool.Name], tool and tool.Name
end

local function tether(player, creature)
	local character = player.Character
	local hand = character
		and (
			character:FindFirstChild("RightHand")
			or character:FindFirstChild("Right Arm")
			or character:FindFirstChild("HumanoidRootPart")
		)
	local target = creature.PrimaryPart
	if not hand or not target then
		return nil
	end
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
	return { from = from, to = to, beam = beam }
end

local function rewardBurst(parent, position, golden)
	local colors = golden
			and { Color3.fromRGB(255, 220, 75), Color3.fromRGB(255, 247, 190), Color3.fromRGB(255, 146, 75) }
		or { Color3.fromRGB(68, 222, 242), Color3.fromRGB(255, 219, 102), Color3.fromRGB(111, 238, 160) }
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
			Position = position
				+ Vector3.new(math.cos(angle) * distance, 1.2 + (i % 3) * 0.8, math.sin(angle) * distance),
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
	self.connection = RunService.Heartbeat:Connect(function(dt)
		self:_step(dt)
	end)
	return self
end

function CaptureService:_finish(player, success, message)
	local session = self.sessions[player]
	if not session then
		return
	end
	self.sessions[player] = nil
	if session.tether then
		session.tether.from:Destroy()
		session.tether.to:Destroy()
	end
	if session.creature and session.creature.Parent then
		session.creature:SetAttribute("BusyUserId", nil)
	end
	if success and session.creature and session.creature.Parent then
		local position = session.creature.PrimaryPart.Position
		success = self.onCaptured(player, session.creature) == true
		if success then
			rewardBurst(self.effectsFolder, position, session.golden)
		else
			message = "Could not store the creature. Check your bag."
		end
	end
	self.remote:FireClient(player, "CaptureEnd", success, message, session.golden)
end

function CaptureService:_beginCapture(player, creature, lasso)
	local required = Gameplay.MinimumStrength(creature:GetAttribute("Species"))
	if (player:GetAttribute("Forca") or 0) < required then
		return false, string.format("Requires %s strength", tostring(required))
	end
	if self.sessions[player] or not creature.Parent or creature.Parent ~= self.wildFolder then
		return false, "This creature is no longer available."
	end
	if creature:GetAttribute("BusyUserId") then
		return false, "Someone is already capturing this creature."
	end
	if not self.canCarry(player) then
		return false, "Bag full. Equip creatures at your base."
	end
	local root = playerRoot(player)
	if
		not root
		or not equippedLasso(player)
		or (root.Position - creature.PrimaryPart.Position).Magnitude > lasso.MaximumRange + 10
	then
		return false, "The creature moved out of range."
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

function CaptureService:_clearProjectile(player, ready)
	local projectile = self.projectiles[player]
	if projectile then
		Visuals.CleanupLine(projectile.line)
		projectile.visual:Destroy()
		self.projectiles[player] = nil
	end
	if ready then
		local cooldown = projectile and projectile.lasso.CooldownSeconds or 0
		self.cooldowns[player] = os.clock() + cooldown
		self.remote:FireClient(player, "ThrowReady", cooldown)
	end
end

function CaptureService:_returnProjectile(player, reason)
	local projectile = self.projectiles[player]
	if not projectile or projectile.returning then
		return
	end
	projectile.returning = true
	if projectile.line then
		projectile.line.beam.CurveSize0 = 1.2
	end
	self.remote:FireClient(player, "ThrowMiss", reason)
end

function CaptureService:_startCharge(player)
	local function deny(message)
		self.remote:FireClient(player, "ChargeDenied", message)
	end
	if self.charges[player] or self.projectiles[player] or self.sessions[player] then
		deny()
		return
	end
	if os.clock() < (self.cooldowns[player] or 0) then
		deny()
		return
	end
	if player:GetAttribute("Treinando") then
		deny("Leave training before hunting.")
		return
	end
	if player:GetAttribute("ProfileReady") ~= true then
		deny("Your progress is loading.")
		return
	end
	local lasso, name = equippedLasso(player)
	if not playerRoot(player) or not lasso then
		deny()
		return
	end
	-- Bolsa cheia bloqueia somente a captura. Arremessar continua permitido.
	self.charges[player] = { started = os.clock(), lassoName = name }
	self.remote:FireClient(player, "ChargeReady")
end

function CaptureService:_throw(player, ray)
	local charge = self.charges[player]
	self.charges[player] = nil
	if not charge or self.projectiles[player] or self.sessions[player] then
		return
	end
	local root = playerRoot(player)
	local lasso, name = equippedLasso(player)
	if not root or not lasso or name ~= charge.lassoName or player:GetAttribute("Treinando") then
		self.remote:FireClient(player, "ThrowReady", 0)
		return
	end
	local allowedCameraDistance =
		math.min(Config.MaximumCameraDistance, (player.CameraMaxZoomDistance or 128) + Config.CameraTolerance)
	if
		typeof(ray) ~= "table"
		or not finiteVector(ray.origin)
		or not finiteVector(ray.direction)
		or (ray.origin - root.Position).Magnitude > allowedCameraDistance
		or ray.direction.Magnitude < 0.9
		or ray.direction.Magnitude > 1.1
	then
		-- Dados de rede inválidos são rejeitados; mirar no céu/chão não é inválido.
		self.remote:FireClient(player, "ThrowReady", 0)
		return
	end
	local power = math.clamp((os.clock() - charge.started) / lasso.ChargeSeconds, 0, 1)
	local params = Aim.Params({ player.Character, self.effectsFolder })
	local range = Aim.Range(lasso, power)
	local resolved = Aim.Resolve(Aim.Origin(player.Character), ray, range, params, Config.AimLimit)
	local blockers = Aim.Params({ player.Character, self.effectsFolder, self.wildFolder })
	local visual = Visuals.Loop(self.effectsFolder)
	visual:PivotTo(CFrame.lookAt(resolved.origin, resolved.origin + resolved.direction))
	self.projectiles[player] = {
		visual = visual,
		line = Visuals.Line(player.Character, visual.PrimaryPart),
		position = resolved.origin,
		startPosition = resolved.origin,
		direction = resolved.direction,
		-- O ponto visto ao lançar define a direção, não um limite congelado no alvo.
		-- Obstáculos e criaturas são consultados novamente durante todo o voo.
		distance = range,
		travel = 0,
		lasso = lasso,
		params = blockers,
		creatures = Collision.Snapshot(self.wildFolder),
	}
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
		if session then
			session.holding = value
		end
	end
end

function CaptureService:_stepProjectile(player, projectile, dt)
	local root = playerRoot(player)
	if not root or not equippedLasso(player) then
		self:_clearProjectile(player, true)
		return
	end
	if projectile.returning then
		local destination = Aim.Origin(player.Character)
		local delta = destination - projectile.position
		if delta.Magnitude < 1 then
			self:_clearProjectile(player, true)
			return
		end
		projectile.position += delta.Unit * math.min(delta.Magnitude, projectile.lasso.ReturnSpeed * dt)
		projectile.visual:PivotTo(CFrame.lookAt(projectile.position, projectile.position + projectile.direction))
		return
	end
	projectile.travel = math.min(projectile.distance, projectile.travel + projectile.lasso.ProjectileSpeed * dt)
	local nextPosition = projectile.startPosition + projectile.direction * projectile.travel
	local movement = nextPosition - projectile.position
	local hit = movement.Magnitude > 0
			and workspace:Spherecast(projectile.position, Config.LoopRadius, movement, projectile.params)
		or nil
	local current = Collision.Snapshot(self.wildFolder)
	local blockerT = hit and hit.Distance / movement.Magnitude or nil
	local creature, contactT = Collision.Find(
		projectile.position,
		nextPosition,
		projectile.creatures,
		current,
		Config.LoopRadius,
		blockerT,
		projectile.params
	)
	projectile.creatures = current
	-- Spherecast.Position é a superfície atingida, não o centro do laço.
	projectile.position = projectile.position:Lerp(nextPosition, contactT or blockerT or 1)
	projectile.visual:PivotTo(
		CFrame.lookAt(projectile.position, projectile.position + projectile.direction)
			* CFrame.Angles(0, 0, projectile.travel * 0.14)
	)
	if hit or creature then
		Visuals.Burst(
			self.effectsFolder,
			projectile.position,
			creature and Color3.fromRGB(255, 221, 60) or Color3.fromRGB(100, 225, 255),
			creature and 12 or 5
		)
		if creature then
			local captured, reason = self:_beginCapture(player, creature, projectile.lasso)
			if captured then
				self:_clearProjectile(player, false)
			else
				self:_returnProjectile(player, reason)
			end
		else
			self:_returnProjectile(player)
		end
	elseif projectile.travel >= projectile.distance then
		self:_returnProjectile(player)
	end
end

function CaptureService:_stepSession(player, session, dt)
	local creature = session.creature
	local root = playerRoot(player)
	if
		not root
		or not creature.Parent
		or (root.Position - creature.PrimaryPart.Position).Magnitude > session.maxDistance
	then
		self:_finish(player, false, nil)
		return
	end
	local elapsed = os.clock() - session.started
	if elapsed > Config.CaptureTimeLimit then
		self:_finish(player, false, "The creature escaped.")
		return
	end
	session.goalTimer -= dt
	if session.goalTimer <= 0 then
		session.goal = self.random:NextNumber(0.18, 0.82)
		session.goalTimer = self.random:NextNumber(session.golden and 0.5 or 0.65, session.golden and 0.85 or 1.05)
	end
	local difficulty = creature:GetAttribute("Difficulty") or 1
	local potion = (session.potionUntil or 0) > os.clock()
	local targetSpeed = 2.15 * difficulty * (potion and Gameplay.Items.Pocao.Slow or 1)
	session.target += (session.goal - session.target) * math.min(1, dt * targetSpeed)
	local desiredVelocity = session.holding and Config.ZoneMaxSpeed or -Config.ZoneMaxSpeed * 0.86
	session.zoneVelocity += (desiredVelocity - session.zoneVelocity) * math.min(1, dt * Config.ZoneFriction)
	session.zone = math.clamp(session.zone + session.zoneVelocity * dt, 0.06, 0.94)
	if session.zone == 0.06 or session.zone == 0.94 then
		session.zoneVelocity = 0
	end
	local strength = math.max(0, player:GetAttribute("Forca") or 0)
	local radius = Config.ZoneRadius + Config.StrengthRadiusBonus * strength / (strength + Config.StrengthHalfBonus)
	local overlap = math.abs(session.target - session.zone) <= radius
	if session.tether then
		session.tether.beam.Width0 = overlap and 0.23 or 0.16
		session.tether.beam.Width1 = session.tether.beam.Width0
	end
	local gain = Config.NormalGain / difficulty
	session.streak = math.clamp(session.streak + (overlap and 1 or -2) * dt, 0, 1.5)
	session.progress =
		math.clamp(session.progress + (overlap and gain * (1 + session.streak * 0.35) or -Config.MissDecay) * dt, 0, 1)
	session.sendTime += dt
	if session.sendTime >= Config.StateInterval then
		session.sendTime = 0
		self.remote:FireClient(player, "CaptureState", {
			target = session.target,
			zone = session.zone,
			radius = radius,
			progress = session.progress,
			overlap = overlap,
			streak = session.streak,
			timeLeft = Config.CaptureTimeLimit - elapsed,
			potion = potion,
		})
	end
	if session.progress >= 1 then
		self:_finish(player, true, "Lumito captured!")
	end
end

function CaptureService:_step(dt)
	dt = math.min(dt, 0.08)
	for player, charge in pairs(self.charges) do
		if
			not playerRoot(player)
			or not equippedLasso(player)
			or os.clock() - charge.started > Config.MaximumChargeSeconds
		then
			self.charges[player] = nil
			self.remote:FireClient(player, "ChargeDenied")
		end
	end
	for player, projectile in pairs(self.projectiles) do
		self:_stepProjectile(player, projectile, dt)
	end
	for player, session in pairs(self.sessions) do
		self:_stepSession(player, session, dt)
	end
end

function CaptureService:PlayerRemoving(player)
	self.charges[player] = nil
	self.cooldowns[player] = nil
	local projectile = self.projectiles[player]
	if projectile then
		self:_clearProjectile(player, false)
	end
	local session = self.sessions[player]
	if session and session.tether then
		session.tether.from:Destroy()
		session.tether.to:Destroy()
	end
	if session and session.creature.Parent then
		session.creature:SetAttribute("BusyUserId", nil)
	end
	self.sessions[player] = nil
end

return CaptureService
