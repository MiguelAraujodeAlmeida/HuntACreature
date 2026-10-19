-- Seleção vem do Tool equipado; sem teclas fixas por tipo de consumível.
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Inventory = {}
function Inventory.new(player, ui)
	local connections, toolConnections, containers = {}, {}, {}
	local function equipped()
		local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
		return tool, tool and tool:GetAttribute("HACItemId")
	end
	local function update()
		local _, id = equipped()
		ui.selected = id and C.Items[id] and id ~= "Pocao" and id or nil
		ui.activeItem = id
	end
	local function watch(tool)
		if not tool:IsA("Tool") or toolConnections[tool] then
			return
		end
		toolConnections[tool] = tool.Activated:Connect(function()
			local current, id = equipped()
			if tool == current and id == "Pocao" then
				ui:UsePotion()
			end
		end)
		tool.Destroying:Once(function()
			if toolConnections[tool] then
				toolConnections[tool]:Disconnect()
				toolConnections[tool] = nil
			end
		end)
	end
	local function bind(container)
		if containers[container] then
			return
		end
		containers[container] = true
		for _, tool in ipairs(container:GetChildren()) do
			watch(tool)
		end
		table.insert(
			connections,
			container.ChildAdded:Connect(function(tool)
				watch(tool)
				update()
			end)
		)
		table.insert(connections, container.ChildRemoved:Connect(update))
	end
	bind(player:WaitForChild("Backpack"))
	local function characterAdded(character)
		bind(character)
		local backpack = player:WaitForChild("Backpack")
		bind(backpack)
		update()
	end
	if player.Character then
		bind(player.Character)
	end
	table.insert(connections, player.CharacterAdded:Connect(characterAdded))
	update()
	ui.hud.Gui.Destroying:Once(function()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		for _, connection in pairs(toolConnections) do
			connection:Disconnect()
		end
	end)
end
return Inventory
