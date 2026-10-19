local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Placement = require(game.ReplicatedStorage.HACShared.ToolPlacement)
local Preview = {}
Preview.__index = Preview
function Preview.new(player)
	local part = Instance.new("Part")
	part.Name = "PreviaFerramenta"
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.Material, part.Transparency, part.CastShadow = Enum.Material.Neon, 1, false
	part.Parent = workspace
	return setmetatable({player = player, part = part}, Preview)
end
function Preview:Resolve(ray)
	local character = self.player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local world = workspace:FindFirstChild("HuntACreature")
	local island = world and world:FindFirstChild("IlhaCaca")
	local ground = island and island:FindFirstChild("Gramado")
	if not ray or not root or not ground then return nil, "Mire no chão perto de você." end
	local effects = world:FindFirstChild("EfeitosDeCaca")
	local wild = island:FindFirstChild("CriaturasSelvagens")
	local excluded = {character, self.part}
	if effects then table.insert(excluded, effects) end
	if wild then table.insert(excluded, wild) end
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, excluded
	local hit = workspace:Raycast(ray.origin, ray.direction * 150, params)
	if not hit then return nil, "Mire no chão perto de você." end
	local occupied = {}
	if effects then
		for _, part in ipairs(effects:GetChildren()) do
			if part:IsA("BasePart") and part:GetAttribute("HuntingTool") then table.insert(occupied, part) end
		end
	end
	local position, reason = Placement.Resolve(hit.Position, root.Position, ground, params, occupied)
	return position, reason, hit.Position
end
function Preview:Update(id, ray, unavailable)
	local position, reason, hit = self:Resolve(ray)
	local valid = position ~= nil and not unavailable
	if hit then
		local width = id == "Isca" and 1.2 or 3
		self.part.Size = Vector3.new(width, 0.12, width)
		self.part.Position = position or hit + Vector3.new(0, C.Placement.Height, 0)
		self.part.Color = valid and Color3.fromRGB(90, 235, 150) or Color3.fromRGB(255, 100, 90)
		self.part.Transparency = 0.4
	else self:Hide() end
	return unavailable or reason or "Local livre • clique / R2 / Posicionar"
end
function Preview:Hide() self.part.Transparency = 1 end
function Preview:Destroy() self.part:Destroy() end
return Preview
