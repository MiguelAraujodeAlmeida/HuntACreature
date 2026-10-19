-- Placas resilientes à chegada tardia de bases, peças e atributos no cliente.
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local RunService = game:GetService("RunService")
local Boards = {}
Boards.__index = Boards

local function number(value)
	return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
end

function Boards.new(player, ui, bases)
	local self = setmetatable({ player = player, ui = ui, panels = {}, bases = bases }, Boards)
	-- bases pode ser injetado para verificar replicação em uma árvore isolada.
	self:_sync()
	local elapsed = 0
	self.connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.2 then
			elapsed = 0
			self:_sync()
		end
	end)
	self.destroyConnection = ui.hud.Gui.Destroying:Once(function()
		self:Destroy()
	end)
	return self
end

function Boards:_canUse(panel)
	local character = self.player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return self.profile ~= nil
		and panel.base.Name == "Base" .. tostring(self.player:GetAttribute("BaseIndex"))
		and root ~= nil
		and (root.Position - panel.anchor.Position).Magnitude <= C.Boards.Distance
		and not self.ui.hud.sheetKind
		and not self.ui.controller.capturing
		and not self.ui.controller.flying
		and not self.ui.controller.charging
		and not self.player:GetAttribute("Treinando")
end

function Boards:_activate(panel, id)
	if not self:_canUse(panel) or os.clock() < (self.nextClick or 0) then
		return
	end
	if id ~= "Treinar" and not C.UpgradePreview(self.profile, id).cost then
		return
	end
	self.nextClick = os.clock() + 0.3
	if id == "Treinar" then
		self.ui.remote:FireServer("ToggleTraining")
	else
		self.ui:Send("Upgrade", id)
	end
end

function Boards:_mount(base, anchor, signature)
	local keys = string.split(signature, ",")
	for _, id in ipairs(keys) do
		if not C.Upgrades[id] then
			return -- Atributos incompletos serão examinados novamente no próximo passo.
		end
	end
	local panel = { base = base, anchor = anchor, signature = signature, faces = {} }
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Name, gui.Adornee, gui.Face = "HACUpgradeBoard_" .. face.Name, anchor, face
		gui.SizingMode, gui.PixelsPerStud = Enum.SurfaceGuiSizingMode.PixelsPerStud, 65
		gui.LightInfluence, gui.AlwaysOnTop, gui.Active, gui.MaxDistance = 0, false, true, 40
		gui.Enabled, gui.ResetOnSpawn = false, false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = self.player:FindFirstChildOfClass("PlayerGui")
		local view = { gui = gui, rows = {} }
		table.insert(panel.faces, view)
		local root = W.frame(gui, "Painel", UDim2.fromScale(1, 1), UDim2.new(), W.Style.UI.Ink, 12)
		W.stroke(root, W.Style.UI.Cyan, 3)
		local training = anchor.Name == "Treino"
		local rows = W.frame(root, "Melhorias", UDim2.new(1, 0, 1, training and -55 or 0), UDim2.new())
		if training then
			view.train = Button.new(root, {
				name = "Treinar",
				text = "TRAIN",
				color = W.Style.UI.Green,
				size = UDim2.new(1, -20, 0, 44),
				position = UDim2.new(0, 10, 1, -49),
				textSize = 23,
			})
			view.train.Root.Activated:Connect(function()
				self:_activate(panel, "Treinar")
			end)
		end
		for i, id in ipairs(keys) do
			local row = W.frame(rows, id, UDim2.new(1, -18, 1 / #keys, -12), UDim2.new(0, 9, (i - 1) / #keys, 6))
			local title = W.text(row, "Titulo", C.Upgrades[id].Name, UDim2.new(1, 0, 0, 26), UDim2.new(), 22)
			local value = W.text(
				row,
				"Beneficio",
				"Loading…",
				UDim2.new(1, 0, 0, 24),
				UDim2.fromOffset(0, 28),
				18,
				W.Style.UI.Green
			)
			local skin = Button.new(row, {
				name = "Comprar",
				text = "…",
				color = W.Style.UI.Red,
				textSize = 23,
				size = UDim2.new(1, -20, 0, 43),
				position = UDim2.new(0, 10, 1, -47),
			})
			skin.Root.Activated:Connect(function()
				self:_activate(panel, id)
			end)
			table.insert(view.rows, { id = id, title = title, value = value, skin = skin })
		end
	end
	self.panels[anchor] = panel
end

function Boards:_remove(anchor)
	local panel = self.panels[anchor]
	for _, view in ipairs(panel.faces) do
		view.gui:Destroy()
	end
	self.panels[anchor] = nil
end

function Boards:_refresh(panel)
	local canUse = self:_canUse(panel)
	local root = self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart")
	local visible = root ~= nil and (root.Position - panel.anchor.Position).Magnitude <= 40
	for _, view in ipairs(panel.faces) do
		-- Distância, treino e menus desabilitam ações, sem apagar o desenho da placa.
		view.gui.Enabled = visible
		if view.train then
			view.train.Root.Active, view.train.Root.Selectable = canUse, canUse
			view.train.caption.TextTransparency = canUse and 0 or 0.4
		end
		for _, row in ipairs(view.rows) do
			local preview = self.profile and C.UpgradePreview(self.profile, row.id)
			if preview then
				row.title.Text = C.Upgrades[row.id].Name .. " • Lv. " .. (preview.level + 1)
				local unit = row.id == "Treino" and " strength"
					or row.id == "Multiplicador" and "×"
					or row.id == "Velocidade" and " studs/s"
					or " slots"
				row.value.Text = number(preview.current)
					.. (preview.next and " → " .. number(preview.next) or "")
					.. unit
				row.skin:SetText(preview.cost and "$ " .. preview.cost or "MAX")
			end
			local enabled = canUse and preview ~= nil and preview.cost ~= nil
			row.skin.Root.Active, row.skin.Root.Selectable = enabled, enabled
			row.skin.caption.TextTransparency = enabled and self.profile.gold >= preview.cost and 0 or 0.4
		end
	end
end

function Boards:_sync()
	if self.dead then
		return
	end
	local world = workspace:FindFirstChild("HuntACreature")
	local hub = world and world:FindFirstChild("Hub")
	local bases = self.bases or hub and hub:FindFirstChild("Bases")
	local base = bases and bases:FindFirstChild("Base" .. tostring(self.player:GetAttribute("BaseIndex")))
	local folder = base and base:FindFirstChild("PlacasMelhorias")
	local guiReady = self.player:FindFirstChildOfClass("PlayerGui") ~= nil
	for anchor, panel in pairs(self.panels) do
		if not folder or anchor.Parent ~= folder or anchor:GetAttribute("UpgradeIds") ~= panel.signature then
			self:_remove(anchor)
		end
	end
	if folder and guiReady then
		for _, anchor in ipairs(folder:GetChildren()) do
			local ids = anchor:IsA("BasePart") and anchor:GetAttribute("UpgradeIds")
			if type(ids) == "string" and ids ~= "" and not self.panels[anchor] then
				self:_mount(base, anchor, ids)
			end
		end
	end
	for _, panel in pairs(self.panels) do
		self:_refresh(panel)
	end
end

function Boards:Update(profile)
	self.profile = profile
	self:_sync()
end

function Boards:Destroy()
	if self.dead then
		return
	end
	self.dead = true
	if self.connection then
		self.connection:Disconnect()
	end
	if self.destroyConnection then
		self.destroyConnection:Disconnect()
	end
	for anchor in pairs(self.panels) do
		self:_remove(anchor)
	end
end
return Boards
