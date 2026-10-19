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
local collection = require(modules.CollectionUI).new(player, remote, hud, controller)
hud.Collection = collection
hud.Slot.Root.Activated:Connect(function() collection.selected = nil end)

remote.OnClientEvent:Connect(function(action, a, b, c)
	if action == "Profile" then collection:SetData(a)
	elseif action == "OpenCollection" then collection:Open(a,b)
	elseif action == "ActionFeedback" then require(modules.AudioFeedback).Play(a == "Use" and "Hit" or "Progress") end
	controller:HandleEvent(action, a, b, c)
end)
remote:FireServer("RequestProfile")

local stats = player:WaitForChild("leaderstats")
stats:WaitForChild("Ouro").Changed:Connect(function() hud:UpdateStats() end)
stats:WaitForChild("XP").Changed:Connect(function() hud:UpdateStats() end)
for _, attribute in ipairs({"Carregando", "Instaladas", "Renda", "Forca", "Treinando", "BagCapacity", "BaseCapacity"}) do
	player:GetAttributeChangedSignal(attribute):Connect(function() hud:UpdateStats() end)
end
hud:UpdateStats()

