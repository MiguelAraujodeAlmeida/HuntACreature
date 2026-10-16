-- Barra de ferramenta v4. Usa o Tool real; não duplica inventário no cliente.
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local Config = require(game.ReplicatedStorage.HACShared.CaptureConfig)
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local Slot = {}
Slot.__index = Slot
function Slot.new(player, parent, isBusy)
	local self = setmetatable({ connections = {} }, Slot)
	self.Skin = Button.new(
		parent,
		{
			name = "LacoEquipado",
			text = "Laço",
			icon = W.Style.Icons.Lasso,
			textSize = 20,
			size = UDim2.fromOffset(88, 88),
			position = UDim2.new(0.5, 0, 1, -12),
		}
	)
	self.Root = self.Skin.Root
	self.Root.AnchorPoint = Vector2.new(0.5, 1)
	W.text(self.Root, "Atalho", "1", UDim2.fromOffset(23, 23), UDim2.fromOffset(1, 0), 16).Visible =
		not UIS.TouchEnabled
	local function toggle()
		if isBusy() then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		local equipped = character:FindFirstChildOfClass("Tool")
		if equipped and Config.Lassos[equipped.Name] then
			humanoid:UnequipTools()
			return
		end
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, tool in ipairs(backpack:GetChildren()) do
				if tool:IsA("Tool") and Config.Lassos[tool.Name] then
					humanoid:EquipTool(tool)
					return
				end
			end
		end
	end
	table.insert(self.connections, self.Root.Activated:Connect(toggle))
	table.insert(
		self.connections,
		UIS.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.One then
				toggle()
			end
		end)
	)
	local previous = {}
	for _, kind in ipairs({ Enum.CoreGuiType.Backpack, Enum.CoreGuiType.PlayerList }) do
		previous[kind] = StarterGui:GetCoreGuiEnabled(kind)
		StarterGui:SetCoreGuiEnabled(kind, false)
	end
	self.Root.Destroying:Connect(function()
		for _, c in ipairs(self.connections) do
			c:Disconnect()
		end
		for kind, value in pairs(previous) do
			StarterGui:SetCoreGuiEnabled(kind, value)
		end
	end)
	return self
end
function Slot:SetEquipped(value)
	self.Skin:SetSelected(value)
	self.Skin:SetText(value and "Em uso" or "Laço")
end
return Slot
