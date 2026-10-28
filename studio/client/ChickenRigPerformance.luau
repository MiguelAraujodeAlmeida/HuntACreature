-- Local playback of Chicken's versioned clips. No Studio preview IDs are needed.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Clips = require(game.ReplicatedStorage.HACShared.ChickenRigClips)
local Performance = {}
local active, pending = {}, {}
local channels = {
	Body="ChickenBodyJoint", Head="ChickenHeadJoint",
	WingL="ChickenWingLJoint", WingR="ChickenWingRJoint",
	FootL="ChickenFootLJoint", FootR="ChickenFootRJoint", Tail="ChickenTailJoint",
}
local states = {Wandering="Walk", Panicking="Panic", Tired="Tired", Capturing="Capturing"}

local function transform(values, scale)
	if not values then return CFrame.new() end
	return CFrame.new(values[1]*scale, values[2]*scale, values[3]*scale)
		* CFrame.Angles(math.rad(values[4]), math.rad(values[5]), math.rad(values[6]))
end

local function sample(name, position, scale)
	local definition = Clips.Definitions[name]
	local frames = definition.frames
	local length = frames[#frames].t
	if definition.loop then position %= length else position = math.clamp(position, 0, length) end
	local left, right = frames[1], frames[#frames]
	for index=1,#frames-1 do
		if position <= frames[index+1].t then
			left, right = frames[index], frames[index+1]
			break
		end
	end
	local span = right.t-left.t
	local alpha = span > 0 and math.clamp((position-left.t)/span,0,1) or 0
	alpha = alpha*alpha*(3-2*alpha)
	local result = {}
	for channel in pairs(channels) do
		result[channel] = transform(left[channel],scale):Lerp(transform(right[channel],scale),alpha)
	end
	return result
end

local bind
local function retry(model)
	if pending[model] then return end
	pending[model] = true
	task.delay(0.15,function()
		pending[model] = nil
		if model.Parent and CollectionService:HasTag(model,"HACChickenRig") then bind(model) end
	end)
end

bind = function(model)
	if active[model] or not model:IsA("Model") then return end
	local root = model:FindFirstChild("Root")
	local joints = {}
	if not root or not model:FindFirstChild("ChickenHeadPivot") then retry(model); return end
	for channel,jointName in pairs(channels) do
		local joint = model:FindFirstChild(jointName,true)
		if not joint or not joint:IsA("Motor6D") then retry(model); return end
		joints[channel] = joint
	end
	local look = model:FindFirstChild("ChickenHeadLookJoint",true)
	if not look then retry(model); return end
	local random = Random.new()
	active[model] = {model=model, root=root, joints=joints, look=look,
		scale=model:GetAttribute("CreatureScale") or 1,
		clock=random:NextNumber(0,2.4), clip=nil, blend=1, prior={},
		gesture=nil, gestureClock=0, gestureSerial=model:GetAttribute("RigGestureSerial") or 0,
		gaze=0, blinkAt=os.clock()+random:NextNumber(2.4,5.3), blinkUntil=0,
		eyes={model:FindFirstChild("Eye_L"),model:FindFirstChild("Eye_R")},
		glints={model:FindFirstChild("Glint_L"),model:FindFirstChild("Glint_R")},random=random}
end

local function snapshot(actor)
	actor.prior = {}
	for channel,joint in pairs(actor.joints) do actor.prior[channel] = joint.Transform end
	actor.blend = 0
end

local function tickActor(actor, dt, now)
	local model = actor.model
	if not model.Parent or not CollectionService:HasTag(model,"HACChickenRig") then active[model]=nil; return end
	local state = model:GetAttribute("RigState") or "Wandering"
	local speed = model:GetAttribute("RigSpeed") or 0
	local clip = states[state] or "Idle"
	if (state=="Wandering" or state=="AtBase") and speed<0.05 then clip="Idle" end
	if state=="AtBase" and speed>=0.05 then clip="Walk" end
	if clip ~= actor.clip then
		snapshot(actor)
		actor.clip,actor.clock,actor.gesture = clip,0,nil
	end
	local serial = model:GetAttribute("RigGestureSerial") or 0
	if serial ~= actor.gestureSerial then
		actor.gestureSerial = serial
		local gesture = model:GetAttribute("RigGesture")
		if clip=="Idle" and Clips.Definitions[gesture] then
			snapshot(actor)
			actor.gesture,actor.gestureClock = gesture,0
		end
	end
	local definition = Clips.Definitions[clip]
	local rate = definition.referenceSpeed
		and math.clamp(speed/math.max(definition.referenceSpeed*actor.scale,0.1),0.15,2.2) or 1
	actor.clock += dt*rate
	local playing,position = clip,actor.clock
	if actor.gesture then
		actor.gestureClock += dt
		playing,position = actor.gesture,actor.gestureClock
		local frames = Clips.Definitions[playing].frames
		if position>=frames[#frames].t then
			snapshot(actor)
			actor.gesture=nil
			playing,position=clip,actor.clock
		end
	end
	local poses = sample(playing,position,actor.scale)
	actor.blend = math.min(1,actor.blend+dt/0.22)
	for channel,joint in pairs(actor.joints) do
		joint.Transform=(actor.prior[channel] or CFrame.new()):Lerp(poses[channel],actor.blend)
	end
	local attention = model:GetAttribute("RigAttention")
	local target = 0
	if typeof(attention)=="Vector3" and state~="Capturing" then
		local delta = actor.root.CFrame:VectorToObjectSpace(attention-actor.root.Position)
		target = math.clamp(math.atan2(-delta.X,-delta.Z),-0.42,0.42)
	end
	actor.gaze += (target-actor.gaze)*(1-math.exp(-math.min(dt,0.1)*4))
	actor.look.Transform=CFrame.Angles(0,actor.gaze,0)
	if now>=actor.blinkAt then
		actor.blinkUntil=now+0.13
		actor.blinkAt=now+actor.random:NextNumber(2.4,5.3)
	end
	local blinking = now<actor.blinkUntil
	for _,eye in ipairs(actor.eyes) do
		if eye then
			local height=eye:GetAttribute("RigEyeHeight")
			if not height then height=eye.Size.Y;eye:SetAttribute("RigEyeHeight",height) end
			eye.Size=Vector3.new(eye.Size.X,height*(blinking and 0.18 or 1),eye.Size.Z)
		end
	end
	for _,glint in ipairs(actor.glints) do
		if glint then glint.Transparency=blinking and 1 or 0 end
	end
end

function Performance.Start()
	for _,model in ipairs(CollectionService:GetTagged("HACChickenRig")) do bind(model) end
	CollectionService:GetInstanceAddedSignal("HACChickenRig"):Connect(bind)
	CollectionService:GetInstanceRemovedSignal("HACChickenRig"):Connect(function(model)
		active[model],pending[model]=nil,nil
	end)
	RunService.PreSimulation:Connect(function(dt)
		local player=Players.LocalPlayer
		local camera=workspace.CurrentCamera
		local anchor=camera and camera.CFrame.Position
		if not anchor and player.Character then
			local root=player.Character:FindFirstChild("HumanoidRootPart")
			anchor=root and root.Position
		end
		local now=os.clock()
		for _,actor in pairs(active) do
			if not anchor or (actor.root.Position-anchor).Magnitude<150 then tickActor(actor,dt,now) end
		end
	end)
end

return Performance
