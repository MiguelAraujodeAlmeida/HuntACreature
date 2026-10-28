-- Articulate the existing Lumito template without changing its visible geometry.
-- Root and Corpo remain authoritative, anchored parts outside the visual rig.
local Builder = {}

local function group(part)
	local name = part.Name
	local side = part:GetAttribute("FootSide")
	if side == "L" or side == "R" then return "Foot" .. side end
	if name:match("^Ear_L") then return "EarL" end
	if name:match("^Ear_R") then return "EarR" end
	if name:match("^Tail") then return "Tail" end
	if name == "Arm_L" then return "ArmL" end
	if name == "Arm_R" then return "ArmR" end
	if name == "Torso" or name == "Belly" then return "Body" end
	if name == "Head" or name == "Snout" or name == "Mouth" or name == "Fang"
		or name:match("^Eye") or name:match("^Crest_") or name:match("^Stud_Crest_") then return "Head" end
	return nil
end

local function motor(parent, child, pivot, name)
	local joint = Instance.new("Motor6D")
	joint.Name = name
	joint.Part0, joint.Part1 = parent, child
	joint.C0 = parent.CFrame:ToObjectSpace(pivot)
	joint.C1 = child.CFrame:ToObjectSpace(pivot)
	joint.Parent = parent
end

function Builder.Build(model)
	if model:FindFirstChild("HeadPivot") then return model end
	local root = assert(model:FindFirstChild("Root"), "Lumito rig needs Root")
	local scale = model:GetAttribute("CreatureScale") or 1
	local cores = {}
	for _, item in ipairs(model:GetChildren()) do
		if item:IsA("BasePart") then
			local side = item:GetAttribute("FootSide")
			if item.Name == "Torso" then cores.Body = item
			elseif item.Name == "Head" then cores.Head = item
			elseif item.Name == "Arm_L" then cores.ArmL = item
			elseif item.Name == "Arm_R" then cores.ArmR = item
			elseif item.Name == "Tail" then cores.Tail = item
			elseif item.Name == "Pe" and side == "L" then cores.FootL = item; item.Name = "Foot_L"
			elseif item.Name == "Pe" and side == "R" then cores.FootR = item; item.Name = "Foot_R"
			elseif item.Name == "Ear_L_Base" then cores.EarL = item
			elseif item.Name == "Ear_R_Base" then cores.EarR = item end
		end
	end
	for _, name in ipairs({"Body", "Head", "ArmL", "ArmR", "Tail", "FootL", "FootR", "EarL", "EarR"}) do
		assert(cores[name], "Lumito rig missing " .. name)
	end
	local pivot = Instance.new("Part")
	pivot.Name = "HeadPivot"
	pivot.Size = Vector3.one * 0.12 * scale
	pivot.CFrame = root.CFrame * CFrame.new(0, -0.55 * scale, 0)
	pivot.Transparency, pivot.Massless = 1, true
	pivot.CanCollide, pivot.CanTouch, pivot.CanQuery = false, false, false
	pivot.Anchored = true
	pivot.Parent = model
	local point = function(x, y, z) return root.CFrame * CFrame.new(x * scale, y * scale, z * scale) end
	motor(root, cores.Body, point(0, -0.96, 0), "BodyJoint")
	motor(cores.Body, pivot, point(0, -0.55, 0), "HeadLookJoint")
	motor(pivot, cores.Head, point(0, -0.55, 0), "HeadJoint")
	motor(cores.Body, cores.ArmL, point(0.60, -0.70, -0.05), "ArmLJoint")
	motor(cores.Body, cores.ArmR, point(-0.60, -0.70, -0.05), "ArmRJoint")
	motor(cores.Body, cores.Tail, point(0, -1.05, 0.50), "TailJoint")
	motor(root, cores.FootL, cores.FootL.CFrame, "FootLJoint")
	motor(root, cores.FootR, cores.FootR.CFrame, "FootRJoint")
	motor(cores.Head, cores.EarL, point(0.45, 0.98, -0.10), "EarLJoint")
	motor(cores.Head, cores.EarR, point(-0.97, 0.60, -0.35), "EarRJoint")
	for _, item in ipairs(model:GetChildren()) do
		if item:IsA("BasePart") and item ~= root and item.Name ~= "Corpo" and item ~= pivot then
			local core = cores[group(item)]
			if core and core ~= item then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "VisualAttachment"
				weld.Part0, weld.Part1 = core, item
				weld.Parent = core
			elseif not core then
				-- Unknown pieces stay fixed to the root until mapped explicitly.
				local weld = Instance.new("WeldConstraint")
				weld.Name = "UnmappedAttachment"
				weld.Part0, weld.Part1 = root, item
				weld.Parent = root
				warn("Lumito rig unmapped art: " .. item.Name)
			end
		end
	end
	for _, item in ipairs(model:GetChildren()) do
		if item:IsA("BasePart") and item ~= root and item.Name ~= "Corpo" then
			item.Anchored, item.Massless = false, true
		end
	end
	local controller = Instance.new("AnimationController")
	controller.Name = "AnimationController"
	controller.Parent = model
	local animator = Instance.new("Animator")
	animator.Parent = controller
	return model
end

return Builder
