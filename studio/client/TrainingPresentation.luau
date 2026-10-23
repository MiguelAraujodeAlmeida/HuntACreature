-- Cosmetic training scene. The server alone positions players and awards strength.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Visuals = require(game.ReplicatedStorage.HACShared.LassoVisuals)
local Audio = require(script.Parent.AudioFeedback)
local Scene = {}
Scene.__index = Scene

local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function joints(character)
	local found = {}
	for _, joint in ipairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
			if joint.Name == "RightShoulder" or joint.Name == "Right Shoulder" then found.shoulder = joint
			elseif joint.Name == "RightElbow" then found.elbow = joint
			elseif joint.Name == "RightWrist" then found.wrist = joint
			elseif joint.Name == "Waist" then found.waist = joint end
		end
	end
	return found
end

local function localRotation(joint, rotation)
	local basis
	if joint:IsA("Motor6D") then basis = joint.C0.Rotation
	else basis = joint.Attachment0 and joint.Attachment0.CFrame.Rotation or CFrame.identity end
	return basis:Inverse() * rotation * basis
end

local function clear(state)
	for joint, transform in pairs(state.baseTransforms or {}) do
		if joint.Parent then pcall(function() joint.Transform = transform end) end
	end
	if state.line then Visuals.CleanupLine(state.line) end
	if state.loop then state.loop:Destroy() end
	if state.dummy and state.dummy.Parent then state.dummy:PivotTo(state.rest) end
end

function Scene.new(localPlayer)
	local self = setmetatable({ localPlayer = localPlayer, states = {}, connections = {} }, Scene)
	local folder = Instance.new("Folder")
	folder.Name = "HACTrainingPresentation"
	folder.Parent = workspace
	self.folder = folder
	table.insert(self.connections, RunService.PreAnimation:Connect(function()
		for _, state in pairs(self.states) do
			for joint, transform in pairs(state.baseTransforms or {}) do
				if joint.Parent then pcall(function() joint.Transform = transform end) end
			end
			state.baseTransforms = {}
		end
	end))
	table.insert(self.connections, RunService.PreSimulation:Connect(function() self:_pose() end))
	table.insert(self.connections, RunService.RenderStepped:Connect(function() self:_render() end))
	return self
end

function Scene:_start(player, character, dummy)
	local target = dummy:FindFirstChild("Alvo")
	if not target then return end
	local loop = Visuals.Loop(self.folder)
	local line = Visuals.Line(character, loop.PrimaryPart)
	self.states[player] = {
		character = character, dummy = dummy, target = target, rest = dummy:GetPivot(),
		loop = loop, line = line, joints = joints(character), baseTransforms = {},
		lastPulse = player:GetAttribute("TrainingPulse"), epoch = player:GetAttribute("TrainingStartedAt") or workspace:GetServerTimeNow(),
	}
end

function Scene:_reward(player, state)
	local amount = player:GetAttribute("TrainingGain") or 0
	if amount <= 0 then return end
	local marker = Instance.new("BillboardGui")
	marker.Name = "TrainingReward"
	marker.Size = UDim2.fromOffset(118, 48)
	marker.StudsOffset = Vector3.new(0, 2.5, 0)
	marker.AlwaysOnTop = true
	marker.Adornee = state.target
	marker.Parent = self.folder
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text = "+" .. amount .. " STRENGTH"
	label.Font, label.TextScaled = Enum.Font.FredokaOne, true
	label.TextColor3, label.TextStrokeColor3 = Color3.fromRGB(255, 216, 77), Color3.fromRGB(24, 30, 51)
	label.TextStrokeTransparency = 0
	label.Parent = marker
	TweenService:Create(marker, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 3.6, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.65), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.7, function() if marker.Parent then marker:Destroy() end end)
	Visuals.Burst(self.folder, state.target.Position, Color3.fromRGB(255, 205, 73), 5)
	if player == self.localPlayer then Audio.Play("Progress") end
end

function Scene:_sync(player)
	local current = self.states[player]
	local character = player.Character
	local world = workspace:FindFirstChild("HuntACreature")
	local bases = world and world:FindFirstChild("Hub") and world.Hub:FindFirstChild("Bases")
	local base = bases and bases:FindFirstChild("Base" .. tostring(player:GetAttribute("BaseIndex")))
	local dummy = base and base:FindFirstChild("Manequim")
	local active = player:GetAttribute("Treinando") == true and character and character.Parent
		and dummy and dummy.PrimaryPart and character:FindFirstChild("HumanoidRootPart")
	if current and (not active or current.character ~= character or current.dummy ~= dummy) then
		clear(current)
		self.states[player] = nil
		current = nil
	end
	if active and not current then
		self:_start(player, character, dummy)
		current = self.states[player]
	end
	if current then
		local pulse = player:GetAttribute("TrainingPulse")
		if pulse and pulse ~= current.lastPulse then
			current.lastPulse, current.epoch = pulse, pulse
			self:_reward(player, current)
		end
	end
end

function Scene:_render()
	for _, player in ipairs(Players:GetPlayers()) do self:_sync(player) end
	for player, state in pairs(self.states) do
		local root = state.character:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera
		if root and (not camera or (camera.CFrame.Position - root.Position).Magnitude < 110) then
			local phase = (workspace:GetServerTimeNow() - state.epoch) % C.TrainingSeconds / C.TrainingSeconds
			state.phase = phase
			local variation = (math.floor(state.epoch / C.TrainingSeconds) % 2 == 0) and 1 or -1
			local tension = smooth((phase - 0.3) / 0.18) * (1 - smooth((phase - 0.72) / 0.25))
			local hit = smooth((phase - 0.72) / 0.1) * (1 - smooth((phase - 0.84) / 0.16))
			state.dummy:PivotTo(state.rest * CFrame.new(0, hit * -0.12, 0)
				* CFrame.Angles(tension * (0.13 + variation * 0.04) + hit * -0.28,
					variation * tension * 0.12, variation * math.sin(phase * 22) * tension * 0.09))
			local hand = state.character:FindFirstChild("RightHand") or state.character:FindFirstChild("Right Arm")
			local from = hand and hand.Position or root.Position + root.CFrame.RightVector
			local target = state.target.Position + Vector3.new(0, 0.15, -0.55)
			local flight = smooth((phase - 0.2) / 0.23)
			local returnFlight = smooth((phase - 0.8) / 0.18)
			local position = from:Lerp(target, flight * (1 - returnFlight))
			state.loop:PivotTo(CFrame.lookAt(position, position + root.CFrame.LookVector)
				* CFrame.Angles(0, 0, phase * math.pi * 2))
			state.loop.PrimaryPart.Transparency = 1
			if state.line then state.line.beam.Width0 = 0.1 + tension * 0.04 end
		end
	end
end

function Scene:_pose()
	for _, state in pairs(self.states) do
		local phase = state.phase or 0
		local lift = smooth(phase / 0.16) * (1 - smooth((phase - 0.85) / 0.15))
		local throw = smooth((phase - 0.18) / 0.18)
		local poses = {
			shoulder = CFrame.Angles(math.rad(110 - throw * 18), 0, math.rad(24)),
			elbow = CFrame.Angles(math.rad(62 * (1 - throw * 0.7)), 0, 0),
			wrist = CFrame.Angles(math.sin(phase * 14) * 0.14, 0, math.cos(phase * 14) * 0.1),
			waist = CFrame.Angles(0, math.sin(phase * 12) * 0.035, 0),
		}
		for name, joint in pairs(state.joints) do
			if joint.Parent then
				pcall(function()
					local base = joint.Transform
					state.baseTransforms[joint] = base
					local pose = localRotation(joint, poses[name])
					joint.Transform = base:Lerp(CFrame.new(base.Position) * pose, lift)
				end)
			end
		end
	end
end

function Scene:Destroy()
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	for _, state in pairs(self.states) do clear(state) end
	self.folder:Destroy()
end

return Scene
