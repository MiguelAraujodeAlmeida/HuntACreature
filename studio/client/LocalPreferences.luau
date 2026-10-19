-- Cosmetic preferences only. Never remove replicated creatures or alter income.
local Audio = require(script.Parent.AudioFeedback)
local Preferences = {}
Preferences.__index = Preferences
local function isBaseVisual(object)
	local folder = object:FindFirstAncestor("CriaturasInstaladas")
	return folder and folder:FindFirstAncestor("Bases") ~= nil
end
function Preferences.new(gui, roots)
	local self = setmetatable({ hidden = false, muted = false, sounds = {}, parts = {}, connections = {} }, Preferences)
	local function observe(object)
		if object:IsA("Sound") and not self.sounds[object] then
			local state = { volume = object.Volume }
			self.sounds[object] = state
			state.changed = object:GetPropertyChangedSignal("Volume"):Connect(function()
				if not state.writing and not (self.muted and object.Volume == 0) then
					state.volume = object.Volume
					if self.muted and object.Volume ~= 0 then
						state.writing = true
						object.Volume = 0
						state.writing = false
					end
				end
			end)
			state.removed = object.Destroying:Connect(function()
				state.changed:Disconnect()
				state.removed:Disconnect()
				self.sounds[object] = nil
			end)
			if self.muted then
				state.writing = true
				object.Volume = 0
				state.writing = false
			end
		elseif object:IsA("BasePart") and isBaseVisual(object) then
			if self.parts[object] == nil then
				self.parts[object] = object.LocalTransparencyModifier
			end
			object.LocalTransparencyModifier = self.hidden and 1 or self.parts[object]
		end
	end
	for _, root in ipairs(roots or { workspace, game:GetService("SoundService") }) do
		table.insert(self.connections, root.DescendantAdded:Connect(observe))
		table.insert(
			self.connections,
			root.DescendantRemoving:Connect(function(object)
				if self.parts[object] ~= nil then
					object.LocalTransparencyModifier = self.parts[object]
					self.parts[object] = nil
				end
			end)
		)
		for _, object in ipairs(root:GetDescendants()) do
			observe(object)
		end
	end
	gui.Destroying:Connect(function()
		for _, connection in ipairs(self.connections) do
			connection:Disconnect()
		end
		for sound, state in pairs(self.sounds) do
			state.changed:Disconnect()
			state.removed:Disconnect()
			if sound.Parent then
				sound.Volume = state.volume
			end
		end
		for part, value in pairs(self.parts) do
			if part.Parent then
				part.LocalTransparencyModifier = value
			end
		end
	end)
	return self
end
function Preferences:Apply(settings)
	settings = settings or {}
	local muted, hidden = settings.Sound == false, settings.BaseCreatures == false
	Audio.SetMuted(muted)
	if muted ~= self.muted then
		self.muted = muted
		for sound, state in pairs(self.sounds) do
			if sound.Parent then
				state.writing = true
				sound.Volume = muted and 0 or state.volume
				state.writing = false
			end
		end
	end
	if hidden ~= self.hidden then
		self.hidden = hidden
		for part, value in pairs(self.parts) do
			if part.Parent then
				part.LocalTransparencyModifier = hidden and 1 or value
			end
		end
	end
end
return Preferences
