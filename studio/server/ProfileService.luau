-- Perfil único por jogador, com lease de sessão e salvamento serializado.
-- Nunca substituir uma falha de leitura por um perfil novo.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Data = require(script.Parent.ProfileData)
local Persistence = require(script.Parent.PersistenceConfig)
local Service = {}
Service.__index = Service
local LEASE_SECONDS, FREEZE_MARGIN = 180, 45
function Service.new()
	local memory = RunService:IsStudio() and workspace:GetAttribute("HACStudioMemoryMode") == true
	return setmetatable({sessions = {}, memory = memory,
		store = not memory and DataStoreService:GetDataStore(Persistence.StoreName(RunService:IsStudio())) or nil}, Service)
end
function Service:Load(player)
	local token = HttpService:GenerateGUID(false)
	local result, reason
	for attempt = 1, 3 do
		local ok, value = pcall(function()
			if self.memory then return {data = Data.New(), lease = {token = token, expires = os.time() + LEASE_SECONDS}} end
			return self.store:UpdateAsync("Player_" .. player.UserId, function(old)
				if old and old.lease and old.lease.token ~= token and old.lease.expires > os.time() then return nil end
				local data = old and Data.Validate(old.data) or Data.New()
				return {data = data, lease = {token = token, expires = os.time() + LEASE_SECONDS}}
			end)
		end)
		if ok and value and value.lease and value.lease.token == token then result = value; break end
		reason = ok and "Your profile is open in another session." or tostring(value)
		if attempt < 3 then task.wait(attempt * 2) end
	end
	if not result then warn("[HAC Perfil] " .. player.UserId .. ": " .. tostring(reason)); return nil end
	self.sessions[player] = {data = result.data, token = token, expires = result.lease.expires, saving = false, closing = false}
	return result.data
end
function Service:Get(player)
	local session = self.sessions[player]
	if session and not session.closing and (self.memory or os.time() < session.expires - FREEZE_MARGIN) then return session.data end
end
function Service:Save(player, release)
	local session = self.sessions[player]
	if not session then return true end
	if release then session.closing = true end
	local deadline = os.clock() + 20
	while session.saving and os.clock() < deadline do task.wait(0.1) end
	if session.saving then return false end
	-- Outro encerramento pode ter concluído durante a espera.
	if self.sessions[player] ~= session then return true end
	session.saving = true
	local snapshot = Data.Copy(session.data)
	local saved = false
	for attempt = 1, 3 do
		local ok, value = pcall(function()
			if self.memory then return {data = snapshot, lease = {token = session.token, expires = os.time() + LEASE_SECONDS}} end
			return self.store:UpdateAsync("Player_" .. player.UserId, function(old)
				if not old or not old.lease or old.lease.token ~= session.token then return nil end
				return {data = snapshot, lease = not release and {token = session.token, expires = os.time() + LEASE_SECONDS} or nil}
			end)
		end)
		if ok and value then
			saved = true
			if not release then session.expires = value.lease.expires end
			break
		elseif ok then
			session.closing = true
			warn("[HAC Perfil] Sessão perdeu a posse do perfil: " .. player.UserId)
			break
		else
			warn("[HAC Perfil] Falha de salvamento: " .. tostring(value))
		end
		if attempt < 3 then task.wait(attempt) end
	end
	session.saving = false
	if release and saved then self.sessions[player] = nil end
	return saved
end
function Service:Change(player, callback, passive)
	local profile = self:Get(player)
	if not profile then return false, "Progress unavailable. Please wait for saving." end
	-- Copy-on-write mantém transações indivisíveis e sem efeitos parciais em falhas.
	local nextProfile = Data.Copy(profile)
	local ok, accepted, message = pcall(callback, nextProfile)
	if not ok then warn("[HAC Transação] " .. tostring(accepted)); return false, "Could not complete the action." end
	if not accepted then return false, message end
	-- A revisão protege ações sobre a coleção; renda/treino não invalidam cliques.
	-- O snapshot completo, inclusive ganhos passivos, continua sendo salvo.
	nextProfile.revision = profile.revision + (passive and 0 or 1)
	self.sessions[player].data = nextProfile
	return true, message
end
return Service
