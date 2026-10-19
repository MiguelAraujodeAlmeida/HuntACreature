-- Feedback local de mira: contorno elegível, alcance previsto e giro durante carga.
local Aim = require(game.ReplicatedStorage.HACShared.LassoAim)
local Visuals = require(game.ReplicatedStorage.HACShared.LassoVisuals)
local Config = require(game.ReplicatedStorage.HACShared.CaptureConfig)
local Feedback = {}
Feedback.__index = Feedback
function Feedback.new(player)
	local self = setmetatable({ player = player }, Feedback)
	self.Folder = Instance.new("Folder")
	self.Folder.Name = "HACLassoFeedback"
	self.Folder.Parent = workspace
	self.Highlight = Instance.new("Highlight")
	self.Highlight.Name = "AlvoNoAlcance"
	self.Highlight.FillTransparency = 1
	self.Highlight.OutlineTransparency = 0.08
	self.Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	self.Highlight.Enabled = false
	self.Highlight.Parent = self.Folder
	local marker = Instance.new("Part")
	marker.Name = "LimiteDoArremesso"
	marker.Shape = Enum.PartType.Ball
	marker.Size = Vector3.new(0.42, 0.42, 0.42)
	marker.Anchored = true
	marker.Material = Enum.Material.Neon
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.CastShadow = false
	marker.Transparency = 1
	marker.Parent = self.Folder
	self.Marker = marker
	return self
end
function Feedback:StopSpin()
	if self.loop then
		Visuals.CleanupLine(self.line)
		self.loop:Destroy()
		self.loop = nil
		self.line = nil
	end
end
function Feedback:SetToolHidden(hidden)
	if not hidden then
		if self.hiddenParts then
			for part, value in pairs(self.hiddenParts) do
				if part.Parent then
					part.LocalTransparencyModifier = value
				end
			end
		end
		self.hiddenParts = nil
		return
	end
	local tool = self.player.Character and self.player.Character:FindFirstChildOfClass("Tool")
	if not tool then
		return
	end
	self.hiddenParts = self.hiddenParts or {}
	for _, part in ipairs(tool:GetDescendants()) do
		if part:IsA("BasePart") then
			if self.hiddenParts[part] == nil then
				self.hiddenParts[part] = part.LocalTransparencyModifier
			end
			part.LocalTransparencyModifier = 1
		end
	end
end
function Feedback:Hide(hideTool)
	self:SetToolHidden(hideTool)
	self:StopSpin()
	self.Marker.Transparency = 1
	self.Highlight.Enabled = false
	self.Highlight.Adornee = nil
	self.lastTarget = nil
end
function Feedback:Update(ray, lasso, power, charging)
	local character = self.player.Character
	local origin = Aim.Origin(character)
	local world = workspace:FindFirstChild("HuntACreature")
	local wild = world and world:FindFirstChild("IlhaCaca") and world.IlhaCaca:FindFirstChild("CriaturasSelvagens")
	if not origin or not ray or not wild then
		self:Hide()
		return
	end
	local exclusions = { character, self.Folder }
	local effects = world:FindFirstChild("EfeitosDeCaca")
	if effects then
		table.insert(exclusions, effects)
	end
	local resolved = Aim.Resolve(origin, ray, Aim.Range(lasso, power), Aim.Params(exclusions), Config.AimLimit)
	local target = resolved.hit and Aim.Creature(resolved.hit.Instance, wild)
	if target and target:GetAttribute("BusyUserId") then
		target = nil
	end
	self.Highlight.Adornee = target
	self.Highlight.Enabled = target ~= nil
	self.Highlight.OutlineColor = target and target:GetAttribute("Golden") and Color3.fromRGB(255, 211, 35)
		or Color3.fromRGB(59, 245, 227)
	self.Highlight.OutlineTransparency = 0.08 + (math.sin(os.clock() * 5) + 1) * 0.04
	if target and target ~= self.lastTarget then
		Visuals.Burst(self.Folder, resolved.endpoint, Color3.fromRGB(91, 255, 206), 4)
	end
	self.lastTarget = target
	self.Marker.Color = target and Color3.fromRGB(71, 255, 164) or Color3.fromRGB(255, 216, 73)
	self.Marker.Position = resolved.endpoint
	self.Marker.Transparency = charging and 0.15 or 1
	if charging then
		if not self.loop then
			self.loop = Visuals.Loop(self.Folder)
			self.line = Visuals.Line(character, self.loop.PrimaryPart)
		end
		local hand = character:FindFirstChild("RightHand")
			or character:FindFirstChild("Right Arm")
			or character.HumanoidRootPart
		local center = hand.Position + Vector3.new(0, 1.1, 0)
		self.loop:PivotTo(
			CFrame.lookAt(center, center + resolved.direction) * CFrame.Angles(0, 0, os.clock() * (8 + power * 14))
		)
		if self.line then
			self.line.beam.Width0 = 0.1 + power * 0.06
			self.line.beam.Width1 = self.line.beam.Width0
		end
	else
		self:StopSpin()
	end
	self:SetToolHidden(charging)
	return Aim.Range(lasso, power)
end
function Feedback:Destroy()
	self:SetToolHidden(false)
	self:StopSpin()
	self.Folder:Destroy()
end
return Feedback

