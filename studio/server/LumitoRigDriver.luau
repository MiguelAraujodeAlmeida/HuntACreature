-- Server owns navigation, capture volume, state and contact effects; clients pose the rig.
local CollectionService = game:GetService("CollectionService")
local Motion = require(game.ReplicatedStorage.HACShared.LumitoMotionConfig)
local FootPuff = require(script.Parent.CreatureFootPuff)
local RigBuilder = require(script.Parent.LumitoRigBuilder)
local Driver = {}
Driver.__index = Driver

function Driver.new(model)
	RigBuilder.Build(model)
	local scale = model:GetAttribute("CreatureScale") or 1
	local root = model.Root
	local self = setmetatable({model = model, scale = scale, root = root, phase = 0,
		lastStep = 0, time = 0, gestureSerial = 0, random = Random.new()}, Driver)
	self.dust = FootPuff.new(root, "LumitoFootDust", Vector3.new(0, -1.59, 0), scale)
	local left = Instance.new("Attachment")
	left.Name = "LumitoRunTrailLeft"
	left.Position = Vector3.new(-0.42, -1.25, 0.40) * scale
	left.Parent = root
	local right = Instance.new("Attachment")
	right.Name = "LumitoRunTrailRight"
	right.Position = Vector3.new(0.42, -1.25, 0.40) * scale
	right.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = "RunSwoosh"
	trail.Attachment0, trail.Attachment1 = left, right
	trail.Enabled, trail.FaceCamera = false, true
	trail.Lifetime, trail.MinLength = 0.13, 0.08 * scale
	trail.Color = ColorSequence.new(Color3.fromRGB(217, 255, 255), Color3.fromRGB(41, 221, 236))
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.65, 0.72), NumberSequenceKeypoint.new(1, 1)})
	trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 0)})
	trail.Parent = root
	self.trail = trail
	self.nextGesture = self.random:NextNumber(Motion.IdleGestureMin, Motion.IdleGestureMax)
	model:SetAttribute("RigState", "Wandering")
	model:SetAttribute("RigSpeed", 0)
	model:SetAttribute("RigGestureSerial", 0)
	CollectionService:AddTag(model, "HACLumitoRig")
	return self
end

function Driver:Step(dt, rootPose, state, speed, attention, phase)
	if not self.model.Parent then return end
	dt = math.clamp(dt, 0, 0.1)
	speed = math.max(0, speed or 0)
	self.time += dt
	self.root.CFrame = rootPose
	local hitbox = self.model:FindFirstChild("Corpo")
	if hitbox then hitbox.CFrame = rootPose end
	if self.model:GetAttribute("RigState") ~= state then self.model:SetAttribute("RigState", state) end
	local roundedSpeed = math.floor(speed * 5 + 0.5) / 5
	if self.model:GetAttribute("RigSpeed") ~= roundedSpeed then self.model:SetAttribute("RigSpeed", roundedSpeed) end
	if self.model:GetAttribute("RigAttention") ~= attention then self.model:SetAttribute("RigAttention", attention) end
	if self.model:GetAttribute("RigCapturePhase") ~= phase then self.model:SetAttribute("RigCapturePhase", phase) end
	local moving = speed > 0.05
	if moving then
		self.phase += dt * speed / math.max(Motion.StrideLength * self.scale, 0.1)
		local step = math.floor(self.phase * 2)
		if step ~= self.lastStep then
			self.dust:Emit(state == "Panicking" and 2 or 1)
			self.lastStep = step
		end
	end
	self.trail.Enabled = state == "Panicking" and moving
	if not moving and state ~= "Panicking" and state ~= "Tired" and state ~= "Capturing" and self.time >= self.nextGesture then
		local names = {"Curious", "Greeting", "Playful"}
		local choice = names[self.random:NextInteger(1, #names)]
		self.gestureSerial += 1
		self.model:SetAttribute("RigGesture", choice)
		self.model:SetAttribute("RigGestureSerial", self.gestureSerial)
		self.nextGesture = self.time + self.random:NextNumber(Motion.IdleGestureMin, Motion.IdleGestureMax)
	end
end

return Driver
