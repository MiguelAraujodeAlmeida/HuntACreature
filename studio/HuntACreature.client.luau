-- Inicialização: HUD e controles de captura podem evoluir separadamente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HuntACreatureRemote")
local modules = script.Parent:WaitForChild("HACClient")
local HUD = require(modules.HUD)
local CaptureController = require(modules.CaptureController)

local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("HuntACreatureGui")
if oldGui then oldGui:Destroy() end
local hud = HUD.new(player)
local controller = CaptureController.new(player, remote, hud)

remote.OnClientEvent:Connect(function(action, a, b, c)
	controller:HandleEvent(action, a, b, c)
end)

local stats = player:WaitForChild("leaderstats")
stats:WaitForChild("Ouro").Changed:Connect(function() hud:UpdateStats() end)
stats:WaitForChild("XP").Changed:Connect(function() hud:UpdateStats() end)
for _, attribute in ipairs({"Carregando", "Instaladas", "Renda", "Forca", "Treinando"}) do
	player:GetAttributeChangedSignal(attribute):Connect(function() hud:UpdateStats() end)
end
hud:UpdateStats()
