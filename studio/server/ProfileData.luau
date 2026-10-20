-- Operações síncronas: nenhuma pode ceder execução no meio de uma transferência.
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Data = {}
function Data.Copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for k, v in pairs(value) do
		result[k] = Data.Copy(v)
	end
	return result
end
function Data.New()
	return {
		schemaVersion = C.SchemaVersion,
		revision = 0,
		gold = 0,
		xp = 0,
		strength = 0,
		creatures = {},
		discoveries = {},
		variantDiscoveries = {},
		settings = Data.Copy(C.Settings),
		upgrades = {},
		items = Data.Copy(C.StartingItems),
		owned = Data.Copy(C.StartingEquipment),
		shop = { rotation = "", bought = {} },
	}
end
function Data.Validate(p)
	assert(type(p) == "table" and p.schemaVersion == C.SchemaVersion, "Versão de perfil incompatível")
	-- Additive migration: keep existing IDs, balances, creatures and discoveries.
	p.settings = p.settings or Data.Copy(C.Settings)
	p.variantDiscoveries = p.variantDiscoveries or {}
	assert(type(p.settings) == "table" and type(p.variantDiscoveries) == "table", "Invalid preferences")
	for id, discovered in pairs(p.variantDiscoveries) do
		assert(type(id) == "string" and type(discovered) == "boolean", "Invalid discovery")
	end
	for key, default in pairs(C.Settings) do
		if p.settings[key] == nil then
			p.settings[key] = default
		end
		assert(type(p.settings[key]) == "boolean", "Invalid setting")
	end
	for _, key in ipairs({ "gold", "xp", "strength", "revision" }) do
		assert(type(p[key]) == "number" and p[key] >= 0 and p[key] < math.huge, "Valor inválido: " .. key)
	end
	for _, key in ipairs({ "creatures", "discoveries", "upgrades", "items", "owned", "shop" }) do
		assert(type(p[key]) == "table", "Campo inválido: " .. key)
	end
	for key, def in pairs(C.Upgrades) do
		local level = p.upgrades[key] or 0
		assert(type(level) == "number" and level % 1 == 0 and level >= 0 and level < #def.Values, "Upgrade inválido")
	end
	local slots = {}
	for id, item in pairs(p.creatures) do
		assert(type(id) == "string" and item.id == id and C.Species[item.species], "Criatura inválida")
		assert(
			table.find(C.Rarities, item.rarity)
				and type(item.size) == "number"
				and item.size >= 0.5
				and item.size <= C.Size.Maximum,
			"Variação inválida"
		)
		-- Existing 0.85× specimens become 1×; retain IDs, location and mutations.
		item.size = math.max(C.Size.Minimum, item.size)
		assert(type(item.mutations) == "table", "Mutações inválidas")
		for _, mutation in ipairs(item.mutations) do
			assert(C.Mutations[mutation], "Mutação desconhecida")
		end
		assert(item.location == "bag" or item.location == "base", "Localização inválida")
		assert(item.favorite == nil or type(item.favorite) == "boolean", "Invalid favorite")
		p.variantDiscoveries[C.VariantKey(item)] = true
		if item.location == "base" then
			assert(
				type(item.slot) == "number"
					and item.slot % 1 == 0
					and item.slot >= 1
					and item.slot <= C.Stat(p, "Base")
					and not slots[item.slot],
				"Slot inválido"
			)
			slots[item.slot] = true
		end
	end
	for key, value in pairs(p.items) do
		assert(
			C.Items[key] and type(value) == "number" and value % 1 == 0 and value >= 0 and value <= C.ItemCapacity(key),
			"Itens inválidos"
		)
	end
	assert(type(p.shop.rotation) == "string" and type(p.shop.bought) == "table", "Cota inválida")
	return p
end
function Data.Count(p, location)
	local count = 0
	for _, item in pairs(p.creatures) do
		if item.location == location then
			count += 1
		end
	end
	return count
end
function Data.FreeSlot(p)
	local used = {}
	for _, item in pairs(p.creatures) do
		if item.location == "base" then
			used[item.slot] = true
		end
	end
	for slot = 1, C.Stat(p, "Base") do
		if not used[slot] then
			return slot
		end
	end
end
function Data.Capture(p, creature)
	if p.strength < C.MinimumStrength(creature.species) then
		return false, "Not enough strength."
	end
	if p.creatures[creature.id] or Data.Count(p, "bag") >= C.Stat(p, "Bolsa") then
		return false, "Bag full."
	end
	local item = Data.Copy(creature)
	item.location, item.slot = "bag", nil
	p.creatures[item.id] = item
	local first = not p.discoveries[item.species]
	p.discoveries[item.species] = true
	p.variantDiscoveries = p.variantDiscoveries or {}
	p.variantDiscoveries[C.VariantKey(item)] = true
	return true, first and "New discovery!" or "Creature captured!"
end
function Data.Action(p, action, args, rotation)
	local item = type(args.id) == "string" and p.creatures[args.id]
	if action == "SetSetting" then
		if C.Settings[args.id] == nil or type(args.value) ~= "boolean" then
			return false, "Invalid setting."
		end
		p.settings = p.settings or Data.Copy(C.Settings)
		p.settings[args.id] = args.value
	elseif action == "SetFavorite" then
		if not item or type(args.value) ~= "boolean" then
			return false, "Invalid favorite."
		end
		item.favorite = args.value
	elseif action == "Equip" then
		local slot = Data.FreeSlot(p)
		if not item or item.location ~= "bag" then
			return false, "Choose a creature from your bag."
		end
		if not slot then
			return false, "Base full. Unequip a creature first."
		end
		item.location, item.slot = "base", slot
	elseif action == "Sell" then
		if not item then
			return false, "This creature is unavailable."
		end
		if item.favorite then
			return false, "Unfavorite this creature before selling."
		end
		p.gold += C.Value(item, "Sale")
		p.creatures[item.id] = nil
	elseif action == "Unequip" then
		if not item or item.location ~= "base" then
			return false, "Creature is not equipped."
		end
		if Data.Count(p, "bag") >= C.Stat(p, "Bolsa") then
			return false, "Bag full. Free a slot before unequipping."
		end
		item.location, item.slot = "bag", nil
	elseif action == "Upgrade" then
		local def = C.Upgrades[args.id]
		if not def then
			return false, "Invalid upgrade."
		end
		local level = p.upgrades[args.id] or 0
		local cost = def.Costs[level + 1]
		if not cost then
			return false, "Maximum level."
		end
		if p.gold < cost then
			return false, "Not enough gold."
		end
		p.gold -= cost
		p.upgrades[args.id] = level + 1
	elseif action == "Buy" then
		if args.rotation ~= rotation.id then
			return false, "Stock changed. Check the new offer."
		end
		local offer, def = rotation.offers[args.id], C.Items[args.id]
		if not offer or not def then
			return false, "Item unavailable in this rotation."
		end
		if def.Permanent and p.owned[args.id] then
			return false, "You already own this equipment."
		end
		local bought = C.Bought(p, rotation, args.id)
		if offer.stock <= 0 then
			return false, "Out of stock."
		end
		if bought >= offer.stock then
			return false, "Purchase limit reached for this restock."
		end
		if not def.Permanent and (p.items[args.id] or 0) >= C.ItemCapacity(args.id) then
			return false, "Tool capacity reached."
		end
		if p.gold < offer.price then
			return false, "Not enough gold."
		end
		if p.shop.rotation ~= rotation.id then
			p.shop = {
				rotation = rotation.id,
				bought = C.SameShopWindow(p.shop.rotation, rotation.id) and p.shop.bought or {},
			}
		end
		p.gold -= offer.price
		p.shop.bought[args.id] = bought + 1
		if def.Permanent then
			p.owned[args.id] = true
		else
			p.items[args.id] = (p.items[args.id] or 0) + 1
		end
	else
		return false, "Invalid action."
	end
	local message = nil -- Sucesso é mostrado no cartão/placa e pelo feedback de ação.
	return true, message
end
return Data
