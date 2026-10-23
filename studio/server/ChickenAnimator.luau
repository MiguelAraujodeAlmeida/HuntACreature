-- Articulated performance for Chicken_Base_v01. All poses derive from import rest transforms.
-- The gameplay root and capture volume stay still relative to the authoritative path.
local Animator = {}
Animator.__index = Animator
local FootPuff = require(script.Parent.CreatureFootPuff)

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
		phase = 0, moving = 0, panic = 0, tired = 0, captive = 0, reaction = 10, gaze = 0,
		wingRoll = { L = 0, R = 0 },
		gesture = 0, gestureStart = -10, attentionCooldown = 0 }, Animator)
	self.scale = model:GetAttribute("CreatureScale") or 1
	self.seed = self.random:NextNumber(0, 100)
	self.nextGesture = self.random:NextNumber(1.8, 4)
	self.nextBlink = self.random:NextNumber(2.4, 5.3)
	local origin = model:GetPivot()
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Root" and part.Name ~= "Corpo" then
			table.insert(self.parts, {part = part, rest = origin:ToObjectSpace(part.CFrame), group = group(part.Name),
				size = part.Size, transparency = part.Transparency})
		end
	end
	self.dustL = FootPuff.new(model.PrimaryPart, "ChickenFootPuffL", Vector3.new(-0.38, -1.31, -0.1), self.scale)
	self.dustR = FootPuff.new(model.PrimaryPart, "ChickenFootPuffR", Vector3.new(0.38, -1.31, -0.1), self.scale)
	return self
end

function Animator:Step(dt, rootPose, state, speed, attention, capturePhase)
	dt = math.clamp(dt, 0, 0.1)
	self.time += dt
	local panic, tired, captive = state == "Panicking", state == "Tired", state == "Capturing"
	if self.state ~= state then
		if panic or captive then self.reaction = 0 end
		self.state = state
	end
	self.reaction += dt
	local blend = 1 - math.exp(-dt * 6)
	self.moving += ((speed > 0.05 and 1 or 0) - self.moving) * blend
	self.panic += ((panic and 1 or 0) - self.panic) * blend
	self.tired += ((tired and 1 or 0) - self.tired) * blend
	self.captive += ((captive and 1 or 0) - self.captive) * blend
	-- Travel drives footfall; a sprint cannot spin the feet independently of the path.
	self.phase += dt * math.min(18, speed / (1.65 * self.scale) * math.pi * 2)
	if self.time >= self.nextGesture and self.moving < 0.18 and not panic and not tired and not captive then
		self.gesture = self.random:NextInteger(1, 3) -- peck, puzzled flap, or clumsy hop
		self.gestureStart = self.time
		self.nextGesture = self.time + self.random:NextNumber(3.6, 7)
	end
	if state == "AtBase" and attention and self.time >= self.attentionCooldown
		and self.moving < 0.18 then
		self.gesture = 2
		self.gestureStart = self.time
		self.attentionCooldown = self.time + 9
	end
	local u = (self.time - self.gestureStart) / (self.gesture == 1 and 1.25 or 1.6)
	local g = u >= 0 and u < 1 and math.sin(math.pi * u) ^ 2 or 0
	g *= (1 - self.moving) * (1 - self.panic) * (1 - self.captive)
	local peck = self.gesture == 1 and g * math.max(0, math.sin(u * math.pi * 4)) or 0
	local baffled = self.gesture == 2 and g or 0
	local stumble = self.gesture == 3 and g or 0
	local t = self.time + self.seed
	local look = 0
	if state == "AtBase" and attention and self.moving < 0.25 then
		local delta = rootPose:VectorToObjectSpace(attention - rootPose.Position)
		look = math.clamp(math.atan2(-delta.X, -delta.Z), -0.45, 0.45)
	end
	self.gaze += (look - self.gaze) * (1 - math.exp(-dt * 4))
	local stride = math.sin(self.phase)
	if speed > 0.7 and self.moving > 0.55 and self.lastStride and (stride >= 0) ~= (self.lastStride >= 0) then
		local puff = stride >= 0 and self.dustR or self.dustL
		puff:Emit(panic and 2 or 1)
	end
	self.lastStride = stride
	local s = self.scale
	local bob = math.abs(stride) * self.moving * (0.055 + self.panic * 0.04)
	local breath = math.sin(t * 2.1) * 0.015
	local tug = math.sin(t * (capturePhase == "resist" and 17 or 10)) * self.captive
	local startle = self.reaction < 0.48 and math.sin(self.reaction / 0.48 * math.pi) or 0
	local hop = stumble * math.max(0, math.sin(u * math.pi * 2)) * 0.16
	local body = CFrame.new(0, (bob + breath + hop + startle * 0.12) * s, 0)
		* hinge(PIVOT.Body * s, CFrame.Angles(-0.07 * self.moving + 0.1 * self.tired + 0.11 * tug,
			0, stride * 0.035 * self.moving + 0.06 * tug + stumble * 0.12 * math.sin(u * math.pi * 2)))
	local head = body * hinge(PIVOT.Head * s, CFrame.Angles(
			-0.72 * peck + 0.14 * self.panic + 0.19 * self.tired + 0.10 * tug - 0.12 * startle
				- 0.035 * stride * self.moving,
			self.gaze + 0.26 * baffled * math.sin(u * math.pi * 2) + 0.05 * math.sin(t * 1.4),
			0.28 * baffled - 0.09 * tug))
	local transforms = {Body = body, Head = head}
	for _, side in ipairs({"L", "R"}) do
		local sign = side == "L" and 1 or -1
		local step = math.sin(self.phase + (side == "R" and math.pi or 0)) * self.moving
		transforms["Foot" .. side] = CFrame.new(0, (math.max(0, step) * 0.14 + hop + startle * 0.12) * s,
			-step * 0.13 * s)
		local wingTarget = 0.08 * math.sin(t * 1.8 + sign) + 0.5 * baffled * math.sin(u * 13)
			+ stumble * 0.42 * math.sin(u * 13) + startle * 0.25
			+ self.panic * (0.26 + 0.1 * math.sin(t * 11)) + 0.32 * tug
		self.wingRoll[side] += (wingTarget - self.wingRoll[side]) * (1 - math.exp(-dt * 9))
		transforms["Wing" .. side] = body * hinge(PIVOT["Wing" .. side] * s,
			CFrame.Angles(-0.16 * step + 0.15 * baffled, 0, sign * self.wingRoll[side]))
	end
	transforms.Tail = body * hinge(PIVOT.Tail * s,
		CFrame.Angles(0.1 * self.tired - 0.08 * self.panic,
			0.11 * math.sin(t * (2.4 + self.moving * 1.8) - 0.4) + 0.16 * baffled
				+ 0.12 * stumble + 0.1 * tug, 0))
	local blinkTime = self.time - self.nextBlink
	local blink = blinkTime >= 0 and blinkTime < 0.14
	if blinkTime >= 0.14 then self.nextBlink = self.time + self.random:NextNumber(2.4, 5.3) end
	self.model.PrimaryPart.CFrame = rootPose
	local collider = self.model:FindFirstChild("Corpo")
	if collider then collider.CFrame = rootPose end
	for _, entry in ipairs(self.parts) do
		if entry.part.Parent then
			entry.part.CFrame = rootPose * (transforms[entry.group] or CFrame.new()) * entry.rest
			if entry.part.Name == "Eye_L" or entry.part.Name == "Eye_R" then
				entry.part.Size = Vector3.new(entry.size.X,
					entry.size.Y * (blink and 0.15 or (1 + self.panic * 0.1 - self.tired * 0.15)), entry.size.Z)
			elseif entry.part.Name == "Glint_L" or entry.part.Name == "Glint_R" then
				entry.part.Transparency = blink and 1 or entry.transparency
			end
		end
	end
end

return Animator
