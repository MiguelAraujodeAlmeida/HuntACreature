-- Objetos de acesso. Idempotente para visualizar em Edit e reutilizar em runtime.
local Stations = {}
local function part(parent, name, size, cf, color)
	local p = parent:FindFirstChild(name) or Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Anchored, p.CanCollide, p.CanTouch = true, false, false
	p.CanQuery = true
	p.Material, p.Parent = Enum.Material.SmoothPlastic, parent
	return p
end
local function board(parent, name, position, forward, ids, size)
	local cf = CFrame.lookAt(position, position + forward)
	local p = part(parent, name, size, cf, Color3.fromRGB(13, 28, 40))
	p:SetAttribute("UpgradeIds", ids)
	part(
		parent,
		name .. "Poste",
		Vector3.new(0.4, 3, 0.4),
		cf * CFrame.new(0, -size.Y / 2 - 1.2, 0.2),
		Color3.fromRGB(103, 67, 40)
	)
	return p
end
function Stations.Ensure(world)
	for _, base in ipairs(world.Hub.Bases:GetChildren()) do
		local folder = base:FindFirstChild("PlacasMelhorias") or Instance.new("Folder")
		folder.Name, folder.Parent = "PlacasMelhorias", base
		local platform = base.Plataforma
		local direction = Vector3.new(0, 0, platform.Position.Z < 0 and 1 or -1)
		local front = platform.Position + direction * (platform.Size.Z / 2 + 0.6) + Vector3.new(0, 3.8, 0)
		board(folder, "Base", front, direction, "Base", Vector3.new(5.6, 5.6, 0.35))
		board(folder, "Velocidade", front + platform.CFrame.RightVector * 6.2, direction,
			"Velocidade", Vector3.new(5.6, 5.6, 0.35))
		local train = base.Esteira.Position + Vector3.new(-4, 3.2, 0)
		board(folder, "Treino", train, direction, "Treino,Multiplicador", Vector3.new(5.6, 5.6, 0.35))
		-- Os acessos antigos deixariam duas formas concorrentes de fazer a mesma ação.
		for _, v in ipairs(base:GetDescendants()) do
			if
				v:IsA("ProximityPrompt") and (v.Name == "Depositar" or v.Name == "Treinar" or v.Name:match("^Melhorar"))
			then
				v.Enabled = false
			end
		end
	end
	local seller =
		part(world.Hub, "VendaDeCriaturas", Vector3.new(6, 3, 3), CFrame.new(-8, 5.7, 9), Color3.fromRGB(221, 154, 43))
	seller.CanCollide = true
	part(
		world.Hub,
		"BalcaoVenda",
		Vector3.new(6.6, 0.35, 3.6),
		seller.CFrame * CFrame.new(0, 1.65, 0),
		Color3.fromRGB(95, 58, 34)
	)
	local prompt = seller:FindFirstChild("Vender") or Instance.new("ProximityPrompt")
	prompt.Name, prompt.ActionText, prompt.ObjectText = "Vender", "Sell", "Creature Market"
	prompt.MaxActivationDistance, prompt.HoldDuration, prompt.Parent = 12, 0, seller
	prompt.Enabled, prompt.RequiresLineOfSight, prompt.ClickablePrompt = true, false, true
	if not seller:FindFirstChild("Letreiro") then
		local gui = Instance.new("BillboardGui")
		gui.Name, gui.Size, gui.StudsOffset, gui.AlwaysOnTop, gui.Parent =
			"Letreiro", UDim2.fromOffset(230, 45), Vector3.new(0, 3, 0), true, seller
		local label = Instance.new("TextLabel")
		label.Size, label.BackgroundTransparency, label.Text = UDim2.fromScale(1, 1), 1, "CREATURE MARKET"
		label.Font, label.TextSize, label.TextColor3, label.TextStrokeTransparency, label.Parent =
			Enum.Font.FredokaOne, 23, Color3.new(1, 1, 1), 0, gui
	end
	return seller
end
function Stations.FindBoard(base, id)
	local folder = base and base:FindFirstChild("PlacasMelhorias")
	if not folder then
		return
	end
	for _, p in ipairs(folder:GetChildren()) do
		local ids = p:GetAttribute("UpgradeIds")
		if ids then
			for key in ids:gmatch("[^,]+") do
				if key == id then
					return p
				end
			end
		end
	end
end
return Stations
