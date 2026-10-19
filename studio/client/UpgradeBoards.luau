-- Botões clicáveis no mundo. Servidor verifica dono, distância, preço e revisão.
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local RunService = game:GetService("RunService")
local Boards = {}
Boards.__index = Boards
local function number(value)
	return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
end
function Boards.new(player, ui)
	local self = setmetatable({ entries = {}, player = player, ui = ui }, Boards)
	local bases = workspace:WaitForChild("HuntACreature"):WaitForChild("Hub"):WaitForChild("Bases")
	for _, base in ipairs(bases:GetChildren()) do
		for _, anchor in ipairs(base:WaitForChild("PlacasMelhorias"):GetChildren()) do
			local ids = anchor:GetAttribute("UpgradeIds")
			if not ids then
				continue
			end
			local gui = Instance.new("SurfaceGui")
			gui.Name, gui.Adornee, gui.Face = "HACUpgradeBoard", anchor, Enum.NormalId.Front
			gui.SizingMode, gui.PixelsPerStud = Enum.SurfaceGuiSizingMode.PixelsPerStud, 65
			gui.LightInfluence, gui.AlwaysOnTop, gui.Active, gui.MaxDistance = 0, false, true, 40
			gui.Enabled, gui.ResetOnSpawn = false, false
			gui.Parent = player.PlayerGui
			local keys = string.split(ids, ",")
			local root = W.frame(gui, "Painel", UDim2.fromScale(1, 1), UDim2.new(), W.Style.UI.Ink, 12)
			W.stroke(root, W.Style.UI.Cyan, 3)
			local isTraining = anchor.Name == "Treino"
			local rows = W.frame(root, "Melhorias", UDim2.new(1, 0, 1, isTraining and -55 or 0), UDim2.new())
			if isTraining then
				local train = Button.new(
					root,
					{
						name = "Treinar",
						text = "TREINAR",
						color = W.Style.UI.Green,
						size = UDim2.new(1, -20, 0, 44),
						position = UDim2.new(0, 10, 1, -49),
						textSize = 23,
					}
				)
				train.Root.Activated:Connect(function()
					if os.clock() < (self.nextClick or 0) or player:GetAttribute("Treinando") then
						return
					end
					self.nextClick = os.clock() + 0.3
					ui.remote:FireServer("ToggleTraining")
				end)
			end
			for i, id in ipairs(keys) do
				local row = W.frame(rows, id, UDim2.new(1, -18, 1 / #keys, -12), UDim2.new(0, 9, (i - 1) / #keys, 6))
				local title = W.text(row, "Titulo", C.Upgrades[id].Name, UDim2.new(1, 0, 0, 26), UDim2.new(), 22)
				local value =
					W.text(row, "Beneficio", "", UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 28), 18, W.Style.UI.Green)
				local skin = Button.new(row, {
					name = "Comprar",
					text = "",
					color = W.Style.UI.Red,
					textSize = 23,
					size = UDim2.new(1, -20, 0, 43),
					position = UDim2.new(0, 10, 1, -47),
				})
				local entry =
					{ id = id, base = base, anchor = anchor, gui = gui, value = value, skin = skin, title = title }
				skin.Root.Activated:Connect(function()
					if
						self.ui.hud.sheetKind
						or self.ui.controller.capturing
						or self.player:GetAttribute("Treinando")
					then
						return
					end
					if os.clock() < (self.nextClick or 0) then
						return
					end
					self.nextClick = os.clock() + 0.3
					self.ui:Send("Upgrade", id)
				end)
				table.insert(self.entries, entry)
			end
		end
	end
	local elapsed = 0
	self.connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 then
			return
		end
		elapsed = 0
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		for _, e in ipairs(self.entries) do
			e.gui.Enabled = e.base.Name == "Base" .. tostring(player:GetAttribute("BaseIndex"))
				and root ~= nil
				and (root.Position - e.anchor.Position).Magnitude <= C.Boards.Distance
				and not ui.hud.sheetKind
				and not player:GetAttribute("Treinando")
		end
	end)
	ui.hud.Gui.Destroying:Once(function()
		self.connection:Disconnect()
		for _, e in ipairs(self.entries) do
			e.gui:Destroy()
		end
	end)
	return self
end
function Boards:Update(profile)
	for _, e in ipairs(self.entries) do
		local p = C.UpgradePreview(profile, e.id)
		e.title.Text = C.Upgrades[e.id].Name .. " • Nv. " .. (p.level + 1)
		local unit = e.id == "Treino" and " força"
			or e.id == "Multiplicador" and "×"
			or e.id == "Velocidade" and " studs/s"
			or " espaços"
		e.value.Text = number(p.current) .. (p.next and " → " .. number(p.next) or "") .. unit
		e.skin:SetText(p.cost and "$ " .. p.cost or "MÁXIMO")
		e.skin.caption.TextTransparency = p.cost and profile.gold >= p.cost and 0 or 0.3
	end
end
return Boards
