local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Page = {}
function Page.Render(ui)
	local p = ui.data.profile
	local selling = ui.tab == "Venda"
	ui.pageTitle = selling and "Vender criaturas" or "Criaturas"
	local items, bag, base = {}, 0, 0
	for _, item in pairs(p.creatures) do
		if item.location == "base" then
			base += 1
		else
			bag += 1
		end
		if not ui.creatureFilter or item.location == ui.creatureFilter then
			table.insert(items, item)
		end
	end
	ui:Text(string.format("Equipadas %d/%d   •   Bolsa %d/%d", base, C.Stat(p, "Base"), bag, C.Stat(p, "Bolsa")), 32)
	local filter = ui.creatureFilter == "base" and "Equipadas" or ui.creatureFilter == "bag" and "Na bolsa" or "Todas"
	ui:InlineAction("CreatureFilter", filter .. "  ›", function()
		ui.creatureFilter = not ui.creatureFilter and "base" or ui.creatureFilter == "base" and "bag" or nil
		ui.confirm = nil
		ui:Render()
	end)
	table.sort(items, function(a, b)
		if a.location ~= b.location then
			return a.location == "base"
		end
		if C.Value(a, "Income") ~= C.Value(b, "Income") then
			return C.Value(a, "Income") > C.Value(b, "Income")
		end
		return a.id < b.id
	end)
	if #items == 0 then
		ui:Text("Nenhuma criatura aqui", 48)
	end
	for _, item in ipairs(items) do
		local equipped = item.location == "base"
		local status = equipped and "Equipada" or "Na bolsa"
		local summary = string.format(
			"%s • %.2f× • %s\n%d ouro/s  •  %d XP/s",
			item.rarity,
			item.size,
			status,
			C.Value(item, "Income"),
			C.Value(item, "XP")
		)
		local card = ui:Card(C.Name(item), summary, 148)
		if selling then
			local value = C.Value(item, "Sale")
			ui:ActionButton(
				card,
				"Sell:" .. item.id,
				(ui.confirm == item.id and "Confirmar • " or "Vender • ") .. value .. " ouro",
				function()
					if ui.confirm == item.id then
						ui:Send("Sell", item.id)
						ui.confirm = nil
					else
						ui.confirm = item.id
						ui:Render()
					end
				end,
				UDim2.new(1, -12, 0, 40),
				UDim2.new(0, 6, 1, -46)
			)
		else
			ui:ActionButton(card, "Equip:" .. item.id, equipped and "Desequipar" or "Equipar", function()
				ui:Send(equipped and "Unequip" or "Equip", item.id)
			end, UDim2.new(1, -12, 0, 40), UDim2.new(0, 6, 1, -46))
		end
	end
end
return Page
