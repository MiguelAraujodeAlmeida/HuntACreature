-- Rigid-piece performance for the v01 template and its named fallback.
-- Rest transforms are captured once; every pose is absolute, never accumulated.
local C = require(game.ReplicatedStorage.HACShared.LumitoMotionConfig)
local Animator = {}
Animator.__index = Animator
local function hinge(point, rotation)
	return CFrame.new(point) * rotation * CFrame.new(-point)
end
local function group(part)
	local n = part.Name
	local foot = part:GetAttribute("FootSide")
	if foot then return "Foot" .. foot end
	if n:match("^Ear_L") then return "EarL" end
	if n:match("^Ear_R") then return "EarR" end
	if n:match("^Tail") then return "Tail" end
	if n == "Arm_L" then return "ArmL" end
	if n == "Arm_R" then return "ArmR" end
	if n == "Torso" or n == "Belly" then return "Body" end
	return "Head"
end

function Animator.new(model)
	local self = setmetatable({ model = model, parts = {}, time = 0, phase = 0, motion = 0,
		panic = 0, tired = 0, struggle = 0, reaction = 10, gaze = 0,
		gestureTime = 10, random = Random.new() }, Animator)
	self.scale = model:GetAttribute("CreatureScale") or 1
	self.seed = self.random:NextNumber(0, math.pi * 2)
	self.nextGesture = self.random:NextNumber(C.IdleGestureMin, C.IdleGestureMax)
	self.nextBlink = self.random:NextNumber(C.BlinkMin, C.BlinkMax)
	self.nextGreeting = 0
	local origin = model:GetPivot()
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Root" and part.Name ~= "Corpo" then
			table.insert(self.parts, { part = part, rest = origin:ToObjectSpace(part.CFrame),
				size = part.Size, transparency = part.Transparency, group = group(part) })
		end
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "LumitoFootDust"
	attachment.Position = Vector3.new(0, -1.59 * self.scale, 0)
	attachment.Parent = model.PrimaryPart
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "StepPuff"
	dust.Texture = C.PuffTexture
	dust.Rate = 0
	dust.Lifetime = NumberRange.new(0.28, 0.34)
	dust.Speed = NumberRange.new(0.25, 0.55)
	dust.SpreadAngle = Vector2.new(18, 12)
	dust.Rotation = NumberRange.new(-8, 8)
	dust.RotSpeed = NumberRange.new(-12, 12)
	dust.Color = ColorSequence.new(Color3.new(1, 1, 1))
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(0.78, 0.18), NumberSequenceKeypoint.new(1, 1) })
	local size = math.min(self.scale, 2)
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.38 * size), NumberSequenceKeypoint.new(1, 0.74 * size) })
	dust.LightEmission = 0.15
	dust.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2
	dust.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	dust.FlipbookFramerate = NumberRange.new(12)
	dust.Parent = attachment
	self.dust = dust -- lifetime owned by model; no extra connection or free-standing effect.
	local trailLeft = Instance.new("Attachment")
	trailLeft.Name = "LumitoRunTrailLeft"
	trailLeft.Position = Vector3.new(-0.42, -1.25, 0.40) * self.scale
	trailLeft.Parent = model.PrimaryPart
	local trailRight = Instance.new("Attachment")
	trailRight.Name = "LumitoRunTrailRight"
	trailRight.Position = Vector3.new(0.42, -1.25, 0.40) * self.scale
	trailRight.Parent = model.PrimaryPart
	local trail = Instance.new("Trail")
	trail.Name = "RunSwoosh"
	trail.Attachment0 = trailLeft
	trail.Attachment1 = trailRight
	trail.Enabled = false
	trail.FaceCamera = true
	trail.Lifetime = 0.13
	trail.MinLength = 0.08 * self.scale
	trail.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(217, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(41, 221, 236)) })
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.65, 0.72), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 0) })
	trail.Parent = model.PrimaryPart
	self.trail = trail
	return self
end

function Animator:Step(dt, rootPose, state, speed, attention, phase)
	dt = math.clamp(dt, 0, 0.1)
	self.time += dt
	self.reaction += dt
	self.gestureTime += dt
	local moving = speed > 0.05
	local panic, tired, struggle = state == "Panicking", state == "Tired", state == "Capturing"
	if state == "AtBase" and attention and not self.hadAttention and not moving and self.time >= self.nextGreeting then
		self.gestureTime, self.gesture = 0, 2
		self.nextGreeting = self.time + 8
		self.nextGesture = self.time + C.GestureDuration + self.random:NextNumber(C.IdleGestureMin, C.IdleGestureMax)
	end
	self.hadAttention = attention ~= nil
	if self.state ~= state then
		if panic or struggle then self.reaction = 0 end
		self.state = state
	end
	local blend = 1 - math.exp(-dt * C.BlendRate)
	self.motion += ((moving and 1 or 0) - self.motion) * blend
	self.panic += ((panic and 1 or 0) - self.panic) * blend
	self.tired += ((tired and 1 or 0) - self.tired) * blend
	self.struggle += ((struggle and 1 or 0) - self.struggle) * blend
	-- Stride follows travel speed and size; slowed/large creatures do not treadmill.
	self.phase += dt * math.min(20, speed / (C.StrideLength * self.scale) * math.pi * 2)
	if not moving and not panic and not tired and not struggle and self.time >= self.nextGesture then
		self.gestureTime = 0
		self.gesture = self.random:NextInteger(1, 3)
		self.nextGesture = self.time + self.random:NextNumber(C.IdleGestureMin, C.IdleGestureMax)
	end
	local u = self.gestureTime / C.GestureDuration
	local gesture = u < 1 and math.sin(u * math.pi)^2 or 0
	gesture *= (1 - self.motion) * (1 - self.panic) * (1 - self.tired) * (1 - self.struggle)
	local yaw = 0
	if attention and not struggle then
		local delta = rootPose:VectorToObjectSpace(attention - rootPose.Position)
		yaw = math.clamp(math.atan2(-delta.X, -delta.Z), -0.5, 0.5)
	end
	self.gaze += (yaw - self.gaze) * (1 - math.exp(-dt * 5))
	local t, s, p = self.time + self.seed, self.scale, self.phase
	local footWave = math.sin(p)
	if moving and self.lastFootWave and (footWave >= 0) ~= (self.lastFootWave >= 0) then
		self.dust:Emit(panic and 2 or 1)
	end
	self.lastFootWave = footWave
	self.trail.Enabled = moving and (panic or speed >= C.RunTrailSpeed * self.scale)
	local bounce = math.abs(footWave) * (0.055 + self.panic * 0.07) * self.motion
	local startle = self.reaction < 0.45 and math.sin(self.reaction / 0.45 * math.pi) or 0
	local hop = self.gesture == 3 and gesture * 0.14 or 0
	local breath = (math.sin(t * (2.5 + self.tired * 2)) + 1) * (0.012 + self.tired * 0.02)
	local tug = math.sin(t * (phase == "resist" and 15 or 8)) * self.struggle
	local body = CFrame.new(0, (bounce + breath + startle * 0.20 + hop) * s, 0)
		* CFrame.Angles(-0.09 * self.motion - 0.10 * self.panic + 0.035 * tug, 0,
			footWave * 0.045 * self.motion + tug * 0.035)
	local head = body * hinge(C.Pivots.Head * s, CFrame.Angles(
		0.045 * math.sin(t * 2.2) + self.tired * 0.12 - startle * 0.16,
		self.gaze + (self.gesture == 1 and gesture * math.sin(u * math.pi * 2) * 0.4 or 0) + tug * 0.07,
		-0.045 * footWave * self.motion + (self.gesture == 2 and gesture * 0.13 or 0)))
	local transforms = { Body = body, Head = head }
	for _, side in ipairs({ "L", "R" }) do
		local sign = side == "L" and 1 or -1
		local step = math.sin(p + (side == "R" and math.pi or 0)) * self.motion
		-- Feet remain planted during idle body breathing; lift only the swing foot.
		transforms["Foot" .. side] = CFrame.new(0, (math.max(0, step) * C.StepLift + startle * 0.20 + hop) * s,
			step * C.StepReach * s)
		local flick = math.sin(t * 7 + sign) * gesture * 0.13
		transforms["Ear" .. side] = head * hinge(C.Pivots["Ear" .. side] * s,
			CFrame.Angles(math.sin(p - 0.6 + sign * 0.3) * self.motion * 0.11 + self.panic * 0.22 + self.tired * 0.12,
				0, sign * (flick + math.sin(t * 2.1 + sign) * 0.025 - startle * 0.18)))
		local wave = side == "L" and self.gesture == 2 and gesture or 0
		transforms["Arm" .. side] = body * hinge(C.Pivots["Arm" .. side] * s,
			CFrame.Angles(-step * 0.35 - self.struggle * 0.35, 0, sign * (wave * (0.6 + 0.15 * math.sin(t * 12)) + startle * 0.25)))
	end
	transforms.Tail = body * hinge(C.Pivots.Tail * s, CFrame.Angles(self.tired * 0.16 - self.panic * 0.16,
		math.sin(t * (3 + self.motion * 4) - 0.7) * (0.12 + gesture * 0.2 + self.motion * 0.1), 0))
	local blinkTime = self.time - self.nextBlink
	local blink = blinkTime >= 0 and blinkTime < C.BlinkDuration
	if blinkTime >= C.BlinkDuration then self.nextBlink = self.time + self.random:NextNumber(C.BlinkMin, C.BlinkMax) end
	-- Keep Root/Corpo at the authoritative position; presentation never changes the capture ellipsoid.
	self.model.PrimaryPart.CFrame = rootPose
	local collider = self.model:FindFirstChild("Corpo")
	if collider then collider.CFrame = rootPose end
	for _, entry in ipairs(self.parts) do
		local part = entry.part
		if part.Parent then
			part.CFrame = rootPose * transforms[entry.group] * entry.rest
			if part.Name == "Eye_L" or part.Name == "Eye_R" then
				part.Size = Vector3.new(entry.size.X, entry.size.Y * (blink and 0.18 or 1), entry.size.Z)
			elseif part.Name == "EyeGlint_L" then
				part.Transparency = blink and 1 or entry.transparency
			end
		end
	end
end

return Animator
