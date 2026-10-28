-- Server owns Chicken navigation, capture volume, state and real footfall puffs.
local CollectionService = game:GetService("CollectionService")
local FootPuff = require(script.Parent.CreatureFootPuff)
local RigBuilder = require(script.Parent.ChickenRigBuilder)
local Driver = {}
Driver.__index = Driver

function Driver.new(model)
	RigBuilder.Build(model)
	local scale = model:GetAttribute("CreatureScale") or 1
	local root = model.Root
	local self = setmetatable({model=model, root=root, scale=scale, time=0, phase=0,
		lastStep=0, gestureSerial=0, random=Random.new()}, Driver)
	self.dustL = FootPuff.new(root, "ChickenFootDustL", Vector3.new(0.455, -1.30, -0.12), scale)
	self.dustR = FootPuff.new(root, "ChickenFootDustR", Vector3.new(-0.455, -1.30, -0.12), scale)
	self.nextGesture = self.random:NextNumber(2.3, 4.5)
	model:SetAttribute("RigState", "Wandering")
	model:SetAttribute("RigSpeed", 0)
	model:SetAttribute("RigGestureSerial", 0)
	CollectionService:AddTag(model, "HACChickenRig")
	return self
end

function Driver:Step(dt, rootPose, state, speed, attention, capturePhase)
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
	if self.model:GetAttribute("RigCapturePhase") ~= capturePhase then self.model:SetAttribute("RigCapturePhase", capturePhase) end
	if speed > 0.05 and state ~= "Capturing" then
		self.phase += dt * speed / math.max(1.65 * self.scale, 0.1)
		local step = math.floor(self.phase * 2)
		if step ~= self.lastStep then
			local foot = step % 2 == 0 and self.dustR or self.dustL
			foot:Emit(state == "Panicking" and 2 or 1)
			self.lastStep = step
		end
	end
	if speed < 0.05 and state ~= "Panicking" and state ~= "Tired"
		and state ~= "Capturing" and self.time >= self.nextGesture then
		local names = {"Peck", "Baffled", "Stumble"}
		local choice = state == "AtBase" and attention and "Baffled"
			or names[self.random:NextInteger(1, #names)]
		self.gestureSerial += 1
		self.model:SetAttribute("RigGesture", choice)
		self.model:SetAttribute("RigGestureSerial", self.gestureSerial)
		self.nextGesture = self.time + self.random:NextNumber(4, 7)
	end
end

return Driver
