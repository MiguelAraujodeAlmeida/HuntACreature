-- Reproducible, unpublished animation sources for the comparison Lumito.
-- RegisterKeyframeSequence produces session-local preview IDs. Published IDs remain
-- intentionally absent until the developer approves the rig for the real game.
local Clips = {}

local function P(t, body, head, leftArm, rightArm, leftFoot, rightFoot, leftEar, rightEar, tail)
	return {t = t, Torso = body, Head = head, Arm_L = leftArm, Arm_R = rightArm,
		Foot_L = leftFoot, Foot_R = rightFoot, Ear_L_Base = leftEar,
		Ear_R_Base = rightEar, Tail = tail}
end

-- Each channel is {local x,y,z in studs, pitch,yaw,roll in degrees}.
local B = function(y, pitch, roll) return {0, y or 0, 0, pitch or 0, 0, roll or 0} end
local H = function(pitch, yaw, roll) return {0, 0, 0, pitch or 0, yaw or 0, roll or 0} end
local A = function(pitch, roll) return {0, 0, 0, pitch or 0, 0, roll or 0} end
local F = function(y, z, pitch) return {0, y or 0, z or 0, pitch or 0, 0, 0} end
local E = function(pitch, roll) return {0, 0, 0, pitch or 0, 0, roll or 0} end
local T = function(pitch, yaw) return {0, 0, 0, pitch or 0, yaw or 0, 0} end

Clips.Definitions = {
	Idle = {loop = true, priority = Enum.AnimationPriority.Idle, frames = {
		P(0, B(0, 0, -1), H(-2, -3, -3), A(-5, 10), A(3, -11), F(), F(), E(0, 2), E(0, -3), T(0, -6)),
		P(0.65, B(0.035, -2, 1), H(4, 4, 5), A(5, 15), A(-8, -7), F(), F(), E(-5, 4), E(2, -1), T(-3, 8)),
		P(1.3, B(0.055, 1, 2), H(2, 7, 2), A(7, 8), A(-5, -15), F(), F(), E(-2, -2), E(-4, -4), T(3, 11)),
		P(1.95, B(0.025, 2, -1), H(-3, -2, -4), A(-3, 12), A(5, -10), F(), F(), E(3, 3), E(1, -1), T(0, -2)),
		P(2.6, B(0, 0, -1), H(-2, -3, -3), A(-5, 10), A(3, -11), F(), F(), E(0, 2), E(0, -3), T(0, -6)),
	}},
	Walk = {loop = true, priority = Enum.AnimationPriority.Movement, referenceSpeed = 3.5, frames = {
		P(0, B(0, -5, -3), H(3, 0, 3), A(-25, 18), A(27, -14), F(0.23, -0.23, -12), F(0, 0.19, 7), E(8, 4), E(4, -4), T(1, -9)),
		P(0.22, B(0.10, -8, 0), H(-2, 2, 0), A(-9, 14), A(11, -11), F(0.15, 0, 4), F(0.03, -0.08, -4), E(-1, 1), E(2, -2), T(-2, 2)),
		P(0.44, B(0, -5, 3), H(3, 0, -3), A(27, 14), A(-25, -18), F(0, 0.19, 7), F(0.23, -0.23, -12), E(4, 4), E(8, -4), T(1, 9)),
		P(0.66, B(0.10, -8, 0), H(-2, -2, 0), A(11, 11), A(-9, -14), F(0.03, -0.08, -4), F(0.15, 0, 4), E(2, 2), E(-1, -1), T(-2, -2)),
		P(0.88, B(0, -5, -3), H(3, 0, 3), A(-25, 18), A(27, -14), F(0.23, -0.23, -12), F(0, 0.19, 7), E(8, 4), E(4, -4), T(1, -9)),
	}},
	Panic = {loop = true, priority = Enum.AnimationPriority.Movement, referenceSpeed = 14, frames = {
		P(0, B(0.03, -16, -7), H(-9, 0, 6), A(-47, 40), A(39, -34), F(0.31, -0.38, -17), F(0, 0.24, 11), E(22, 12), E(19, -10), T(-12, -13)),
		P(0.14, B(0.19, -21, 0), H(-12, 2, 0), A(-13, 32), A(7, -29), F(0.15, 0.03, 4), F(0.07, -0.10, -4), E(28, 9), E(26, -8), T(-18, 0)),
		P(0.28, B(0.03, -16, 7), H(-9, 0, -6), A(39, 34), A(-47, -40), F(0, 0.24, 11), F(0.31, -0.38, -17), E(19, 10), E(22, -12), T(-12, 13)),
		P(0.42, B(0.19, -21, 0), H(-12, -2, 0), A(7, 29), A(-13, -32), F(0.07, -0.10, -4), F(0.15, 0.03, 4), E(26, 8), E(28, -9), T(-18, 0)),
		P(0.56, B(0.03, -16, -7), H(-9, 0, 6), A(-47, 40), A(39, -34), F(0.31, -0.38, -17), F(0, 0.24, 11), E(22, 12), E(19, -10), T(-12, -13)),
	}},
	Tired = {loop = true, priority = Enum.AnimationPriority.Movement, referenceSpeed = 1.8, frames = {
		P(0, B(-0.09, 11, -2), H(17, -3, -5), A(13, 1), A(9, -2), F(0.09, -0.10, 5), F(), E(14, -2), E(13, 2), T(16, -3)),
		P(0.42, B(-0.12, 14, 0), H(21, 2, 3), A(8, 2), A(14, -1), F(0.02, 0.08, -3), F(), E(17, 2), E(16, -2), T(19, 2)),
		P(0.84, B(-0.09, 11, 2), H(17, 3, 5), A(9, 2), A(13, -1), F(), F(0.09, -0.10, 5), E(13, -2), E(14, 2), T(16, 3)),
		P(1.26, B(-0.12, 14, 0), H(21, -2, -3), A(14, 1), A(8, -2), F(), F(0.02, 0.08, -3), E(16, 2), E(17, -2), T(19, -2)),
		P(1.68, B(-0.09, 11, -2), H(17, -3, -5), A(13, 1), A(9, -2), F(0.09, -0.10, 5), F(), E(14, -2), E(13, 2), T(16, -3)),
	}},
	Capturing = {loop = true, priority = Enum.AnimationPriority.Movement, frames = {
		P(0, B(-0.04, -9, -3), H(-6, 0, -4), A(-32, 25), A(-25, -24), F(0, -0.05, -4), F(0, 0.06, 4), E(8, 8), E(7, -7), T(-5, -7)),
		P(0.28, B(-0.10, 13, 7), H(11, -8, 8), A(-58, 35), A(-42, -33), F(0, -0.09, -8), F(0, 0.13, 10), E(19, 13), E(18, -8), T(9, 12)),
		P(0.55, B(0.02, -17, -5), H(-16, 6, -7), A(-16, 24), A(-48, -38), F(0.07, 0.05, 6), F(0, -0.10, -5), E(-5, 6), E(5, -11), T(-13, -13)),
		P(0.82, B(-0.09, 11, 5), H(8, -6, 6), A(-49, 34), A(-34, -31), F(0, -0.08, -7), F(0, 0.10, 7), E(18, 11), E(16, -7), T(8, 9)),
		P(1.1, B(-0.04, -9, -3), H(-6, 0, -4), A(-32, 25), A(-25, -24), F(0, -0.05, -4), F(0, 0.06, 4), E(8, 8), E(7, -7), T(-5, -7)),
	}},
	Curious = {loop = false, priority = Enum.AnimationPriority.Action, frames = {
		P(0, B(), H(), A(0, 9), A(0, -9), F(), F(), E(), E(), T()),
		P(0.22, B(0.01, -3, -3), H(-10, -18, -12), A(4, 13), A(-31, -24), F(), F(), E(-13, 9), E(3, -5), T(-3, 8)),
		P(0.68, B(0.04, -5, -3), H(-12, -26, -16), A(6, 15), A(-39, -30), F(), F(), E(-18, 11), E(5, -6), T(-4, 13)),
		P(1.08, B(0.02, -2, 2), H(-5, 10, 5), A(3, 10), A(-9, -16), F(), F(), E(6, 3), E(-7, -5), T(1, -5)),
		P(1.48, B(), H(), A(0, 9), A(0, -9), F(), F(), E(), E(), T()),
	}},
	Greeting = {loop = false, priority = Enum.AnimationPriority.Action, frames = {
		P(0, B(), H(), A(0, 9), A(0, -9), F(), F(), E(), E(), T()),
		P(0.25, B(0.08, -4, 5), H(-8, 0, 12), A(-28, 80), A(-10, -16), F(0.03, -0.03), F(), E(-7, 9), E(3, -5), T(-4, 11)),
		P(0.53, B(0.10, -6, 6), H(-10, 5, 15), A(-35, 95), A(-9, -17), F(0.03, -0.03), F(), E(-11, 11), E(4, -5), T(-5, 16)),
		P(0.79, B(0.07, -5, 4), H(-7, -4, 8), A(-25, 68), A(-8, -15), F(), F(), E(-6, 7), E(0, -4), T(-3, 7)),
		P(1.06, B(0.09, -4, 5), H(-9, 4, 12), A(-34, 91), A(-7, -15), F(), F(), E(-9, 10), E(2, -4), T(-4, 14)),
		P(1.55, B(), H(), A(0, 9), A(0, -9), F(), F(), E(), E(), T()),
	}},
	Playful = {loop = false, priority = Enum.AnimationPriority.Action, frames = {
		P(0, B(), H(), A(0, 9), A(0, -9), F(), F(), E(), E(), T()),
		P(0.22, B(-0.13, 13, -7), H(8, 0, 6), A(15, 16), A(15, -16), F(0, -0.05), F(0, -0.05), E(9, 5), E(9, -5), T(6, -10)),
		P(0.45, B(0.27, -15, 8), H(-13, 7, -9), A(-48, 55), A(-42, -53), F(0.18, -0.02), F(0.18, -0.02), E(-17, 13), E(-14, -11), T(-12, 15)),
		P(0.68, B(0.34, -10, -6), H(-9, -4, 7), A(-35, 45), A(-39, -47), F(0.24, 0.03), F(0.24, 0.03), E(-12, 9), E(-15, -12), T(-10, -11)),
		P(0.97, B(-0.06, 9, 5), H(10, 0, -6), A(13, 18), A(9, -18), F(), F(), E(8, 4), E(8, -4), T(5, 9)),
		P(1.43, B(), H(), A(0, 9), A(0, -9), F(), F(), E(), E(), T()),
	}},
}

local graph = {
	name = "Root", children = {
		{name = "Torso", children = {
			{name = "HeadPivot", children = {
				{name = "Head", children = {{name = "Ear_L_Base"}, {name = "Ear_R_Base"}}},
			}},
			{name = "Arm_L"}, {name = "Arm_R"}, {name = "Tail"},
		}},
		{name = "Foot_L"}, {name = "Foot_R"},
	},
}

local function transform(values)
	if not values then return CFrame.new() end
	return CFrame.new(values[1], values[2], values[3])
		* CFrame.Angles(math.rad(values[4]), math.rad(values[5]), math.rad(values[6]))
end

local function makePose(node, frame)
	local pose = Instance.new("Pose")
	pose.Name = node.name
	pose.CFrame = transform(frame[node.name])
	pose.Weight = node.name == "Root" and 0 or 1
	pose.EasingStyle = Enum.PoseEasingStyle.CubicV2
	pose.EasingDirection = Enum.PoseEasingDirection.InOut
	for _, child in ipairs(node.children or {}) do
		pose:AddSubPose(makePose(child, frame))
	end
	return pose
end

function Clips.Build(name)
	local def = assert(Clips.Definitions[name], "Unknown Lumito clip: " .. tostring(name))
	local sequence = Instance.new("KeyframeSequence")
	sequence.Name = "LumitoRig_" .. name
	sequence.Loop = def.loop
	sequence.Priority = def.priority
	for _, frame in ipairs(def.frames) do
		local key = Instance.new("Keyframe")
		key.Time = frame.t
		key.Name = "Pose_" .. tostring(frame.t)
		key:AddPose(makePose(graph, frame))
		sequence:AddKeyframe(key)
	end
	return sequence
end

function Clips.RegisterPreviews()
	local provider = game:GetService("KeyframeSequenceProvider")
	local animations = {}
	for name in pairs(Clips.Definitions) do
		local sequence = Clips.Build(name)
		local animation = Instance.new("Animation")
		animation.Name = name
		animation.AnimationId = provider:RegisterKeyframeSequence(sequence)
		sequence:Destroy()
		animations[name] = animation
	end
	return animations
end

return Clips
