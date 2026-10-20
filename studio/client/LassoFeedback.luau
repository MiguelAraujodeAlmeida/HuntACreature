-- Feedback local de mira: contorno elegível, alcance previsto e giro durante carga.
local Aim = require(game.ReplicatedStorage.HACShared.LassoAim)
local Visuals = require(game.ReplicatedStorage.HACShared.LassoVisuals)
local Config = require(game.ReplicatedStorage.HACShared.CaptureConfig)
local Gameplay = require(game.ReplicatedStorage.HACShared.GameplayConfig)
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
	self.lastState = nil
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
	local range = Aim.Range(lasso, power)
	local resolved = Aim.Resolve(origin, ray, range, Aim.Params(exclusions), Config.AimLimit)
	local aimed = resolved.hit and Aim.Creature(resolved.hit.Instance, wild)
	local camera = workspace.CurrentCamera
	local cursor = camera and camera:WorldToViewportPoint(ray.origin + ray.direction * 20)
	local target, nearest = aimed, math.huge
	if not target and camera and cursor then
		for _, creature in ipairs(wild:GetChildren()) do
			if creature:IsA("Model") and creature.PrimaryPart then
				local screen, visible = camera:WorldToViewportPoint(creature.PrimaryPart.Position)
				local pixels = (Vector2.new(screen.X, screen.Y) - Vector2.new(cursor.X, cursor.Y)).Magnitude
				if visible and pixels < 82 and pixels < nearest then
					target, nearest = creature, pixels
				end
			end
		end
	end
	local detected = target
	if not target and self.lastTarget and self.lastTarget.Parent and os.clock() - (self.focusTime or 0) < 0.12 then
		target = self.lastTarget
	end
	local state
	if target and target.PrimaryPart then
		local distance = (target.PrimaryPart.Position - origin).Magnitude
		local busy = target:GetAttribute("BusyUserId")
		local locked = (self.player:GetAttribute("Forca") or 0) < Gameplay.MinimumStrength(target:GetAttribute("Species"))
		local obstruction = workspace:Raycast(origin, target.PrimaryPart.Position - origin, Aim.Params(exclusions))
		local blocked = obstruction and Aim.Creature(obstruction.Instance, wild) ~= target
		state = busy and "busy" or locked and "locked" or distance > range + Config.LoopRadius and "far"
			or blocked and "blocked" or aimed == target and "aimed" or "near"
		if detected then self.focusTime = os.clock() end
	end
	self.Highlight.Adornee = target
	self.Highlight.Enabled = target ~= nil
	local palette = {
		far = Color3.fromRGB(171, 195, 204), near = Color3.fromRGB(72, 221, 219),
		aimed = target and target:GetAttribute("Golden") and Color3.fromRGB(255, 211, 35) or Color3.fromRGB(91, 255, 195),
		blocked = Color3.fromRGB(255, 174, 90), busy = Color3.fromRGB(187, 148, 222),
		locked = Color3.fromRGB(255, 133, 116),
	}
	self.Highlight.OutlineColor = palette[state] or palette.near
	self.Highlight.FillColor = palette[state] or palette.near
	self.Highlight.FillTransparency = state == "aimed" and 0.84 or state == "busy" and 0.9
		or state == "blocked" and 0.95 or 1
	local baseTransparency = state == "aimed" and 0.04 or state == "near" and 0.35
		or state == "blocked" and 0.55 or state == "busy" and 0.48 or 0.7
	self.Highlight.OutlineTransparency = baseTransparency + (state == "aimed" and (math.sin(os.clock() * 3) + 1) * 0.035 or 0)
	if target and state == "aimed" and (target ~= self.lastTarget or self.lastState ~= "aimed") then
		Visuals.Burst(self.Folder, resolved.endpoint, Color3.fromRGB(91, 255, 206), 4)
	end
	self.lastTarget = target
	self.lastState = state
	self.Marker.Color = palette[state] or Color3.fromRGB(255, 216, 73)
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
	return range
end
function Feedback:Destroy()
	self:SetToolHidden(false)
	self:StopSpin()
	self.Folder:Destroy()
end
return Feedback
