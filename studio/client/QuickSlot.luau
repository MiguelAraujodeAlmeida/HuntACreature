-- Reserva de layout; mochila, atalhos e reordenação pertencem ao Roblox.
local StarterGui = game:GetService("StarterGui")
local Slot = {}
function Slot.new(_, parent)
	local root = Instance.new("Frame")
	root.Name, root.Visible, root.Parent = "ReservaInventarioNativo", false, parent
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	return setmetatable({ Root = root }, { __index = Slot })
end
function Slot:SetEquipped() end
return Slot
