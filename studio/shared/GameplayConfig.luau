-- Primeira curva jogável. Valores provisórios centralizados para ajuste no playtest.
local C = {}
C.SchemaVersion = 1
C.Rarities = { "Comum", "Rara", "Épica", "Mítica", "Lendária", "Secreta", "Divina" }
C.Species = {
	Lumito = {
		Name = "Lumito",
		Rarity = "Comum",
		Behavior = "Lumito",
		Sale = 12,
		Income = 1,
		XP = 1,
		MinimumStrength = 0,
		Description = "A playful wanderer. Flees from hunters until it tires.",
	},
}
C.Mutations = { Dourado = { Name = "Gold", Chance = 0.18, Value = 3, Difficulty = 1.2 } }
C.Size = { Minimum = 1, Maximum = 5, Curve = 5, Precision = 100 }
function C.RollSize(random)
	-- Continuous scale; large specimens are uncommon without a separate rarity tier.
	local size = C.Size.Minimum + (C.Size.Maximum - C.Size.Minimum) * random:NextNumber() ^ C.Size.Curve
	return math.clamp(math.floor(size * C.Size.Precision + 0.5) / C.Size.Precision, C.Size.Minimum, C.Size.Maximum)
end
C.IncomeSeconds = 1 -- Mesmo valor por pagamento: rendimento 5x, solicitado em 18/10.
C.TrainingSeconds = 2
C.RespawnSeconds = 7
C.ItemLimit = 20
C.StartingItems = { Isca = 1, Armadilha = 1, Pocao = 1 }
C.StartingEquipment = { LacoTreino = true }
C.Placement = { Distance = 18, Border = 3, Spacing = 3, Height = 0.18 }
C.UpgradeOrder = { "Base", "Bolsa", "Treino", "Multiplicador", "Velocidade" }
C.UpgradeGroups = {
	Base = {
		Name = "Your base",
		Anchor = "Plataforma",
		Distance = 22,
		Hint = "Move closer to your base.",
		PromptAnchor = "Totem",
		ActionText = "Upgrade base",
	},
	Bolsa = { Name = "Creature Bag" },
	Treino = {
		Name = "Training dummy",
		Anchor = "Esteira",
		Distance = 12,
		Hint = "Move closer to your dummy.",
		PromptAnchor = "Esteira",
		ActionText = "Upgrade training",
	},
	Velocidade = { Name = "Movement speed" },
}
C.BaseLayout = { Columns = 3, ColumnSpacing = 4, RowSpacing = 3.5 }
C.Index = { PageSize = 18 }
C.Settings = { Sound = true, BaseCreatures = true }
C.BaseRoaming = { Speed = 2.1, Interval = 0.05, PauseMin = 0.8, PauseMax = 2.8, Margin = 0.35 }
C.RarityNames = {
	Comum = "Common",
	Rara = "Rare",
	["Épica"] = "Epic",
	["Mítica"] = "Mythic",
	["Lendária"] = "Legendary",
	Secreta = "Secret",
	Divina = "Divine",
}
function C.MinimumStrength(species)
	return C.Species[species] and (C.Species[species].MinimumStrength or 0) or math.huge
end
function C.VariantKey(item)
	local mutations = table.clone(item.mutations or {})
	table.sort(mutations)
	return item.species .. ":" .. (#mutations == 0 and "Normal" or table.concat(mutations, "+"))
end
C.Sell = { Distance = 14 }
C.Boards = { Distance = 16 }
C.Upgrades = {
	Base = {
		Name = "Base",
		Group = "Base",
		Description = "Equip more creatures to grow your income.",
		Values = { 3, 4, 5, 6 },
		Costs = { 40, 100, 220 },
		Unit = "slots",
	},
	Bolsa = {
		Name = "Bag",
		Group = "Bolsa",
		Description = "Carry more creatures on your hunts.",
		Values = { 3, 4, 5, 6 },
		Costs = { 25, 70, 160 },
		Unit = "slots",
	},
	Treino = {
		Name = "Training dummy",
		Group = "Treino",
		Description = "Gain more strength each training cycle.",
		Values = { 1, 2, 3, 4 },
		Costs = { 30, 90, 180 },
		Unit = "strength / cycle",
	},
	Multiplicador = {
		Name = "Training efficiency",
		Group = "Treino",
		Description = "Multiply strength gained during training.",
		Values = { 1, 1.25, 1.5, 2 },
		Costs = { 50, 140, 300 },
		Unit = "× training gain",
	},
	Velocidade = {
		Name = "Speed",
		Group = "Velocidade",
		Description = "Move faster to keep up with creatures.",
		Values = { 16, 18, 20, 22 },
		Costs = { 35, 100, 240 },
		Unit = "studs/s",
	},
}
C.ItemOrder = { "Isca", "Armadilha", "Pocao", "LacoTreino" }
C.Items = {
	Isca = {
		Name = "Bait",
		Description = "Attracts nearby calm creatures.",
		Category = "Tools",
		Shop = { Chance = 1, Min = 2, Max = 5 },
		Price = 8,
		Stock = 5,
		Cooldown = 8,
		Duration = 15,
		Radius = 18,
	},
	Armadilha = {
		Name = "Trap",
		Description = "Place on the ground to slow a creature.",
		Category = "Tools",
		Shop = { Chance = 0.7, Min = 1, Max = 3 },
		Price = 12,
		Stock = 3,
		Cooldown = 10,
		Duration = 25,
		Radius = 3,
		Slow = 0.35,
		EffectSeconds = 6,
	},
	Pocao = {
		Name = "Calming Potion",
		Description = "Calms the creature during capture.",
		Category = "Tools",
		Shop = { Chance = 0.6, Min = 1, Max = 4 },
		Price = 10,
		Stock = 4,
		Cooldown = 12,
		Duration = 6,
		Slow = 0.65,
	},
	LacoTreino = {
		Name = "Training Lasso",
		Description = "Your trusty starter lasso.",
		Category = "Lassos",
		Shop = { Chance = 1, Min = 1, Max = 1 },
		Price = 0,
		Stock = 1,
		Permanent = true,
	},
}
C.Shop = { Version = 2, Seconds = 300, Seed = 73129, Distance = 18 }

-- As listas de ordem são opcionais: novas definições também entram no catálogo.
function C.OrderedIds(definitions, preferred)
	local ids, rank = {}, {}
	for i, id in ipairs(preferred or {}) do
		rank[id] = i
	end
	for id in pairs(definitions) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		local ar, br = rank[a] or math.huge, rank[b] or math.huge
		return ar == br and a < b or ar < br
	end)
	return ids
end
function C.ShopIds()
	local ids = {}
	for _, id in ipairs(C.OrderedIds(C.Items, C.ItemOrder)) do
		if C.Items[id].Shop then
			table.insert(ids, id)
		end
	end
	return ids
end
function C.UpgradesIn(group)
	local ids = {}
	for _, id in ipairs(C.OrderedIds(C.Upgrades, C.UpgradeOrder)) do
		if C.Upgrades[id].Group == group then
			table.insert(ids, id)
		end
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
	return { level = level, current = def.Values[level + 1], next = def.Values[level + 2], cost = def.Costs[level + 1] }
end
function C.SameShopWindow(a, b)
	-- Uma atualização de catálogo não devolve compras já feitas na mesma janela.
	return type(a) == "string"
		and type(b) == "string"
		and a:match(":(%d+)$") ~= nil
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
	for _, mutation in ipairs(creature.mutations) do
		value *= C.Mutations[mutation].Value
	end
	return math.max(1, math.floor(value * creature.size + 0.5))
end

function C.Name(creature)
	local name = C.Species[creature.species].Name
	for _, mutation in ipairs(creature.mutations) do
		name ..= " " .. C.Mutations[mutation].Name
	end
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
		for i = 1, #id do
			seed = (seed * 31 + string.byte(id, i)) % 2147483647
		end
		local function nextNumber()
			seed = math.max(1, seed) * 16807 % 2147483647
			return (seed - 1) / 2147483646
		end
		local available = nextNumber() < rule.Chance
		local quantity = rule.Min + math.floor(nextNumber() * (rule.Max - rule.Min + 1))
		offers[id] = { price = def.Price, stock = available and quantity or 0 }
	end
	return { id = tostring(C.Shop.Version) .. ":" .. epoch, endsAt = (epoch + 1) * C.Shop.Seconds, offers = offers }
end
for id, species in pairs(C.Species) do
	local minimum = species.MinimumStrength or 0
	assert(type(minimum) == "number" and minimum >= 0 and minimum < math.huge, "Invalid minimum strength: " .. id)
end
-- Erros de edição do catálogo aparecem na carga, antes de qualquer compra.
for id, def in pairs(C.Upgrades) do
	assert(C.UpgradeGroups[def.Group], "Grupo de upgrade desconhecido: " .. id)
	assert(#def.Values == #def.Costs + 1, "Values precisa conter o nível inicial e todos os upgrades: " .. id)
	for _, value in ipairs(def.Values) do
		assert(type(value) == "number" and value >= 0 and value < math.huge, "Valor inválido: " .. id)
	end
	for _, cost in ipairs(def.Costs) do
		assert(type(cost) == "number" and cost >= 0 and cost < math.huge, "Custo inválido: " .. id)
	end
end
for id, def in pairs(C.Items) do
	if def.Shop then
		local rule = def.Shop
		assert(type(rule.Chance) == "number" and rule.Chance >= 0 and rule.Chance <= 1, "Chance inválida: " .. id)
		assert(
			type(rule.Min) == "number"
				and type(rule.Max) == "number"
				and rule.Min >= 0
				and rule.Max >= rule.Min
				and rule.Min % 1 == 0
				and rule.Max % 1 == 0,
			"Estoque inválido: " .. id
		)
		assert(type(def.Price) == "number" and def.Price >= 0 and def.Price < math.huge, "Preço inválido: " .. id)
	end
end
return C
