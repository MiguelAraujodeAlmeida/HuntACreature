-- Inicialização: HUD e controles de captura podem evoluir separadamente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HuntACreatureRemote")
local modules = script.Parent:WaitForChild("HACClient")
local HUD = require(modules.HUD)
local CaptureController = require(modules.CaptureController)
require(modules.LumitoRigPerformance).Start()
require(modules.ChickenRigPerformance).Start()

local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("HuntACreatureGui")
if oldGui then
	oldGui:Destroy()
end
local hud = HUD.new(player)
local controller = CaptureController.new(player, remote, hud)
local trainingPresentation = require(modules.TrainingPresentation).new(player)
local collection = require(modules.CollectionUI).new(player, remote, hud, controller)
hud.Collection = collection
local boards

remote.OnClientEvent:Connect(function(action, a, b, c)
	if action == "Profile" then
		collection:SetData(a)
		if boards then
			boards:Update(a.profile)
		end
	elseif action == "OpenCollection" then
		collection:Open(a, b)
	elseif action == "OpenZoneCollection" then
		collection:Open(a)
		if collection.root.Visible and collection.tab == a then
			collection.zonePage = a
		end
	elseif action == "CloseZoneCollection" then
		if collection.root.Visible and collection.tab == a and collection.zonePage == a then
			hud:CloseSheet()
		end
	elseif action == "ActionFeedback" then
		require(modules.AudioFeedback).Play(a == "Use" and "Hit" or "Progress")
	elseif action == "HunterRankUp" then
		hud:RankUp(a.from, a.to)
	end
	controller:HandleEvent(action, a, b, c)
end)
remote:FireServer("RequestProfile")

-- Receber perfis/abertura de menus não depende da replicação de objetos opcionais.
task.defer(function()
	require(modules.NativeInventory).new(player, collection)
end)
task.defer(function()
	boards = require(modules.UpgradeBoards).new(player, collection)
	if collection.data then
		boards:Update(collection.data.profile)
	end
end)

local stats = player:WaitForChild("leaderstats")
stats:WaitForChild("Gold").Changed:Connect(function()
	hud:UpdateStats()
end)
stats:WaitForChild("XP").Changed:Connect(function()
	hud:UpdateStats()
end)
for _, attribute in ipairs({ "Carregando", "Instaladas", "Renda", "Forca", "Treinando", "BagCapacity", "BaseCapacity", "HunterRank" }) do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		hud:UpdateStats()
	end)
end
hud:UpdateStats()
