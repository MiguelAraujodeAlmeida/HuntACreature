-- Articulated performance for Chicken_Base_v01. All poses derive from import rest transforms.
-- The gameplay root and capture volume stay still relative to the authoritative path.
local Animator = {}
Animator.__index = Animator

local PIVOT = {
	Head = Vector3.new(0, -0.15, -0.08),
	Body = Vector3.new(0, -1.07, 0),
	WingL = Vector3.new(-0.616, -0.43, 0.02),
	WingR = Vector3.new(0.616, -0.43, 0.02),
	Tail = Vector3.new(0, -0.66, 0.43),
}
local function hinge(at, rotation)
	return CFrame.new(at) * rotation * CFrame.new(-at)
end
local function group(name)
	if name == "Body" or name == "Breast" then return "Body" end
	if name == "Head" or name == "Beak" or name == "Wattle"
		or name:match("^Comb_") or name:match("^Eye_") or name:match("^Glint_") then return "Head" end
	if name:match("^FootStud_L") or name:match("^Sole_L") or name:match("^Ankle_L") or name == "Foot_L" then return "FootL" end
	if name:match("^FootStud_R") or name:match("^Sole_R") or name:match("^Ankle_R") or name == "Foot_R" then return "FootR" end
	if name == "Wing_L" then return "WingL" end
	if name == "Wing_R" then return "WingR" end
	if name:match("^Tail_Feather_") then return "Tail" end
	return nil -- Unknown imported pieces remain at rest, never default to the head.
end

function Animator.new(model)
	local self = setmetatable({ model = model, parts = {}, random = Random.new(), time = 0,
		phase = 0, moving = 0, panic = 0, tired = 0, captive = 0,
		gesture = 0, gestureStart = -10, attentionCooldown = 0 }, Animator)
	self.scale = model:GetAttribute("CreatureScale") or 1
	self.seed = self.random:NextNumber(0, 100)
	self.nextGesture = self.random:NextNumber(1.8, 4)
	local origin = model:GetPivot()
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Root" and part.Name ~= "Corpo" then
			table.insert(self.parts, {part = part, rest = origin:ToObjectSpace(part.CFrame), group = group(part.Name)})
		end
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "ChickenFootPuff"
	attachment.Position = Vector3.new(0, -1.31 * self.scale, 0)
	attachment.Parent = model.PrimaryPart
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "ChickenStepDust"
	dust.Rate = 0
	dust.Lifetime = NumberRange.new(0.2, 0.3)
	dust.Speed = NumberRange.new(0.2, 0.5)
	dust.Size = NumberSequence.new(0.25 * math.min(self.scale, 2), 0)
	dust.Transparency = NumberSequence.new(0.35, 1)
	dust.Color = ColorSequence.new(Color3.fromRGB(247, 229, 186))
	dust.Parent = attachment
	self.dust = dust
	return self
end

function Animator:Step(dt, rootPose, state, speed, attention, capturePhase)
	dt = math.clamp(dt, 0, 0.1)
	self.time += dt
	local panic, tired, captive = state == "Panicking", state == "Tired", state == "Capturing"
	local blend = 1 - math.exp(-dt * 9)
	self.moving += ((speed > 0.05 and 1 or 0) - self.moving) * blend
	self.panic += ((panic and 1 or 0) - self.panic) * blend
	self.tired += ((tired and 1 or 0) - self.tired) * blend
	self.captive += ((captive and 1 or 0) - self.captive) * blend
	local pace = speed / math.max(0.7, self.scale) * 3.1
	self.phase += dt * math.min(27, pace)
	if self.time >= self.nextGesture and self.moving < 0.18 and not captive then
		self.gesture = self.random:NextInteger(1, 2) -- peck or baffled head-tilt and flap
		self.gestureStart = self.time
		self.nextGesture = self.time + self.random:NextNumber(3.6, 7)
	end
	if state == "AtBase" and attention and self.time >= self.attentionCooldown
		and self.moving < 0.18 then
		self.gesture = 2
		self.gestureStart = self.time
		self.attentionCooldown = self.time + 9
	end
	local u = (self.time - self.gestureStart) / (self.gesture == 1 and 1.1 or 1.4)
	local g = u >= 0 and u < 1 and math.sin(math.pi * u) ^ 2 or 0
	g *= (1 - self.moving) * (1 - self.panic) * (1 - self.captive)
	local peck = self.gesture == 1 and g * math.max(0, math.sin(u * math.pi * 6)) or 0
	local baffled = self.gesture == 2 and g or 0
	local t = self.time + self.seed
	local stride = math.sin(self.phase)
	if self.moving > 0.55 and self.lastStride and (stride >= 0) ~= (self.lastStride >= 0) then
		self.dust:Emit(panic and 2 or 1)
	end
	self.lastStride = stride
	local s = self.scale
	local bob = math.abs(stride) * self.moving * (0.055 + self.panic * 0.04)
	local breath = math.sin(t * 2.1) * 0.015
	local tug = math.sin(t * (capturePhase == "resist" and 17 or 10)) * self.captive
	local body = CFrame.new(0, (bob + breath) * s, 0)
		* hinge(PIVOT.Body * s, CFrame.Angles(-0.07 * self.moving + 0.1 * self.tired + 0.11 * tug,
			0, stride * 0.035 * self.moving + 0.06 * tug))
	local head = body * hinge(PIVOT.Head * s, CFrame.Angles(
			-0.72 * peck + 0.14 * self.panic + 0.19 * self.tired + 0.10 * tug,
			0.26 * baffled * math.sin(u * math.pi * 2) + 0.05 * math.sin(t * 1.4),
			0.28 * baffled - 0.09 * tug))
	local transforms = {Body = body, Head = head}
	for _, side in ipairs({"L", "R"}) do
		local sign = side == "L" and 1 or -1
		local step = math.sin(self.phase + (side == "R" and math.pi or 0)) * self.moving
		transforms["Foot" .. side] = CFrame.new(0, math.max(0, step) * 0.17 * s,
			-step * 0.16 * s)
		transforms["Wing" .. side] = body * hinge(PIVOT["Wing" .. side] * s,
			CFrame.Angles(-0.08 * step, 0,
				sign * (0.1 * math.sin(t * 2) + 0.48 * baffled * math.sin(u * 18)
					+ self.panic * (0.26 + 0.17 * math.sin(t * 22)) + 0.32 * tug)))
	end
	transforms.Tail = body * hinge(PIVOT.Tail * s,
		CFrame.Angles(0.1 * self.tired - 0.08 * self.panic,
			0.08 * math.sin(t * 3 - 0.4) + 0.14 * baffled + 0.1 * tug, 0))
	self.model.PrimaryPart.CFrame = rootPose
	local collider = self.model:FindFirstChild("Corpo")
	if collider then collider.CFrame = rootPose end
	for _, entry in ipairs(self.parts) do
		if entry.part.Parent then
			entry.part.CFrame = rootPose * (transforms[entry.group] or CFrame.new()) * entry.rest
		end
	end
end

return Animator
