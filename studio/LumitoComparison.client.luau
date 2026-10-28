-- Client-local playback for the rig half of the Studio-only A/B display.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() or game.PlaceId ~= 102310424634629 then return end

local Clips = require(game.ReplicatedStorage.HACShared.LumitoRigClips)
local arena = workspace:WaitForChild("HuntACreature"):WaitForChild("LumitoRigComparison", 30)
if not arena then return end
local animations = Clips.RegisterPreviews()
local stateToClip = {AtBase = "Idle", Wandering = "Walk", Panicking = "Panic",
	Tired = "Tired", Capturing = "Capturing"}
local model, animator, tracks, current, currentName, gestureTrack
local random = Random.new()
local nextBlink = time() + random:NextNumber(2.8, 5.8)
local blinkUntil = 0
local gaze = 0
local lastGestureSerial = arena:GetAttribute("DemoGestureSerial") or 0

local function dispose()
	if tracks then
		for _, track in pairs(tracks) do track:Stop(0) end
	end
	model, animator, tracks, current, currentName, gestureTrack = nil, nil, nil, nil, nil, nil
end

local function bind(candidate)
	if not candidate or not candidate:IsA("Model") then return end
	dispose()
	model = candidate
	local controller = candidate:FindFirstChildOfClass("AnimationController")
	animator = controller and controller:FindFirstChildOfClass("Animator")
	if not animator then dispose(); return end
	tracks = {}
	for name, animation in pairs(animations) do
		local track = animator:LoadAnimation(animation)
		track.Looped = Clips.Definitions[name].loop
		tracks[name] = track
	end
	lastGestureSerial = arena:GetAttribute("DemoGestureSerial") or 0
	currentName = nil
end

local function updateState()
	if not tracks then return end
	local state = arena:GetAttribute("DemoState") or "AtBase"
	local name = stateToClip[state] or "Idle"
	if currentName ~= name then
		if current then current:Stop(0.22) end
		if gestureTrack then gestureTrack:Stop(0.12); gestureTrack = nil end
		currentName, current = name, tracks[name]
		current:Play(0.24, 1, 1)
	end
	local definition = Clips.Definitions[name]
	if definition.referenceSpeed then
		local speed = arena:GetAttribute("DemoSpeed") or 0
		current:AdjustSpeed(math.clamp(speed / definition.referenceSpeed, 0.6, 1.35))
	end
end

local function updateGesture()
	local serial = arena:GetAttribute("DemoGestureSerial") or 0
	if serial == lastGestureSerial or not tracks then return end
	lastGestureSerial = serial
	if currentName ~= "Idle" then return end
	local name = arena:GetAttribute("DemoGesture")
	local chosen = name and tracks[name]
	if not chosen then return end
	if gestureTrack then gestureTrack:Stop(0.08) end
	gestureTrack = chosen
	chosen:Play(0.16, 1, 1)
end

arena.ChildAdded:Connect(function(child)
	if child.Name == "Rig" then task.defer(bind, child) end
end)
arena.ChildRemoved:Connect(function(child)
	if child == model then dispose() end
end)
bind(arena:FindFirstChild("Rig"))

RunService.PreSimulation:Connect(function(dt)
	if not model or not model.Parent then return end
	updateState()
	updateGesture()
	-- A separate, unkeyed neck joint carries attention without fighting the clips.
	local pivot = model:FindFirstChild("HeadPivot")
	local lookJoint = pivot and model:FindFirstChild("Torso") and model.Torso:FindFirstChild("HeadLookJoint")
	if lookJoint then
		local rootPose = model.Root.CFrame
		local attention = rootPose.Position + rootPose.LookVector * 4 + Vector3.new(2, 0, 0)
		local delta = rootPose:VectorToObjectSpace(attention - rootPose.Position)
		local target = currentName == "Capturing" and 0
			or math.clamp(math.atan2(-delta.X, -delta.Z), -0.5, 0.5)
		gaze += (target - gaze) * (1 - math.exp(-math.min(dt, 0.1) * 4))
		lookJoint.Transform = CFrame.Angles(0, gaze, 0)
	end
	local now = time()
	if now >= nextBlink and now >= blinkUntil then
		blinkUntil = now + 0.16
		nextBlink = now + random:NextNumber(2.8, 5.8)
	end
	local blink = now < blinkUntil
	for _, name in ipairs({"Eye_L", "Eye_R"}) do
		local eye = model:FindFirstChild(name)
		if eye then
			local baseY = eye:GetAttribute("ComparisonEyeHeight")
			if not baseY then baseY = eye.Size.Y; eye:SetAttribute("ComparisonEyeHeight", baseY) end
			eye.Size = Vector3.new(eye.Size.X, baseY * (blink and 0.18 or 1), eye.Size.Z)
		end
	end
	local glint = model:FindFirstChild("EyeGlint_L")
	if glint then glint.Transparency = blink and 1 or 0 end
end)
