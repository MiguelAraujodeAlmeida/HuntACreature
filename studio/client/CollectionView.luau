-- Só mudanças no conteúdo da aba exigem reconstruir seus cartões.
-- Ouro, força e revisão continuam atualizando sem destruir botões/foco.
local View = {}
function View.Equal(a, b)
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for key, value in pairs(a) do
		if not View.Equal(value, b[key]) then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] == nil then
			return false
		end
	end
	return true
end
function View.Content(data, tab)
	if not data then
		return nil
	end
	local p = data.profile
	if tab == "Criaturas" or tab == "Venda" then
		return { creatures = p.creatures, capacity = p.upgrades }
	elseif tab == "Index" then
		return { discoveries = p.discoveries, variants = p.variantDiscoveries, creatures = p.creatures }
	elseif tab == "HunterRank" then
		return { rank = require(game.ReplicatedStorage.HACShared.HunterProgression).Level(p.xp) }
	elseif tab == "Settings" then
		return p.settings
	elseif tab == "Melhorias" then
		return p.upgrades
	elseif tab == "Loja" then
		return { rotation = data.rotation, shop = p.shop, owned = p.owned, items = p.items }
	end
	return nil
end
return View
