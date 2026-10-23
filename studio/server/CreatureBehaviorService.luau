-- Ciclo de vida das criaturas selvagens. Novas espécies escolhem perfil/comportamento.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Profiles = require(script.Parent.CreatureProfiles)
local Behaviors = { Lumito = require(script.Parent.LumitoBehavior), Chicken = require(script.Parent.LumitoBehavior) }
local Service = {}
Service.__index = Service

function Service.new(options)
	local self = setmetatable({ agents = {}, actors = {}, clock = 0, actorClock = 0 }, Service)
	self.ground = options.ground
	self.wildFolder = options.wildFolder
	self.effectsFolder = options.effectsFolder
	self.connection = RunService.Heartbeat:Connect(function(dt)
		self.clock += dt
		if self.clock < 0.05 then return end
		local step = math.min(self.clock, 0.1)
		self.clock = 0
		self.actorClock -= step
		if self.actorClock <= 0 then
			self.actorClock = 0.2
			table.clear(self.actors)
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and humanoid and humanoid.Health > 0 then
					table.insert(self.actors, { character = character, root = root, humanoid = humanoid })
				end
			end
		end
		for model, agent in pairs(self.agents) do
			if model.Parent ~= self.wildFolder or not model.PrimaryPart then
				self.agents[model] = nil
			else
				agent:Step(step)
			end
		end
	end)
	return self
end

function Service:Add(model, species)
	local profile = assert(Profiles[species], "Espécie sem perfil: " .. species)
	local behavior = assert(Behaviors[profile.Behavior], "Comportamento não registrado")
	model:SetAttribute("Species", species)
	self.agents[model] = behavior.new(model, profile, self)
end

function Service:Destroy()
	self.connection:Disconnect()
	table.clear(self.agents)
	table.clear(self.actors)
end

return Service
