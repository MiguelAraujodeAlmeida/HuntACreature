-- Articulates the imported Chicken template. The Root and capture volume never pose.
local Builder = {}

local function group(part)
	local name = part.Name
	if name == "Body" or name == "Breast" then return "Body" end
	if name == "Head" or name == "Beak" or name == "Wattle"
		or name:match("^Comb_") or name:match("^Eye_") or name:match("^Glint_") then return "Head" end
	if name == "Wing_L" then return "WingL" end
	if name == "Wing_R" then return "WingR" end
	if name:match("^Tail_Feather_") then return "Tail" end
	if name == "Foot_L" or name:match("^FootStud_L") or name:match("^Sole_L") or name:match("^Ankle_L") then return "FootL" end
	if name == "Foot_R" or name:match("^FootStud_R") or name:match("^Sole_R") or name:match("^Ankle_R") then return "FootR" end
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
	if model:FindFirstChild("ChickenHeadPivot") then return model end
	local root = assert(model:FindFirstChild("Root"), "Chicken rig needs Root")
	local scale = model:GetAttribute("CreatureScale") or 1
	local cores = {}
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			if part.Name == "Body" then cores.Body = part
			elseif part.Name == "Head" then cores.Head = part
			elseif part.Name == "Wing_L" then cores.WingL = part
			elseif part.Name == "Wing_R" then cores.WingR = part
			elseif part.Name == "Foot_L" then cores.FootL = part
			elseif part.Name == "Foot_R" then cores.FootR = part end
		end
	end
	for _, name in ipairs({"Body", "Head", "WingL", "WingR", "FootL", "FootR"}) do
		assert(cores[name], "Chicken rig missing " .. name)
	end
	local point = function(x, y, z) return root.CFrame * CFrame.new(x * scale, y * scale, z * scale) end
	local headPivot = Instance.new("Part")
	headPivot.Name = "ChickenHeadPivot"
	headPivot.Size = Vector3.one * 0.12 * scale
	headPivot.CFrame = point(0, -0.15, -0.08)
	headPivot.Transparency, headPivot.Massless = 1, true
	headPivot.CanCollide, headPivot.CanTouch, headPivot.CanQuery = false, false, false
	headPivot.Anchored = true
	headPivot.Parent = model
	local tailPivot = Instance.new("Part")
	tailPivot.Name = "ChickenTailPivot"
	tailPivot.Size = Vector3.one * 0.12 * scale
	tailPivot.CFrame = point(0, -0.66, 0.43)
	tailPivot.Transparency, tailPivot.Massless = 1, true
	tailPivot.CanCollide, tailPivot.CanTouch, tailPivot.CanQuery = false, false, false
	tailPivot.Anchored = true
	tailPivot.Parent = model
	motor(root, cores.Body, point(0, -1.07, 0), "ChickenBodyJoint")
	motor(cores.Body, headPivot, point(0, -0.15, -0.08), "ChickenHeadLookJoint")
	motor(headPivot, cores.Head, point(0, -0.15, -0.08), "ChickenHeadJoint")
	motor(cores.Body, cores.WingL, point(0.616, -0.43, 0.02), "ChickenWingLJoint")
	motor(cores.Body, cores.WingR, point(-0.616, -0.43, 0.02), "ChickenWingRJoint")
	motor(cores.Body, tailPivot, point(0, -0.66, 0.43), "ChickenTailJoint")
	motor(root, cores.FootL, cores.FootL.CFrame, "ChickenFootLJoint")
	motor(root, cores.FootR, cores.FootR.CFrame, "ChickenFootRJoint")
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= root and part.Name ~= "Corpo"
			and part ~= headPivot and part ~= tailPivot then
			local owner = ({Body = cores.Body, Head = cores.Head, WingL = cores.WingL,
				WingR = cores.WingR, Tail = tailPivot, FootL = cores.FootL, FootR = cores.FootR})[group(part)]
			if owner and owner ~= part then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "ChickenVisualAttachment"
				weld.Part0, weld.Part1 = owner, part
				weld.Parent = owner
			elseif not owner then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "ChickenUnmappedAttachment"
				weld.Part0, weld.Part1 = root, part
				weld.Parent = root
				warn("Chicken rig unmapped art: " .. part.Name)
			end
		end
	end
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= root and part.Name ~= "Corpo" then
			part.Anchored, part.Massless = false, true
		end
	end
	local controller = Instance.new("AnimationController")
	controller.Name = "AnimationController"
	controller.Parent = model
	Instance.new("Animator").Parent = controller
	return model
end

return Builder
