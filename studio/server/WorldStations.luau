-- Objetos de acesso. Idempotente para visualizar em Edit e reutilizar em runtime.
local Stations = {}
local part
local function interactionZone(parent, name, position, radius, color)
	local folder = parent:FindFirstChild(name) or Instance.new("Model")
	folder.Name, folder.Parent = name, parent
	local center = part(folder, "Center", Vector3.new(0.08, radius * 2, radius * 2),
		CFrame.new(position), color)
	center.Shape, center.Material, center.Transparency = Enum.PartType.Cylinder, Enum.Material.Neon, 0.72
	center.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	center.CanQuery = false
	center:SetAttribute("Radius", radius)
	for i = 1, 16 do
		local a = i * math.pi * 2 / 16
		local b = (i + 1) * math.pi * 2 / 16
		local p0 = position + Vector3.new(math.cos(a) * radius, 0.1, math.sin(a) * radius)
		local p1 = position + Vector3.new(math.cos(b) * radius, 0.1, math.sin(b) * radius)
		local segment = part(folder, "Rim" .. i, Vector3.new(0.16, 0.12, (p1 - p0).Magnitude),
			CFrame.lookAt((p0 + p1) / 2, p1), color)
		segment.Material, segment.CanQuery = Enum.Material.Neon, false
	end
	local oldLabel = center:FindFirstChild("ZoneLabel")
	if oldLabel then oldLabel:Destroy() end
	return center
end
Stations.Zone = interactionZone
part = function(parent, name, size, cf, color)
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
function Stations.Prepare(world)
	for _, base in ipairs(world.Hub.Bases:GetChildren()) do
		local platform = base.Plataforma
		local direction = Vector3.new(0, 0, platform.Position.Z < 0 and 1 or -1)
		local station = base:FindFirstChild("Esteira")
		if station then
			local destination = platform.Position - direction * (platform.Size.Z / 2 + 10)
			station.Position = Vector3.new(platform.Position.X + 4.2, 5.05, destination.Z)
			local annex = part(base, "TrainingAnnex", Vector3.new(10, 1, 25),
				CFrame.new(station.Position.X, 3.5, (platform.Position.Z + station.Position.Z) / 2 - direction.Z * 4),
				Color3.fromRGB(117, 222, 94))
			annex.TopSurface = Enum.SurfaceType.Studs
			local belt = base:FindFirstChild("FaixaEsteira")
			if belt then belt.Position = station.Position + Vector3.new(0, 0.29, 0) end
			local old = station:FindFirstChild("Treinar")
			if old then old:Destroy() end
		end
		local totem = base:FindFirstChild("Totem")
		if totem then totem:Destroy() end
		local marker = part(base, "OwnerMarker", Vector3.new(0.2, 0.2, 0.2),
			CFrame.new(platform.Position + Vector3.new(0, 10.5, 0)), Color3.new(1, 1, 1))
		marker.Transparency, marker.CanQuery = 1, false
		local gui = marker:FindFirstChild("OwnerBillboard") or Instance.new("BillboardGui")
		gui.Name, gui.Adornee, gui.Size = "OwnerBillboard", marker, UDim2.fromOffset(160, 118)
		gui.AlwaysOnTop, gui.MaxDistance, gui.Enabled, gui.Parent = true, 110, false, marker
		local portrait = gui:FindFirstChild("Portrait") or Instance.new("ImageLabel")
		portrait.Name, portrait.Size, portrait.Position = "Portrait", UDim2.fromOffset(70, 70), UDim2.fromOffset(45, 0)
		portrait.BackgroundTransparency, portrait.Parent = 1, gui
		local corner = portrait:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
		corner.CornerRadius, corner.Parent = UDim.new(1, 0), portrait
		local name = gui:FindFirstChild("OwnerName") or Instance.new("TextLabel")
		name.Name, name.Size, name.Position = "OwnerName", UDim2.fromOffset(160, 42), UDim2.fromOffset(0, 72)
		name.BackgroundTransparency, name.TextScaled, name.Font = 1, true, Enum.Font.FredokaOne
		name.TextColor3, name.TextStrokeTransparency, name.Parent = Color3.new(1, 1, 1), 0, gui
	end
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
		interactionZone(base, "TrainZone", base.Esteira.Position + Vector3.new(0, 0.36, 1.5), 4.5, Color3.fromRGB(70, 232, 255))
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
	local oldPrompt = seller:FindFirstChild("Vender")
	if oldPrompt then oldPrompt:Destroy() end
	interactionZone(world.Hub, "SellZone", seller.Position + Vector3.new(0, -1.55, 4.7), 4.5, Color3.fromRGB(78, 255, 156))
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
