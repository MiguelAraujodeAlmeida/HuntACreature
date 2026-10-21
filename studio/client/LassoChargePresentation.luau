-- Client-only charge theatre. The server validates charge and replicates just its start/end.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").HACShared
local Config = require(Shared.CaptureConfig)
local Styles = require(Shared.LassoChargeStyle)
local Visuals = require(Shared.LassoVisuals)

local Presentation = {}
Presentation.__index = Presentation
local CHARGE_ATTRIBUTE = "HACLassoCharging"
local START_ATTRIBUTE = "HACLassoChargeStartedAt"

local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function handOf(character)
	return character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
		or character:FindFirstChild("HumanoidRootPart")
end

local function jointsOf(character)
	local joints = {}
	for _, item in ipairs(character:GetDescendants()) do
		if (item:IsA("Motor6D") or item:IsA("AnimationConstraint")) then
			if item.Name == "RightShoulder" or item.Name == "Right Shoulder" then
				joints.shoulder = item
			elseif item.Name == "RightElbow" then
				joints.elbow = item
			elseif item.Name == "RightWrist" then
				joints.wrist = item
			elseif item.Name == "LeftShoulder" or item.Name == "Left Shoulder" then
				joints.leftShoulder = item
			elseif item.Name == "Waist" then
				joints.waist = item
			end
		end
	end
	return joints
end

local function hideTool(character)
	local hidden = {}
	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		for _, descendant in ipairs(tool:GetDescendants()) do
			if descendant:IsA("BasePart") then
				hidden[descendant] = descendant.LocalTransparencyModifier
				descendant.LocalTransparencyModifier = 1
			end
		end
	end
	return hidden
end

local function restoreTool(hidden)
	for part, original in pairs(hidden) do
		if part.Parent then
			part.LocalTransparencyModifier = original
		end
	end
end

local function makeEffect(parent, character, lassoName, started, localOwner)
	local head = character:FindFirstChild("Head")
	local hand = handOf(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not head or not hand or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local style = Styles.For(lassoName)
	local ring = Instance.new("Model")
	ring.Name = "ChargeBoleio_" .. character.Name
	local segments = {}
	for i = 1, style.SegmentCount do
		local segment = Instance.new("Part")
		segment.Name = "FlexibleRope"
		segment.Size = Vector3.new(0.12, 0.25, 0.12)
		segment.Color = style.RopeColor
		segment.Material = Enum.Material.SmoothPlastic
		segment.Anchored = true
		segment.CanCollide = false
		segment.CanTouch = false
		segment.CanQuery = false
		segment.CastShadow = false
		segment.Transparency = 1
		segment.Parent = ring
		segments[i] = segment
	end
	local knot = Instance.new("Part")
	knot.Name = "OrbitingKnot"
	knot.Shape = Enum.PartType.Ball
	knot.Size = Vector3.new(0.32, 0.32, 0.32)
	knot.Color = style.BrightColor
	knot.Material = Enum.Material.Neon
	knot.Anchored = true
	knot.CanCollide = false
	knot.CanTouch = false
	knot.CanQuery = false
	knot.CastShadow = false
	knot.Transparency = 1
	knot.Parent = ring
	local swish = Instance.new("Part")
	swish.Name = "RopeTipTrailAnchor"
	swish.Size = Vector3.new(0.1, 0.1, 0.1)
	swish.Transparency = 1
	swish.Anchored = true
	swish.CanCollide = false
	swish.CanTouch = false
	swish.CanQuery = false
	swish.CastShadow = false
	swish.Parent = ring
	local trail0 = Instance.new("Attachment")
	trail0.Position = Vector3.new(0, 0.12, 0)
	trail0.Parent = swish
	local trail1 = Instance.new("Attachment")
	trail1.Position = Vector3.new(0, -0.12, 0)
	trail1.Parent = swish
	local trail = Instance.new("Trail")
	trail.Attachment0 = trail0
	trail.Attachment1 = trail1
	trail.Lifetime = style.TrailLifetime
	trail.MinLength = 0.12
	trail.LightEmission = 0.55
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(style.BrightColor, style.RopeColor)
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Enabled = false
	trail.Parent = swish
	local line = Visuals.Line(character, knot)
	if line then
		line.beam.CurveSize0 = 0.35
		line.beam.CurveSize1 = -0.25
		line.beam.Width0 = 0.1
		line.beam.Width1 = 0.1
		line.beam.Transparency = NumberSequence.new(1)
	end
	ring.Parent = parent
	return {
		character = character, head = head, hand = hand, ring = ring, knot = knot, swish = swish, segments = segments,
		trail = trail, line = line, style = style, lassoName = lassoName,
		started = started, localOwner = localOwner, phase = 0, lastTime = os.clock(),
		joints = jointsOf(character), hidden = hideTool(character), fullAccent = false,
	}
end

local function destroyEffect(effect)
	if effect.line then Visuals.CleanupLine(effect.line) end
	restoreTool(effect.hidden)
	for _, joint in pairs(effect.joints) do
		if joint.Parent then
			pcall(function() joint.Transform = CFrame.identity end)
		end
	end
	effect.ring:Destroy()
end

function Presentation.new(localPlayer)
	local self = setmetatable({}, Presentation)
	self.localPlayer = localPlayer
	self.effects = {}
	self.connections = {}
	self.characterConnections = {}
	self.folder = Instance.new("Folder")
	self.folder.Name = "HACLassoChargePresentation"
	self.folder.Parent = workspace
	local function watchPlayer(player)
		local function watchCharacter(character)
			if self.characterConnections[player] then
				for _, connection in ipairs(self.characterConnections[player]) do connection:Disconnect() end
			end
			self.characterConnections[player] = {}
			self:_end(player, "cancel")
			local function sync()
				if player == localPlayer then return end -- Local prediction wins until release/denial.
				local name = character:GetAttribute(CHARGE_ATTRIBUTE)
				if type(name) == "string" and Config.Lassos[name] then
					local start = character:GetAttribute(START_ATTRIBUTE)
					self:_start(player, character, name, type(start) == "number" and start or workspace:GetServerTimeNow(), false)
				else
					self:_end(player, "cancel")
				end
			end
			table.insert(self.characterConnections[player], character:GetAttributeChangedSignal(CHARGE_ATTRIBUTE):Connect(sync))
			table.insert(self.characterConnections[player], character.AncestryChanged:Connect(function(_, parent)
				if not parent then self:_end(player, "cancel") end
			end))
			sync()
		end
		table.insert(self.connections, player.CharacterAdded:Connect(watchCharacter))
		if player.Character then watchCharacter(player.Character) end
	end
	for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end
	table.insert(self.connections, Players.PlayerAdded:Connect(watchPlayer))
	table.insert(self.connections, Players.PlayerRemoving:Connect(function(player)
		self:_end(player, "cancel")
		for _, connection in ipairs(self.characterConnections[player] or {}) do connection:Disconnect() end
		self.characterConnections[player] = nil
	end))
	table.insert(self.connections, RunService.RenderStepped:Connect(function(dt) self:_render(dt) end))
	table.insert(self.connections, RunService.PreSimulation:Connect(function() self:_pose() end))
	return self
end

function Presentation:_start(player, character, lassoName, started, localOwner)
	local old = self.effects[player]
	if old and old.character == character and old.lassoName == lassoName and not old.ending then return end
	if old then destroyEffect(old) end
	self.effects[player] = makeEffect(self.folder, character, lassoName, started, localOwner)
end

function Presentation:_end(player, kind)
	local effect = self.effects[player]
	if not effect or effect.ending then return end
	effect.ending = kind
	effect.endAt = os.clock()
	effect.trail.Enabled = false
	restoreTool(effect.hidden)
	effect.hidden = {}
end

function Presentation:StartLocal(lassoName, started)
	local character = self.localPlayer.Character
	if character then self:_start(self.localPlayer, character, lassoName, started, true) end
end

function Presentation:StopLocal(kind, aim)
	local effect = self.effects[self.localPlayer]
	if effect and kind == "throw" and aim and aim.origin and aim.direction then
		local target = aim.origin + aim.direction * 70
		local delta = target - effect.hand.Position
		if delta.Magnitude > 0.001 then effect.throwDirection = delta.Unit end
	end
	self:_end(self.localPlayer, kind or "cancel")
end

local function loopPoint(center, right, tiltedForward, normal, radius, angle, phase, wave)
	local wobble = 1 + wave * math.sin(angle * 3 - phase * 0.85)
	return center + (right * math.cos(angle) + tiltedForward * math.sin(angle)) * (radius * wobble)
		+ normal * (radius * wave * 0.5 * math.sin(angle * 2 - phase * 1.1))
end

function Presentation:_render(dt)
	local now = os.clock()
	for player, effect in pairs(self.effects) do
		if not effect.character.Parent or not effect.head.Parent or not effect.hand.Parent then
			destroyEffect(effect)
			self.effects[player] = nil
			continue
		end
		local style = effect.style
		local elapsed = effect.localOwner and now - effect.started or workspace:GetServerTimeNow() - effect.started
		local power = math.clamp(elapsed / Config.Lassos[effect.lassoName].ChargeSeconds, 0, 1)
		local entry = smooth((now - effect.lastTime) / style.EntrySeconds)
		local fade = 1
		if effect.ending then
			local duration = effect.ending == "throw" and style.ReleaseSeconds or style.CancelSeconds
			fade = 1 - smooth((now - effect.endAt) / duration)
			if fade <= 0 then
				destroyEffect(effect)
				self.effects[player] = nil
				continue
			end
		end
		local camera = workspace.CurrentCamera
		effect.hiddenByDistance = not effect.localOwner and camera ~= nil
			and (camera.CFrame.Position - effect.head.Position).Magnitude > style.RemoteViewDistance
		if effect.hiddenByDistance then
			if power >= 1 then effect.fullAccent = true end
			for _, segment in ipairs(effect.segments) do segment.Transparency = 1 end
			effect.knot.Transparency = 1
			effect.trail.Enabled = false
			if effect.line then effect.line.beam.Transparency = NumberSequence.new(1) end
			continue
		end
		local speed = style.StartTurnsPerSecond + (style.FullTurnsPerSecond - style.StartTurnsPerSecond) * smooth(power)
		effect.phase += 2 * math.pi * speed * math.min(dt, 0.08)
		local root = effect.character:FindFirstChild("HumanoidRootPart")
		if not root then
			destroyEffect(effect)
			self.effects[player] = nil
			continue
		end
		local up = root.CFrame.UpVector
		local right = root.CFrame.RightVector
		local forward = root.CFrame.LookVector
		local tilt = math.rad(style.TiltDegrees)
		local planeForward = forward * math.cos(tilt) + up * math.sin(tilt)
		local rotatingRight = right * math.cos(effect.phase) + planeForward * math.sin(effect.phase)
		local rotatingForward = -right * math.sin(effect.phase) + planeForward * math.cos(effect.phase)
		local normal = right:Cross(planeForward).Unit
		local radius = style.Radius * (0.22 + 0.78 * entry)
		local anchor = effect.hand.Position + forward * 0.18 + up * 0.08
		local center = anchor + rotatingRight * radius
		if effect.ending == "throw" then
			local t = smooth((now - effect.endAt) / style.ReleaseSeconds)
			center += (effect.throwDirection or forward) * (1.05 * t)
			radius *= 1 - 0.22 * t
		elseif effect.ending then
			radius *= fade
		end
		local function point(angle)
			return loopPoint(center, rotatingRight, rotatingForward, normal, radius, angle, effect.phase, style.WaveAmount)
		end
		local count = #effect.segments
		for i, segment in ipairs(effect.segments) do
			local a = point((i - 1) * math.pi * 2 / count)
			local b = point(i * math.pi * 2 / count)
			local delta = b - a
			segment.Size = Vector3.new(0.12, delta.Magnitude * 1.12, 0.12)
			segment.CFrame = CFrame.lookAt((a + b) * 0.5, b) * CFrame.Angles(-math.pi / 2, 0, 0)
			segment.Transparency = 1 - entry * fade
			segment.Color = style.RopeColor:Lerp(style.BrightColor, 0.12 + 0.16 * (1 + math.sin(i * 0.7 - effect.phase)) * 0.5)
		end
		effect.knot.Position = point(math.pi)
		effect.knot.Size = Vector3.new(0.28, 0.28, 0.28) * math.max(entry * fade, 0.05)
		effect.knot.Transparency = 1 - entry * fade
		effect.swish.Position = point(0)
		effect.trail.Enabled = entry > 0.45 and not effect.ending
		if effect.line then effect.line.beam.Transparency = NumberSequence.new(1 - entry * fade) end
		if power >= 1 and not effect.fullAccent and not effect.ending then
			effect.fullAccent = true
			Visuals.Burst(self.folder, effect.swish.Position, style.BrightColor, 4)
		end
	end
end

function Presentation:_pose()
	for _, effect in pairs(self.effects) do
		local humanoid = effect.character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 and not effect.hiddenByDistance then
			local weight = smooth((os.clock() - effect.lastTime) / effect.style.EntrySeconds)
			local release = 0
			if effect.ending then
				local duration = effect.ending == "throw" and effect.style.ReleaseSeconds or effect.style.CancelSeconds
				local t = math.clamp((os.clock() - effect.endAt) / duration, 0, 1)
				if effect.ending == "throw" then
					release = smooth(t / 0.7)
					weight *= 1 - smooth((t - 0.68) / 0.32)
				else
					weight *= 1 - smooth(t)
				end
			end
			local swing = math.sin(effect.phase) * weight
			local aimYaw = 0
			if effect.throwDirection then
				local root = effect.character:FindFirstChild("HumanoidRootPart")
				if root then aimYaw = math.clamp(root.CFrame:VectorToObjectSpace(effect.throwDirection).X, -0.7, 0.7) end
			end
			local poses = {
				shoulder = CFrame.Angles(math.rad(-52 - release * 32) * weight + swing * 0.1,
					aimYaw * release * 0.3, math.rad(18) * weight + math.cos(effect.phase) * 0.12 * weight),
				elbow = CFrame.Angles(math.rad(-48 + release * 42) * weight + swing * 0.14, 0, 0),
				wrist = CFrame.Angles(swing * 0.35, 0, math.cos(effect.phase) * 0.32 * weight),
				leftShoulder = CFrame.Angles(math.rad(-14) * weight, 0, math.rad(-10) * weight),
				waist = CFrame.Angles(math.rad(-3 - release * 6) * weight,
					math.sin(effect.phase) * 0.04 * weight + aimYaw * release * 0.2, 0),
			}
			for name, joint in pairs(effect.joints) do
				if joint.Parent then
					pcall(function() joint.Transform = joint.Transform * poses[name] end)
				end
			end
		end
	end
end

function Presentation:Destroy()
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	for _, connections in pairs(self.characterConnections) do
		for _, connection in ipairs(connections) do connection:Disconnect() end
	end
	for player, effect in pairs(self.effects) do
		destroyEffect(effect)
		self.effects[player] = nil
	end
	self.folder:Destroy()
end
return Presentation
