-- Executar pelo MCP no Server durante Play. Mundo isolado; não altera jogadores reais.
local Config = require(game.ReplicatedStorage.HACShared.CaptureConfig)
local Service = require(game.ServerScriptService.HACServer.CaptureService)
local fixtures = Instance.new("Folder")
fixtures.Name = "HACFlightTest"
fixtures.Parent = workspace
local character = Instance.new("Model")
character.Parent = fixtures
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Anchored = true
root.Position = Vector3.new(3000, 100, 0)
root.Parent = character
local humanoid = Instance.new("Humanoid")
humanoid.Parent = character
local tool = Instance.new("Tool")
tool.Name = Config.ToolName
tool.RequiresHandle = false
tool.Parent = character
local wild = Instance.new("Folder")
wild.Name = "Wild"
wild.Parent = fixtures
local effects = Instance.new("Folder")
effects.Name = "Effects"
effects.Parent = fixtures
local player = {
	Character = character,
	UserId = -1,
	CameraMaxZoomDistance = 128,
	GetAttribute = function()
		return false
	end,
}
local events = {}
local service = Service.new({
	remote = {
		FireClient = function(_, _, action, a)
			table.insert(events, { action, a })
		end,
	},
	wildFolder = wild,
	effectsFolder = effects,
	canCarry = function()
		return true
	end,
	onCaptured = function() end,
})
service.connection:Disconnect()
local passed = {}
local origin = root.Position + Vector3.new(0, 1.3, 0)
local function record(name, condition)
	assert(condition, name)
	table.insert(passed, name)
end
local function launch(direction, power, camera)
	service.cooldowns[player] = nil
	service.charges[player] =
		{ started = os.clock() - Config.Lassos[tool.Name].ChargeSeconds * (power or 1), lassoName = tool.Name }
	service:_throw(player, { origin = camera or origin, direction = direction })
	return service.projectiles[player]
end
local function advance()
	for _ = 1, 160 do
		local p = service.projectiles[player]
		if not p then
			break
		end
		service:_stepProjectile(player, p, 1 / 60)
	end
end
local ok, err = xpcall(function()
	local lasso = Config.Lassos[tool.Name]
	local p = launch(Vector3.new(0, 1, 0), 1)
	record("Céu: lançamento permitido", p ~= nil)
	for _ = 1, 80 do
		if p.returning then
			break
		end
		service:_stepProjectile(player, p, 1 / 60)
	end
	record("Alcance máximo físico = 73 studs", math.abs((p.position - origin).Magnitude - lasso.MaximumRange) < 0.03)
	record("Volta ao atingir limite", p.returning == true)
	advance()
	record(
		"Recolhimento limpa projétil e attachments",
		not service.projectiles[player] and not root:FindFirstChild("HACLacoOrigem")
	)
	p = launch(Vector3.new(0, 1, 0), 0.5)
	record(
		"Meia carga limita percurso a 45,5 studs",
		math.abs(p.distance - (lasso.MinimumRange + lasso.MaximumRange) / 2) < 0.03
	)
	service:_clearProjectile(player, false)
	local camera = origin + Vector3.new(0, 0, 120)
	p = launch(Vector3.new(0, 1, 0), 1, camera)
	record("Zoom de câmera a 120 studs aceito", p ~= nil)
	service:_clearProjectile(player, false)
	local creature = Instance.new("Model")
	creature.Name = "Alvo"
	creature.Parent = wild
	local body = Instance.new("Part")
	body.Anchored = true
	body.Size = Vector3.new(3, 3, 3)
	body.Position = origin + Vector3.new(0, 0, -35)
	body.Parent = creature
	creature.PrimaryPart = body
	local blocker = Instance.new("Part")
	blocker.Anchored = true
	blocker.Size = Vector3.new(8, 8, 1)
	blocker.Position = origin + Vector3.new(0, 0, -15)
	blocker.Parent = fixtures
	p = launch((body.Position - camera).Unit, 1, camera)
	for _ = 1, 80 do
		if p.returning then
			break
		end
		service:_stepProjectile(player, p, 1 / 60)
	end
	record(
		"Parede bloqueia captura e inicia retorno",
		p.returning and not service.sessions[player] and math.abs(p.position.Z - blocker.Position.Z - 0.5) < 0.03
	)
	advance()
	blocker:Destroy()
	p = launch((body.Position - camera).Unit, 1, camera)
	advance()
	record("Acerto real inicia captura", service.sessions[player] ~= nil and not service.projectiles[player])
	service:_finish(player, false, nil)
	creature:Destroy()
	Config.Lassos["TesteCurto"] = {
		ChargeSeconds = 1,
		MinimumRange = 5,
		MaximumRange = 20,
		ProjectileSpeed = 90,
		ReturnSpeed = 140,
		CooldownSeconds = 0,
	}
	tool.Name = "TesteCurto"
	p = launch(Vector3.new(1, 0, 0), 1)
	record("Outro laço usa seu próprio alcance (20)", math.abs(p.distance - 20) < 0.03)
	advance()
	tool.Name = Config.ToolName
	local surface = Instance.new("Part")
	surface.Anchored = true
	surface.Size = Vector3.new(2, 2, 0.1)
	surface.Position = origin + Vector3.new(0, 0, -0.25)
	surface.Parent = fixtures
	p = launch(Vector3.new(0, 0, -1), 1)
	record("Superfície próxima não gera mira inválida", p ~= nil)
	advance()
	surface:Destroy()
	service.charges[player] = { started = os.clock() - 2, lassoName = tool.Name }
	service:_throw(player, { origin = Vector3.new(0 / 0, 0, 0), direction = Vector3.new(0, 0, -1) })
	record("Dados não finitos rejeitados com segurança", not service.projectiles[player])
	local redundant = false
	for _, event in ipairs(events) do
		if
			event[2] == "Mira inválida."
			or event[2] == "O laço errou o alvo."
			or event[2] == "Alvo fora do alcance."
		then
			redundant = true
		end
	end
	record("Nenhum aviso redundante de erro", not redundant)
end, debug.traceback)
service:PlayerRemoving(player)
fixtures:Destroy()
Config.Lassos.TesteCurto = nil
assert(ok, err)
return { passed = passed, count = #passed }
