-- Interface do protótipo, compatível com espaço, mouse e toque.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HuntACreatureRemote")
local gui = Instance.new("ScreenGui")
gui.Name = "HuntACreatureGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local C = {
	dark = Color3.fromRGB(23, 42, 51),
	panel = Color3.fromRGB(31, 60, 68),
	light = Color3.fromRGB(231, 249, 241),
	mint = Color3.fromRGB(88, 225, 186),
	gold = Color3.fromRGB(255, 212, 107),
	muted = Color3.fromRGB(166, 201, 201),
}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = 0.35
	s.Parent = parent
end

local function frame(parent, name, size, position, color)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = position
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function text(parent, name, message, size, position, color, font, textSize)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.Size = size
	t.Position = position
	t.BackgroundTransparency = 1
	t.Text = message
	t.TextColor3 = color
	t.TextSize = textSize or 16
	t.Font = font or Enum.Font.Gotham
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextWrapped = true
	t.Parent = parent
	return t
end

local hud = frame(gui, "HUD", UDim2.fromOffset(270, 145), UDim2.fromOffset(18, 18), C.dark)
corner(hud, 16)
stroke(hud, C.mint, 2)
text(hud, "Titulo", "HUNT A CREATURE", UDim2.fromOffset(240, 28), UDim2.fromOffset(15, 10), C.mint, Enum.Font.GothamBlack, 20)
local counters = text(hud, "Recursos", "Ouro 0  •  XP 0", UDim2.fromOffset(240, 27), UDim2.fromOffset(15, 42), C.gold, Enum.Font.GothamBold, 17)
local collection = text(hud, "Colecao", "Carregando 0/3  •  Base 0/3", UDim2.fromOffset(240, 25), UDim2.fromOffset(15, 71), C.light, Enum.Font.GothamMedium, 14)
local strength = text(hud, "Forca", "Força 0  •  Renda 0 ouro/5 s", UDim2.fromOffset(240, 27), UDim2.fromOffset(15, 98), C.muted, Enum.Font.GothamMedium, 14)

local tip = frame(gui, "Dica", UDim2.new(0, 520, 0, 42), UDim2.new(0.5, -260, 1, -56), C.dark)
corner(tip, 12)
tip.BackgroundTransparency = 0.1
local tipText = text(tip, "Texto", "Equipe o laço, capture na ilha e instale na sua base.", UDim2.new(1, -24, 1, 0), UDim2.fromOffset(12, 0), C.light, Enum.Font.GothamMedium, 14)
tipText.TextXAlignment = Enum.TextXAlignment.Center

local toast = frame(gui, "Aviso", UDim2.new(0, 420, 0, 54), UDim2.new(0.5, -210, 0, 35), C.dark)
corner(toast, 14)
stroke(toast, C.gold, 2)
toast.Visible = false
local toastText = text(toast, "Texto", "", UDim2.new(1, -26, 1, -8), UDim2.fromOffset(13, 4), C.light, Enum.Font.GothamBold, 15)
toastText.TextXAlignment = Enum.TextXAlignment.Center
local toastVersion = 0
local function showToast(message)
	toastVersion += 1
	local version = toastVersion
	toastText.Text = message
	toast.Visible = true
	task.delay(4, function()
		if version == toastVersion then toast.Visible = false end
	end)
end

local panel = frame(gui, "Captura", UDim2.fromOffset(350, 300), UDim2.new(0.5, -175, 0.5, -150), C.dark)
corner(panel, 18)
stroke(panel, C.mint, 3)
panel.Visible = false
local scale = Instance.new("UIScale")
scale.Parent = panel
local function resize()
	scale.Scale = math.min(1, math.max(0.72, workspace.CurrentCamera.ViewportSize.X / 390))
end
resize()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

text(panel, "Titulo", "CAPTURA COM LAÇO", UDim2.fromOffset(320, 29), UDim2.fromOffset(17, 14), C.mint, Enum.Font.GothamBlack, 20)
local targetName = text(panel, "Criatura", "Lumito", UDim2.fromOffset(320, 25), UDim2.fromOffset(18, 45), C.light, Enum.Font.GothamBold, 17)
local track = frame(panel, "Trilha", UDim2.fromOffset(68, 184), UDim2.fromOffset(24, 78), C.panel)
corner(track, 10)
stroke(track, C.muted, 2)
track.ClipsDescendants = true
local zone = frame(track, "ZonaDoLaco", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0.5, -25), C.mint)
zone.BackgroundTransparency = 0.45
corner(zone, 8)
local target = frame(track, "Alvo", UDim2.new(1, -10, 0, 10), UDim2.new(0, 5, 0.5, -5), C.gold)
corner(target, 5)

local instruction = text(panel, "Instrucao", "Segure ESPAÇO ou o botão para subir. Solte para descer. Mantenha o alvo na faixa!", UDim2.fromOffset(226, 72), UDim2.fromOffset(107, 76), C.light, Enum.Font.GothamMedium, 15)
local progressLabel = text(panel, "ProgressoTexto", "Progresso 8%", UDim2.fromOffset(225, 23), UDim2.fromOffset(108, 151), C.gold, Enum.Font.GothamBold, 15)
local progressBack = frame(panel, "BarraFundo", UDim2.fromOffset(222, 16), UDim2.fromOffset(108, 179), C.panel)
corner(progressBack, 8)
local progressFill = frame(progressBack, "Barra", UDim2.fromScale(0.08, 1), UDim2.fromScale(0, 0), C.mint)
corner(progressFill, 8)
local holdButton = Instance.new("TextButton")
holdButton.Name = "SegurarLaco"
holdButton.Size = UDim2.fromOffset(222, 54)
holdButton.Position = UDim2.fromOffset(108, 207)
holdButton.BackgroundColor3 = C.mint
holdButton.BorderSizePixel = 0
holdButton.Text = "SEGURAR LAÇO"
holdButton.TextColor3 = C.dark
holdButton.TextSize = 17
holdButton.Font = Enum.Font.GothamBlack
holdButton.Parent = panel
corner(holdButton, 11)

local active = false
local holding = false
local function setHolding(value)
	if not active or holding == value then return end
	holding = value
	remote:FireServer("Hold", value)
	holdButton.BackgroundColor3 = value and C.gold or C.mint
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
		setHolding(true)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
		setHolding(false)
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		setHolding(false)
	end
end)
holdButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		setHolding(true)
	end
end)
holdButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		setHolding(false)
	end
end)

remote.OnClientEvent:Connect(function(action, a, b, c)
	if action == "Start" then
		active = true
		holding = false
		targetName.Text = a
		panel.Visible = true
		tip.Visible = false
	elseif action == "State" then
		if not active then return end
		target.Position = UDim2.new(0, 5, 1 - a, -5)
		zone.Position = UDim2.new(0, 0, 1 - b, -25)
		progressFill.Size = UDim2.fromScale(c, 1)
		progressLabel.Text = "Progresso " .. math.floor(c * 100) .. "%"
	elseif action == "End" then
		active = false
		holding = false
		panel.Visible = false
		tip.Visible = true
		showToast(b)
	elseif action == "Notice" then
		showToast(a)
	end
end)

local stats = player:WaitForChild("leaderstats")
local gold = stats:WaitForChild("Ouro")
local xp = stats:WaitForChild("XP")
local function updateHud()
	counters.Text = "Ouro " .. gold.Value .. "  •  XP " .. xp.Value
	collection.Text = "Carregando " .. (player:GetAttribute("Carregando") or 0) .. "/3  •  Base " .. (player:GetAttribute("Instaladas") or 0) .. "/3"
	strength.Text = "Força " .. (player:GetAttribute("Forca") or 0) .. "  •  Renda " .. (player:GetAttribute("Renda") or 0) .. " ouro/5 s"
	if player:GetAttribute("Treinando") then
		tipText.Text = "Treinando... fique perto da esteira para ganhar força."
	elseif (player:GetAttribute("Carregando") or 0) > 0 then
		tipText.Text = "Volte à sua base no Hub e instale a criatura no totem."
	else
		tipText.Text = "Equipe o laço, capture na ilha e instale na sua base."
	end
end
gold.Changed:Connect(updateHud)
xp.Changed:Connect(updateHud)
for _, attribute in ipairs({"Carregando", "Instaladas", "Forca", "Renda", "Treinando"}) do
	player:GetAttributeChangedSignal(attribute):Connect(updateHud)
end
updateHud()
