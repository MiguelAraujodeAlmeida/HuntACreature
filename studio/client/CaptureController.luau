-- Entrada do jogador. O servidor é a única autoridade sobre carga e acerto.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Config = require(game:GetService("ReplicatedStorage").HACShared.CaptureConfig)

local Feedback = require(script.Parent.LassoFeedback)
local Aim = require(game.ReplicatedStorage.HACShared.LassoAim)
local Audio = require(script.Parent.AudioFeedback)

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
	self.feedback = Feedback.new(player)
	self.flying = false
	self.readyAt = 0

	local function attachCharacter(character)
		ContextActionService:UnbindAction("HACCaptureHold")
		self:_cancelCharge()
		self.capturing = false
		self.holding = false
		self.flying = false
		self.feedback:Hide()
		local function update()
			local tool = character:FindFirstChildOfClass("Tool")
			self.lasso = tool and Config.Lassos[tool.Name] or nil
			self.equipped = self.lasso ~= nil
			self.hud:SetEquipped(self.equipped)
			self.hud.Reticle.Visible = self.equipped and UserInputService.TouchEnabled and not self.capturing
			if not self.equipped then
				self:_cancelCharge()
			end
		end
		character.ChildAdded:Connect(update)
		character.ChildRemoved:Connect(update)
		update()
	end
	player.CharacterAdded:Connect(attachCharacter)
	if player.Character then
		attachCharacter(player.Character)
	end

	hud.ThrowButton.InputBegan:Connect(function(input)
		if isPointer(input) then
			self:_startCharge("button", input)
		end
	end)
	hud.ThrowButton.InputEnded:Connect(function(input)
		if input == self.chargeInput then
			self:_releaseCharge()
		end
	end)
	hud.HoldButton.InputBegan:Connect(function(input)
		if isPointer(input) and self.capturing then
			self.holdInput = input
			self:_setHolding(true)
		end
	end)
	hud.HoldButton.InputEnded:Connect(function(input)
		if input == self.holdInput then
			self:_setHolding(false)
			self.holdInput = nil
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if self.capturing then
			if not processed and (input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA) then
				self:_setHolding(true)
			end
			return
		end
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:_startCharge("mouse", input)
		elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
			self:_startCharge("center", input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if self.capturing then
			if
				input.KeyCode == Enum.KeyCode.Space
				or input.KeyCode == Enum.KeyCode.ButtonA
				or input == self.holdInput
			then
				self:_setHolding(false)
				self.holdInput = nil
			end
			return
		end
		if input == self.chargeInput then
			self:_releaseCharge()
		end
	end)
	self.renderConnection = RunService.RenderStepped:Connect(function()
		if self.hud.sheetKind and self.charging then
			self:_cancelCharge()
		end
		if
			not self.equipped
			or self.capturing
			or self.flying
			or self.hud.sheetKind
			or self.player:GetAttribute("Treinando")
			or self.hud.Collection and self.hud.Collection.selected
		then
			self.feedback:Hide(self.flying)
			return
		end
		local power = self.charging and math.clamp((os.clock() - self.chargeStarted) / self.lasso.ChargeSeconds, 0, 1)
			or 1
		local inputType = UserInputService:GetLastInputType()
		local center = self.charging and self.chargeMode ~= "mouse"
			or not self.charging and (UserInputService.TouchEnabled or inputType.Name:find("Gamepad") ~= nil)
		self.feedback:Update(self:_aimRay(center), self.lasso, power, self.charging)
		if self.charging then
			self.hud:SetCharging(power, Aim.Range(self.lasso, power), self.lasso.MaximumRange)
		end
	end)
	hud.Gui.Destroying:Connect(function()
		ContextActionService:UnbindAction("HACCaptureHold")
		self.renderConnection:Disconnect()
		self.feedback:Destroy()
	end)
	UserInputService.WindowFocusReleased:Connect(function()
		self:_cancelCharge()
		self:_setHolding(false)
		self.holdInput = nil
	end)

	return self
end

function Controller:_aimRay(center)
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local screenPoint
	if center then
		screenPoint = camera.ViewportSize / 2
	else
		-- GetMouseLocation e ViewportPointToRay usam as mesmas coordenadas.
		screenPoint = UserInputService:GetMouseLocation()
	end
	local ray = camera:ViewportPointToRay(screenPoint.X, screenPoint.Y)
	return { origin = ray.Origin, direction = ray.Direction }
end

function Controller:_startCharge(mode, input)
	if
		self.hud.Collection
		and self.hud.Collection.selected
		and not self.hud.sheetKind
		and not self.capturing
		and not self.flying
		and not self.player:GetAttribute("Treinando")
	then
		self.hud.Collection:Place(self:_aimRay(mode ~= "mouse"))
		return
	end
	if
		self.charging
		or self.capturing
		or self.flying
		or os.clock() < self.readyAt
		or not self.equipped
		or self.hud.sheetKind
		or self.player:GetAttribute("Treinando")
		or self.player:GetAttribute("ProfileReady") ~= true
	then
		return
	end
	self.charging = true
	self.chargeMode = mode
	self.chargeInput = input
	self.chargeStarted = os.clock()
	self.remote:FireServer("ChargeStart")
	self.hud:SetCharging(0)
end

function Controller:_releaseCharge()
	if not self.charging then
		return
	end
	local aim = self:_aimRay(self.chargeMode ~= "mouse")
	local power = math.clamp((os.clock() - self.chargeStarted) / self.lasso.ChargeSeconds, 0, 1)
	self.charging = false
	self.chargeInput = nil
	self.chargeMode = nil
	if aim then
		self.flying = true
		self.feedback:Hide(true)
		self.remote:FireServer("Throw", aim)
		Audio.StopCharge()
		Audio.Play("Throw", 0.9 + power * 0.25)
		self.hud:ThrowLaunched()
	else
		self.remote:FireServer("ChargeCancel")
	end
end

function Controller:_cancelCharge()
	if not self.charging then
		return
	end
	self.charging = false
	self.chargeInput = nil
	self.chargeMode = nil
	self.remote:FireServer("ChargeCancel")
	self.hud:ResetThrow()
end

function Controller:_setHolding(value)
	if not self.capturing or self.holding == value then
		return
	end
	self.holding = value
	self.remote:FireServer("Hold", value)
	self.hud:SetHolding(value)
end

function Controller:HandleEvent(action, a, b, c)
	if action == "ChargeReady" then
		return
	elseif action == "ChargeDenied" then
		self.flying = false
		self.charging = false
		self.chargeInput = nil
		self.chargeMode = nil
		self.hud:ResetThrow()
		if a then
			self.hud:Notice(a)
		end
	elseif action == "ThrowReady" then
		self.flying = false
		self.readyAt = os.clock() + (a or 0)
		self.hud:ResetThrow()
	elseif action == "ThrowLaunched" then
		self.hud:ThrowLaunched()
	elseif action == "ThrowMiss" then
		Audio.Play("Return", a == "obstacle" and 0.82 or a == "rejected" and 0.7 or 1.1)
		self.hud:ResetThrow()
		if a == "rejected" and b and (b:find("Bag full", 1, true) or b:find("Requires", 1, true)) then
			self.hud:Notice(b)
		end
	elseif action == "CaptureStart" then
		if self.hud.Collection then
			self.hud.Collection.selected = nil
		end
		self.flying = false
		self.feedback:Hide()
		self.charging = false
		self.chargeInput = nil
		self.capturing = true
		self.holding = false
		self.hud:StartCapture(a, b)
		ContextActionService:BindActionAtPriority("HACCaptureHold", function(_, state)
			self:_setHolding(state == Enum.UserInputState.Begin)
			return Enum.ContextActionResult.Sink
		end, false, 3000, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	elseif action == "CaptureState" then
		self.hud:CaptureState(a)
	elseif action == "CaptureEnd" then
		ContextActionService:UnbindAction("HACCaptureHold")
		self.flying = false
		self.capturing = false
		self.holding = false
		self.holdInput = nil
		self.hud:EndCapture(a, b)
		self.hud.Reticle.Visible = self.equipped and UserInputService.TouchEnabled
	elseif action == "Reward" then
		self.hud:Reward(a)
	elseif action == "Notice" then
		self.hud:Notice(a)
	end
end

return Controller
