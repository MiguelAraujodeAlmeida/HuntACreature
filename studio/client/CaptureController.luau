-- Entrada do jogador. O servidor é a única autoridade sobre carga e acerto.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Config = require(game:GetService("ReplicatedStorage").HACShared.CaptureConfig)

local Controller = {}
Controller.__index = Controller

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function Controller.new(player, remote, hud)
	local self = setmetatable({}, Controller)
	self.player = player
	self.remote = remote
	self.hud = hud
	self.equipped = false
	self.charging = false
	self.chargeInput = nil
	self.chargeMode = nil
	self.chargeStarted = 0
	self.capturing = false
	self.holding = false
	self.holdInput = nil
	self.lasso = nil

	local function attachCharacter(character)
		self:_cancelCharge()
		self.capturing = false
		self.holding = false
		local function update()
			local tool = character:FindFirstChildOfClass("Tool")
			self.lasso = tool and Config.Lassos[tool.Name] or nil
			self.equipped = self.lasso ~= nil
			self.hud:SetEquipped(self.equipped)
			self.hud.Reticle.Visible = self.equipped and UserInputService.TouchEnabled and not self.capturing
			if not self.equipped then self:_cancelCharge() end
		end
		character.ChildAdded:Connect(update)
		character.ChildRemoved:Connect(update)
		update()
	end
	player.CharacterAdded:Connect(attachCharacter)
	if player.Character then attachCharacter(player.Character) end

	hud.ThrowButton.InputBegan:Connect(function(input)
		if isPointer(input) then self:_startCharge("button", input) end
	end)
	hud.ThrowButton.InputEnded:Connect(function(input)
		if input == self.chargeInput then self:_releaseCharge() end
	end)
	hud.HoldButton.InputBegan:Connect(function(input)
		if isPointer(input) and self.capturing then
			self.holdInput = input
			self:_setHolding(true)
		end
	end)
	hud.HoldButton.InputEnded:Connect(function(input)
		if input == self.holdInput then self:_setHolding(false); self.holdInput = nil end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if self.capturing then
			if not processed and (input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA) then self:_setHolding(true) end
			return
		end
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:_startCharge("mouse", input)
		elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
			self:_startCharge("center", input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if self.capturing then
			if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA or input == self.holdInput then
				self:_setHolding(false)
				self.holdInput = nil
			end
			return
		end
		if input == self.chargeInput then self:_releaseCharge() end
	end)
	RunService.RenderStepped:Connect(function()
		if self.charging then
			local power = math.clamp((os.clock() - self.chargeStarted) / self.lasso.ChargeSeconds, 0, 1)
			self.hud:SetCharging(power)
		end
	end)
	return self
end

function Controller:_aimRay(center)
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	local screenPoint
	if center then
		screenPoint = camera.ViewportSize / 2
	else
		-- GetMouseLocation e ViewportPointToRay usam as mesmas coordenadas.
		screenPoint = UserInputService:GetMouseLocation()
	end
	local ray = camera:ViewportPointToRay(screenPoint.X, screenPoint.Y)
	return {origin = ray.Origin, direction = ray.Direction}
end

function Controller:_startCharge(mode, input)
	if self.charging or self.capturing or not self.equipped or self.player:GetAttribute("Treinando") then return end
	self.charging = true
	self.chargeMode = mode
	self.chargeInput = input
	self.chargeStarted = os.clock()
	self.remote:FireServer("ChargeStart")
	self.hud:SetCharging(0)
end

function Controller:_releaseCharge()
	if not self.charging then return end
	local aim = self:_aimRay(self.chargeMode ~= "mouse")
	self.charging = false
	self.chargeInput = nil
	self.chargeMode = nil
	if aim then
		self.remote:FireServer("Throw", aim)
		self.hud:ThrowLaunched()
	else
		self.remote:FireServer("ChargeCancel")
	end
end

function Controller:_cancelCharge()
	if not self.charging then return end
	self.charging = false
	self.chargeInput = nil
	self.chargeMode = nil
	self.remote:FireServer("ChargeCancel")
	self.hud:ResetThrow()
end

function Controller:_setHolding(value)
	if not self.capturing or self.holding == value then return end
	self.holding = value
	self.remote:FireServer("Hold", value)
	self.hud:SetHolding(value)
end

function Controller:HandleEvent(action, a, b, c)
	if action == "ChargeReady" then
		return
	elseif action == "ChargeDenied" then
		self.charging = false
		self.chargeInput = nil
		self.chargeMode = nil
		self.hud:ResetThrow()
		self.hud:Notice(a)
	elseif action == "ThrowLaunched" then
		self.hud:ThrowLaunched()
	elseif action == "ThrowMiss" then
		self.hud:ResetThrow()
		self.hud:Notice(a)
	elseif action == "CaptureStart" then
		self.charging = false
		self.chargeInput = nil
		self.capturing = true
		self.holding = false
		self.hud:StartCapture(a, b)
	elseif action == "CaptureState" then
		self.hud:CaptureState(a)
	elseif action == "CaptureEnd" then
		self.capturing = false
		self.holding = false
		self.holdInput = nil
		self.hud:EndCapture(a, b)
		self.hud.Reticle.Visible = self.equipped and UserInputService.TouchEnabled
	elseif action == "Reward" then
		self.hud:Reward(a, b)
	elseif action == "Notice" then
		self.hud:Notice(a)
	end
end

return Controller
