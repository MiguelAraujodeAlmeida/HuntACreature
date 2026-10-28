-- Local, frame-smooth playback of the versioned Lumito rig clips.
-- It uses Motor6D.Transform, so the same sources work without unpublished animation IDs.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Clips = require(game.ReplicatedStorage.HACShared.LumitoRigClips)
local Performance = {}
local active = {}
local channels = {
	Torso = "BodyJoint", Head = "HeadJoint", Arm_L = "ArmLJoint", Arm_R = "ArmRJoint",
	Foot_L = "FootLJoint", Foot_R = "FootRJoint", Ear_L_Base = "EarLJoint",
	Ear_R_Base = "EarRJoint", Tail = "TailJoint",
}
local states = {Wandering = "Walk", Panicking = "Panic", Tired = "Tired", Capturing = "Capturing"}

local function retryBind(model)
	task.delay(0.1, function()
		if model.Parent and CollectionService:HasTag(model, "HACLumitoRig") then
			Performance.Bind(model)
		end
	end)
end

local function transform(values, scale)
	if not values then return CFrame.new() end
	return CFrame.new(values[1] * scale, values[2] * scale, values[3] * scale)
		* CFrame.Angles(math.rad(values[4]), math.rad(values[5]), math.rad(values[6]))
end

local function sample(name, position, scale)
	local definition = Clips.Definitions[name]
	local frames = definition.frames
	local length = frames[#frames].t
	if definition.loop then position %= length else position = math.clamp(position, 0, length) end
	local left, right = frames[1], frames[#frames]
	for index = 1, #frames - 1 do
		if position <= frames[index + 1].t then
			left, right = frames[index], frames[index + 1]
			break
		end
	end
	local span = right.t - left.t
	local alpha = span > 0 and math.clamp((position - left.t) / span, 0, 1) or 0
	alpha = alpha * alpha * (3 - 2 * alpha)
	local result = {}
	for partName in pairs(channels) do
		result[partName] = transform(left[partName], scale):Lerp(transform(right[partName], scale), alpha)
	end
	return result, length
end

local function bind(model)
	if active[model] or not model:IsA("Model") then return end
	local root = model:FindFirstChild("Root")
	local torso = model:FindFirstChild("Torso")
	local head = model:FindFirstChild("Head")
	if not root or not torso or not head or not model:FindFirstChild("HeadPivot") then
		retryBind(model)
		return
	end
	local joints = {}
	for channel, jointName in pairs(channels) do
		local found = model:FindFirstChild(jointName, true)
		if not found or not found:IsA("Motor6D") then retryBind(model); return end
		joints[channel] = found
	end
	local look = torso:FindFirstChild("HeadLookJoint")
	if not look then retryBind(model); return end
	local random = Random.new()
	active[model] = {model = model, root = root, joints = joints, look = look,
		scale = model:GetAttribute("CreatureScale") or 1, clock = random:NextNumber(0, 2.6),
		clip = nil, blend = 1, prior = {}, gaze = 0, gestureSerial = model:GetAttribute("RigGestureSerial") or 0,
		gesture = nil, gestureClock = 0, blinkAt = os.clock() + random:NextNumber(2.8, 5.8), blinkUntil = 0,
		eyes = {model:FindFirstChild("Eye_L"), model:FindFirstChild("Eye_R")},
		glint = model:FindFirstChild("EyeGlint_L"), random = random}
end
Performance.Bind = bind

local function tickActor(actor, dt, now)
	local model, root = actor.model, actor.root
	if not model.Parent or not CollectionService:HasTag(model, "HACLumitoRig") then active[model] = nil; return end
	local state = model:GetAttribute("RigState") or "Wandering"
	local speed = model:GetAttribute("RigSpeed") or 0
	local name = states[state] or "Idle"
	if (state == "Wandering" or state == "AtBase") and speed < 0.05 then name = "Idle" end
	if state == "AtBase" and speed >= 0.05 then name = "Walk" end
	if name ~= actor.clip then
		actor.prior = {}
		for channel, joint in pairs(actor.joints) do actor.prior[channel] = joint.Transform end
		actor.clip, actor.clock, actor.blend = name, 0, 0
		actor.gesture = nil
	end
	local serial = model:GetAttribute("RigGestureSerial") or 0
	if serial ~= actor.gestureSerial then
		actor.gestureSerial = serial
		local gesture = model:GetAttribute("RigGesture")
		if name == "Idle" and Clips.Definitions[gesture] then
			actor.prior = {}
			for channel, joint in pairs(actor.joints) do actor.prior[channel] = joint.Transform end
			actor.blend = 0
			actor.gesture, actor.gestureClock = gesture, 0
		end
	end
	local definition = Clips.Definitions[name]
	local rate = definition.referenceSpeed and math.clamp(speed / definition.referenceSpeed, 0.2, 1.5) or 1
	actor.clock += dt * rate
	local clipName, clipClock = name, actor.clock
	if actor.gesture then
		actor.gestureClock += dt
		clipName, clipClock = actor.gesture, actor.gestureClock
		local gestureFrames = Clips.Definitions[clipName].frames
		if clipClock >= gestureFrames[#gestureFrames].t then
			actor.prior = {}
			for channel, joint in pairs(actor.joints) do actor.prior[channel] = joint.Transform end
			actor.blend = 0
			actor.gesture = nil
			clipName, clipClock = name, actor.clock
		end
	end
	local poses = sample(clipName, clipClock, actor.scale)
	actor.blend = math.min(1, actor.blend + dt / 0.22)
	for channel, joint in pairs(actor.joints) do
		local from = actor.prior[channel] or CFrame.new()
		joint.Transform = from:Lerp(poses[channel], actor.blend)
	end
	local attention = model:GetAttribute("RigAttention")
	local target = 0
	if typeof(attention) == "Vector3" and state ~= "Capturing" then
		local delta = root.CFrame:VectorToObjectSpace(attention - root.Position)
		target = math.clamp(math.atan2(-delta.X, -delta.Z), -0.5, 0.5)
	end
	actor.gaze += (target - actor.gaze) * (1 - math.exp(-math.min(dt, 0.1) * 5))
	actor.look.Transform = CFrame.Angles(0, actor.gaze, 0)
	if now >= actor.blinkAt then
		actor.blinkUntil = now + 0.16
		actor.blinkAt = now + actor.random:NextNumber(2.8, 5.8)
	end
	local blink = now < actor.blinkUntil
	for _, eye in ipairs(actor.eyes) do
		if eye then
			local height = eye:GetAttribute("RigEyeHeight")
			if not height then height = eye.Size.Y; eye:SetAttribute("RigEyeHeight", height) end
			eye.Size = Vector3.new(eye.Size.X, height * (blink and 0.18 or 1), eye.Size.Z)
		end
	end
	if actor.glint then actor.glint.Transparency = blink and 1 or 0 end
end

function Performance.Start()
	for _, model in ipairs(CollectionService:GetTagged("HACLumitoRig")) do bind(model) end
	CollectionService:GetInstanceAddedSignal("HACLumitoRig"):Connect(bind)
	CollectionService:GetInstanceRemovedSignal("HACLumitoRig"):Connect(function(model) active[model] = nil end)
	RunService.PreSimulation:Connect(function(dt)
		local player = Players.LocalPlayer
		local camera = workspace.CurrentCamera
		local anchor = camera and camera.CFrame.Position
		if not anchor and player.Character then
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			anchor = root and root.Position
		end
		local now = os.clock()
		for _, actor in pairs(active) do
			if not anchor or (actor.root.Position - anchor).Magnitude < 150 then
				tickActor(actor, dt, now)
			end
		end
	end)
end

return Performance
