-- Rigid-piece performance for the v01 template and its named fallback.
-- Rest transforms are captured once; every pose is absolute, never accumulated.
local C = require(game.ReplicatedStorage.HACShared.LumitoMotionConfig)
local FootPuff = require(script.Parent.CreatureFootPuff)
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
	if n == "Torso" or n == "Belly" or n:match("^Crest_Back") or n == "Stud_Crest_2" then return "Body" end
	if n == "Head" or n == "Snout" or n == "Mouth" or n == "Fang"
		or n:match("^Eye") or n == "Crest_Top" or n == "Stud_Crest_0" or n == "Stud_Crest_1" then return "Head" end
	return nil -- Unknown art stays at rest instead of following the head.
end

function Animator.new(model)
	local self = setmetatable({ model = model, parts = {}, time = 0, phase = 0, motion = 0,
		panic = 0, tired = 0, struggle = 0, reaction = 10, gaze = 0,
		armPitch = { L = 0, R = 0 }, armRoll = { L = 0, R = 0 },
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
	self.dust = FootPuff.new(model.PrimaryPart, "LumitoFootDust", Vector3.new(0, -1.59, 0), self.scale)
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
	local motionTarget = math.clamp(speed / C.WalkReferenceSpeed, 0, 1)
	self.motion += (motionTarget - self.motion) * blend
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
	local gesture = u >= 0 and u < 1 and math.sin(u * math.pi)^2 or 0
	gesture *= (1 - self.motion) * (1 - self.panic) * (1 - self.tired) * (1 - self.struggle)
	local curious = self.gesture == 1 and gesture or 0
	local greeting = self.gesture == 2 and gesture or 0
	local playful = self.gesture == 3 and gesture or 0
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
	local hop = playful * math.max(0, math.sin(u * math.pi * 2)) * 0.14
	local breath = (math.sin(t * (2.5 + self.tired * 2)) + 1) * (0.012 + self.tired * 0.02)
	local tug = math.sin(t * (phase == "resist" and 15 or 8)) * self.struggle
	local body = CFrame.new(0, (bounce + breath + startle * 0.20 + hop) * s, 0)
		* CFrame.Angles(-0.07 * self.motion - 0.10 * self.panic + 0.06 * self.tired + 0.035 * tug,
			0.025 * math.sin(t * 1.25) * (1 - self.motion),
			footWave * 0.045 * self.motion + tug * 0.035 + playful * math.sin(u * math.pi * 2) * 0.07)
	local head = body * hinge(C.Pivots.Head * s, CFrame.Angles(
		0.055 * math.sin(t * 1.7) + self.tired * 0.13 - startle * 0.16 - curious * 0.09,
		self.gaze + curious * math.sin(u * math.pi * 2) * 0.38 + tug * 0.07,
		-0.045 * footWave * self.motion + greeting * 0.16 + curious * 0.13))
	local transforms = { Body = body, Head = head }
	for _, side in ipairs({ "L", "R" }) do
		local sign = side == "L" and 1 or -1
		local step = math.sin(p + (side == "R" and math.pi or 0)) * self.motion
		-- Feet remain planted during idle body breathing; lift only the swing foot.
		transforms["Foot" .. side] = CFrame.new(0, (math.max(0, step) * C.StepLift + startle * 0.20 + hop) * s,
			step * C.StepReach * s)
		local flick = math.sin(t * 6 + sign) * gesture * 0.11
		transforms["Ear" .. side] = head * hinge(C.Pivots["Ear" .. side] * s,
			CFrame.Angles(math.sin(p - 0.55 + sign * 0.35) * self.motion * 0.12 + self.panic * 0.22
				+ self.tired * 0.11 + curious * 0.13,
				0, sign * (flick + math.sin(t * 1.9 + sign) * 0.035 - startle * 0.18)))
		local wave = side == "L" and greeting * (0.78 + 0.14 * math.sin(u * math.pi * 6)) or 0
		local armTargetPitch = -step * (0.44 + self.panic * 0.1) + math.sin(t * 1.7 + sign) * 0.07 * (1 - self.motion)
			+ curious * (side == "R" and 0.26 or 0.1) + wave * 0.42
			+ playful * 0.23 + startle * 0.2 - self.struggle * (0.24 + sign * 0.12)
		local armTargetRoll = sign * (0.12 + self.panic * 0.25 + self.tired * 0.08 + wave
			+ playful * 0.47 + curious * (side == "R" and 0.18 or 0.06) + startle * 0.28)
		local armBlend = 1 - math.exp(-dt * 8)
		self.armPitch[side] += (armTargetPitch - self.armPitch[side]) * armBlend
		self.armRoll[side] += (armTargetRoll - self.armRoll[side]) * armBlend
		transforms["Arm" .. side] = body * hinge(C.Pivots["Arm" .. side] * s,
			CFrame.Angles(self.armPitch[side], 0, self.armRoll[side]))
	end
	transforms.Tail = body * hinge(C.Pivots.Tail * s, CFrame.Angles(self.tired * 0.16 - self.panic * 0.16,
		math.sin(t * (2.2 + self.motion * 3) - 0.8) * (0.12 + greeting * 0.19 + self.motion * 0.12)
			+ playful * 0.15, 0))
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
			part.CFrame = rootPose * (transforms[entry.group] or CFrame.new()) * entry.rest
			if part.Name == "Eye_L" or part.Name == "Eye_R" then
				local expression = part.Name == "Eye_R" and (1 + self.panic * 0.35 - self.tired * 0.12)
					or (1 + self.panic * 0.08 - self.tired * 0.12)
				part.Size = Vector3.new(entry.size.X, entry.size.Y * (blink and 0.18 or expression), entry.size.Z)
			elseif part.Name == "EyeGlint_L" then
				part.Transparency = blink and 1 or entry.transparency
			end
		end
	end
end

return Animator
