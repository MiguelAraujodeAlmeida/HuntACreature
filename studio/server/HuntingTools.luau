local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Placement = require(game.ReplicatedStorage.HACShared.ToolPlacement)
local RunService = game:GetService("RunService")
local Tools = {}
Tools.__index = Tools
function Tools.new(options)
	local self = setmetatable({ options = options, objects = {}, cooldowns = {} }, Tools)
	self.connection = RunService.Heartbeat:Connect(function()
		self:Step()
	end)
	return self
end
function Tools:Use(player, id, position)
	local o, def = self.options, C.Items[id]
	local profile = o.profiles:Get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if
		not def
		or def.Permanent
		or not profile
		or not root
		or not humanoid
		or humanoid.Health <= 0
		or player:GetAttribute("Treinando")
	then
		return false, "Cannot use this now."
	end
	local held = character:FindFirstChildOfClass("Tool")
	if not held or held:GetAttribute("HACItemId") ~= id then
		return false, "Equip the tool first."
	end
	if (profile.items[id] or 0) <= 0 then
		return false, "You do not own this tool."
	end
	local cooldowns = self.cooldowns[player] or {}
	if (cooldowns[id] or 0) > os.clock() then
		return false, "Tool is on cooldown."
	end
	local session = o.capture.sessions[player]
	if id == "Pocao" then
		if not session then
			return false, "Use the potion during a capture."
		end
		if (session.potionUntil or 0) > os.clock() then
			return false, "Potion already active."
		end
	else
		if session or o.capture.projectiles[player] or o.capture.charges[player] then
			return false, "Finish the throw first."
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character, o.effects, o.wild }
		local occupied = {}
		for _, object in ipairs(self.objects) do
			table.insert(occupied, object.part)
		end
		local resolved, reason = Placement.Resolve(position, root.Position, o.ground, params, occupied)
		if not resolved then
			return false, reason
		end
		position = resolved
	end
	local accepted, message = o.profiles:Change(player, function(p)
		if (p.items[id] or 0) <= 0 then
			return false, "Tool unavailable."
		end
		p.items[id] -= 1
		return true
	end)
	if not accepted then
		return false, message
	end
	cooldowns[id] = os.clock() + def.Cooldown
	self.cooldowns[player] = cooldowns
	player:SetAttribute("Cooldown" .. id, workspace:GetServerTimeNow() + def.Cooldown)
	if id == "Pocao" then
		session.potionUntil = os.clock() + def.Duration
	else
		local part = Instance.new("Part")
		part.Name = id
		part.Size = id == "Isca" and Vector3.new(1.2, 0.35, 1.2) or Vector3.new(3, 0.3, 3)
		part.Color = id == "Isca" and Color3.fromRGB(255, 194, 75) or Color3.fromRGB(89, 230, 221)
		part.Material = Enum.Material.Neon
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part:SetAttribute("HuntingTool", id)
		part.Position, part.Parent = position, o.effects
		table.insert(
			self.objects,
			{ part = part, id = id, owner = player, expires = os.clock() + def.Duration, armed = os.clock() + 1 }
		)
	end
	return true
end
function Tools:Step()
	local now = os.clock()
	for i = #self.objects, 1, -1 do
		local object = self.objects[i]
		if not object.part.Parent or now >= object.expires then
			object.part:Destroy()
			table.remove(self.objects, i)
		elseif object.id == "Armadilha" and now >= object.armed then
			for model, agent in pairs(self.options.creatures.agents) do
				if
					not model:GetAttribute("BusyUserId")
					and (agent.position - object.part.Position).Magnitude < C.Items.Armadilha.Radius + agent.radius
				then
					model:SetAttribute("SlowedUntil", now + C.Items.Armadilha.EffectSeconds)
					object.expires = now
					object.part.Color = Color3.fromRGB(255, 255, 255)
					break
				end
			end
		end
	end
end
function Tools:Attractor(position, vision)
	local best, distance
	for _, object in ipairs(self.objects) do
		if object.id == "Isca" and object.part.Parent and object.expires > os.clock() then
			local delta = object.part.Position - position
			local d = delta.Magnitude
			if
				d < C.Items.Isca.Radius
				and (not distance or d < distance)
				and not workspace:Raycast(position, delta, vision)
			then
				best, distance = object.part.Position, d
			end
		end
	end
	return best
end
function Tools:RemovePlayer(player)
	self.cooldowns[player] = nil
	for i = #self.objects, 1, -1 do
		if self.objects[i].owner == player then
			self.objects[i].part:Destroy()
			table.remove(self.objects, i)
		end
	end
	for _, id in ipairs({ "Isca", "Armadilha", "Pocao" }) do
		player:SetAttribute("Cooldown" .. id, nil)
	end
end
return Tools
