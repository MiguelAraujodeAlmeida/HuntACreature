-- Primeira curva jogável. Valores provisórios centralizados para ajuste no playtest.
local C = {}
C.SchemaVersion = 1
C.Rarities = {"Comum", "Rara", "Épica", "Mítica", "Lendária", "Secreta", "Divina"}
C.Species = {
	Lumito = {Name = "Lumito", Rarity = "Comum", Behavior = "Lumito", Sale = 12, Income = 1, XP = 1,
		Description = "Passeia com pequenas pausas. Ao perceber um caçador, foge até se cansar."},
}
C.Mutations = {Dourado = {Name = "Dourado", Chance = 0.18, Value = 3, Difficulty = 1.2}}
C.Sizes = {
	{Name = "Pequeno", Scale = 0.85, Weight = 25},
	{Name = "Normal", Scale = 1, Weight = 55},
	{Name = "Grande", Scale = 1.2, Weight = 20},
}
C.IncomeSeconds = 5
C.TrainingSeconds = 2
C.RespawnSeconds = 7
C.ItemLimit = 20
C.StartingItems = {Isca = 1, Armadilha = 1, Pocao = 1}
C.StartingEquipment = {LacoTreino = true}
C.Placement = {Distance = 18, Border = 3, Spacing = 3, Height = 0.18}
C.UpgradeOrder = {"Base", "Bolsa", "Treino", "Multiplicador", "Velocidade"}
C.UpgradeGroups = {
	Base = {Name = "Sua base", Anchor = "Plataforma", Distance = 22, Hint = "Aproxime-se da sua base.", PromptAnchor = "Totem", ActionText = "Melhorar base"},
	Bolsa = {Name = "Bolsa de caça"},
	Treino = {Name = "Manequim de laço", Anchor = "Esteira", Distance = 12, Hint = "Aproxime-se do seu manequim.", PromptAnchor = "Esteira", ActionText = "Melhorar treino"},
	Velocidade = {Name = "Velocidade do caçador"},
}
C.BaseLayout = {Columns = 3, ColumnSpacing = 4, RowSpacing = 3.5}
C.Index = {PageSize = 18}
C.Upgrades = {
	Base = {Name = "Base", Group = "Base", Description = "Instale mais criaturas e amplie sua produção de ouro.", Values = {3, 4, 5, 6}, Costs = {40, 100, 220}, Unit = "lugares"},
	Bolsa = {Name = "Bolsa", Group = "Bolsa", Description = "Carregue mais criaturas antes de voltar à base.", Values = {3, 4, 5, 6}, Costs = {25, 70, 160}, Unit = "lugares"},
	Treino = {Name = "Manequim", Group = "Treino", Description = "Melhora o ganho básico de força a cada ciclo de treino.", Values = {1, 2, 3, 4}, Costs = {30, 90, 180}, Unit = "força base / ciclo"},
	Multiplicador = {Name = "Eficiência do treino", Group = "Treino", Description = "Multiplica a força recebida em cada ciclo do manequim.", Values = {1, 1.25, 1.5, 2}, Costs = {50, 140, 300}, Unit = "× ganho do treino"},
	Velocidade = {Name = "Velocidade", Group = "Velocidade", Description = "Desloque-se mais rápido para acompanhar as criaturas.", Values = {16, 18, 20, 22}, Costs = {35, 100, 240}, Unit = "studs/s"},
}
C.ItemOrder = {"Isca", "Armadilha", "Pocao", "LacoTreino"}
C.Items = {
	Isca = {Name = "Isca", Description = "Atrai criaturas tranquilas que respondem à isca.", Category = "Consumíveis", Shop = {Chance = 1, Min = 2, Max = 5}, Price = 8, Stock = 5, Cooldown = 8, Duration = 15, Radius = 18},
	Armadilha = {Name = "Armadilha", Description = "Posicione no chão para desacelerar um alvo.", Category = "Consumíveis", Shop = {Chance = 0.7, Min = 1, Max = 3}, Price = 12, Stock = 3, Cooldown = 10, Duration = 25, Radius = 3, Slow = 0.35, EffectSeconds = 6},
	Pocao = {Name = "Poção", Description = "Acalma o alvo durante a disputa de captura.", Category = "Consumíveis", Shop = {Chance = 0.6, Min = 1, Max = 4}, Price = 10, Stock = 4, Cooldown = 12, Duration = 6, Slow = 0.65},
	LacoTreino = {Name = "Laço de treino", Description = "Seu laço inicial permanente.", Category = "Equipamentos", Shop = {Chance = 1, Min = 1, Max = 1}, Price = 0, Stock = 1, Permanent = true},
}
C.Shop = {Version = 2, Seconds = 300, Seed = 73129, Distance = 18}

-- As listas de ordem são opcionais: novas definições também entram no catálogo.
function C.OrderedIds(definitions, preferred)
	local ids, rank = {}, {}
	for i, id in ipairs(preferred or {}) do rank[id] = i end
	for id in pairs(definitions) do table.insert(ids, id) end
	table.sort(ids, function(a,b)
		local ar, br = rank[a] or math.huge, rank[b] or math.huge
		return ar == br and a < b or ar < br
	end)
	return ids
end
function C.ShopIds()
	local ids = {}
	for _, id in ipairs(C.OrderedIds(C.Items, C.ItemOrder)) do
		if C.Items[id].Shop then table.insert(ids, id) end
	end
	return ids
end
function C.UpgradesIn(group)
	local ids = {}
	for _, id in ipairs(C.OrderedIds(C.Upgrades, C.UpgradeOrder)) do
		if C.Upgrades[id].Group == group then table.insert(ids, id) end
	end
	return ids
end

function C.Stat(profile, key)
	local definition = C.Upgrades[key]
	return definition.Values[(profile.upgrades[key] or 0) + 1]
end
function C.TrainingGain(profile, changedId)
	local function value(id)
		local level = (profile.upgrades[id] or 0) + (changedId == id and 1 or 0)
		return C.Upgrades[id].Values[level + 1] or C.Stat(profile, id)
	end
	return value("Treino") * value("Multiplicador")
end
function C.UpgradePreview(profile, id)
	local def = C.Upgrades[id]
	local level = profile.upgrades[id] or 0
	return {level = level, current = def.Values[level + 1], next = def.Values[level + 2], cost = def.Costs[level + 1]}
end
function C.SameShopWindow(a, b)
	-- Uma atualização de catálogo não devolve compras já feitas na mesma janela.
	return type(a) == "string" and type(b) == "string" and a:match(":(%d+)$") ~= nil
		and a:match(":(%d+)$") == b:match(":(%d+)$")
end
function C.Bought(profile, rotation, id)
	return C.SameShopWindow(profile.shop.rotation, rotation.id) and (profile.shop.bought[id] or 0) or 0
end
function C.ItemCapacity(id)
	return C.Items[id].Limit or C.ItemLimit
end

function C.Value(creature, kind)
	local value = C.Species[creature.species][kind]
	for _, mutation in ipairs(creature.mutations) do value *= C.Mutations[mutation].Value end
	return math.max(1, math.floor(value * creature.size + 0.5))
end

function C.Name(creature)
	local name = C.Species[creature.species].Name
	for _, mutation in ipairs(creature.mutations) do name ..= " " .. C.Mutations[mutation].Name end
	return name
end

function C.Rotation(timestamp)
	local epoch = math.floor(timestamp / C.Shop.Seconds)
	local offers = {}
	for _, id in ipairs(C.ShopIds()) do
		local def = C.Items[id]
		local rule = def.Shop
		-- Fluxo por ID: inserir/reordenar um item não altera o sorteio dos demais.
		local seed = (epoch + C.Shop.Seed + C.Shop.Version * 104729) % 2147483647
		for i = 1, #id do seed = (seed * 31 + string.byte(id,i)) % 2147483647 end
		local function nextNumber()
			seed = math.max(1, seed) * 16807 % 2147483647
			return (seed - 1) / 2147483646
		end
		local available = nextNumber() < rule.Chance
		local quantity = rule.Min + math.floor(nextNumber() * (rule.Max - rule.Min + 1))
		offers[id] = {price = def.Price, stock = available and quantity or 0}
	end
	return {id = tostring(C.Shop.Version) .. ":" .. epoch, endsAt = (epoch + 1) * C.Shop.Seconds, offers = offers}
end
-- Erros de edição do catálogo aparecem na carga, antes de qualquer compra.
for id,def in pairs(C.Upgrades) do
	assert(C.UpgradeGroups[def.Group], "Grupo de upgrade desconhecido: " .. id)
	assert(#def.Values == #def.Costs + 1, "Values precisa conter o nível inicial e todos os upgrades: " .. id)
	for _,value in ipairs(def.Values) do assert(type(value)=="number" and value>=0 and value<math.huge, "Valor inválido: " .. id) end
	for _,cost in ipairs(def.Costs) do assert(type(cost)=="number" and cost>=0 and cost<math.huge, "Custo inválido: " .. id) end
end
for id,def in pairs(C.Items) do
	if def.Shop then
		local rule=def.Shop
		assert(type(rule.Chance)=="number" and rule.Chance>=0 and rule.Chance<=1, "Chance inválida: " .. id)
		assert(type(rule.Min)=="number" and type(rule.Max)=="number" and rule.Min>=0 and rule.Max>=rule.Min
			and rule.Min%1==0 and rule.Max%1==0, "Estoque inválido: " .. id)
		assert(type(def.Price)=="number" and def.Price>=0 and def.Price<math.huge, "Preço inválido: " .. id)
	end
end
return C
