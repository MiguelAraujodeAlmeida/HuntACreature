-- Projeção do perfil em Tools reais; a ordenação pertence ao inventário nativo.
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Inventory = {}
function Inventory.Sync(player, profile)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local found = {}
	for _, container in ipairs({ backpack, player.Character }) do
		for _, tool in ipairs(container:GetChildren()) do
			local id = tool:IsA("Tool") and tool:GetAttribute("HACItemId")
			if id then
				if found[id] or not C.Items[id] or (profile.items[id] or 0) <= 0 then
					tool:Destroy()
				else
					found[id] = tool
				end
			end
		end
	end
	for _, id in ipairs(C.OrderedIds(C.Items, C.ItemOrder)) do
		local def, quantity = C.Items[id], profile.items[id] or 0
		if not def.Permanent and quantity > 0 then
			local tool = found[id]
			if not tool then
				tool = Instance.new("Tool")
				tool.RequiresHandle, tool.CanBeDropped = false, false
				tool:SetAttribute("HACItemId", id)
				tool.Parent = backpack
			end
			tool.Name, tool.ToolTip = def.Name .. " ×" .. quantity, def.Name
			tool:SetAttribute("Quantity", quantity)
		end
	end
end
return Inventory
