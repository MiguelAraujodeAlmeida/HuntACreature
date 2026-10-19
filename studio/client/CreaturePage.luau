local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Portrait = require(script.Parent.CreaturePortrait)
local W = require(script.Parent.HUDWidgets)
local Page = {}
function Page.Render(ui)
	local p = ui.data.profile
	local selling = ui.tab == "Venda"
	ui.pageTitle = selling and "Creature Market" or "Creatures"
	local items, bag, base = {}, 0, 0
	for _, item in pairs(p.creatures) do
		if item.location == "base" then
			base += 1
		else
			bag += 1
		end
		if
			not ui.creatureFilter
			or item.location == ui.creatureFilter
			or (ui.creatureFilter == "favorite" and item.favorite)
		then
			table.insert(items, item)
		end
	end
	ui:Text(string.format("Equipped %d/%d   •   Bag %d/%d", base, C.Stat(p, "Base"), bag, C.Stat(p, "Bolsa")), 32)
	ui:Tabs(
		"CreatureFilter",
		{ { id = "all", name = "All" }, { id = "base", name = "Equipped" }, { id = "bag", name = "Bag" }, {
			id = "favorite",
			name = "★",
		} },
		ui.creatureFilter or "all",
		function(id)
			ui.creatureFilter = id ~= "all" and id or nil
			ui.confirm = nil
			ui:Render()
		end
	)
	table.sort(items, function(a, b)
		if (a.favorite == true) ~= (b.favorite == true) then
			return a.favorite == true
		end
		if a.location ~= b.location then
			return a.location == "base"
		end
		if C.Value(a, "Income") ~= C.Value(b, "Income") then
			return C.Value(a, "Income") > C.Value(b, "Income")
		end
		return a.id < b.id
	end)
	if #items == 0 then
		ui:Text("No creatures here yet", 48)
	end
	for _, item in ipairs(items) do
		local equipped = item.location == "base"
		local summary = string.format(
			"%s • %.2f×\n%d gold/s   •   %d XP/s",
			C.RarityNames[item.rarity] or item.rarity,
			item.size,
			C.Value(item, "Income"),
			C.Value(item, "XP")
		)
		local card = ui:Card(C.Name(item), summary, 188)
		card.Texto.Position, card.Texto.Size = UDim2.fromOffset(110, 8), UDim2.new(1, -126, 0, 34)
		card.Descricao.Position, card.Descricao.Size = UDim2.fromOffset(110, 46), UDim2.new(1, -126, 0, 58)
		card.Descricao.TextXAlignment = Enum.TextXAlignment.Left
		Portrait.new(card, item, true, UDim2.fromOffset(100, 110), UDim2.fromOffset(6, 6))
		local status = W.text(
			card,
			"Location",
			equipped and "EQUIPPED" or "IN BAG",
			UDim2.new(1, -126, 0, 24),
			UDim2.fromOffset(110, 102),
			12,
			equipped and W.Style.UI.Green or W.Style.UI.Cyan,
			Enum.TextXAlignment.Left
		)
		local favorite = ui:ActionButton(card, "Favorite:" .. item.id, item.favorite and "★" or "☆", function()
			ui.confirm = nil
			ui:Send("SetFavorite", item.id, { value = not item.favorite })
		end, UDim2.fromOffset(48, 42), UDim2.new(1, -56, 1, -50))
		favorite:SetSelected(item.favorite == true)
		local caption = equipped and "Unequip" or "Equip"
		if selling then
			caption = item.favorite and "★ Protected"
				or ((ui.confirm == item.id and "Confirm • " or "Sell • ") .. C.Value(item, "Sale") .. " gold")
		end
		local action = ui:ActionButton(card, (selling and "Sell:" or "Equip:") .. item.id, caption, function()
			if selling then
				if item.favorite then
					return
				end
				if ui.confirm == item.id then
					ui:Send("Sell", item.id)
					ui.confirm = nil
				else
					ui.confirm = item.id
					ui:Render()
				end
			else
				ui:Send(equipped and "Unequip" or "Equip", item.id)
			end
		end, UDim2.new(1, -70, 0, 42), UDim2.new(0, 6, 1, -50))
		if selling and item.favorite then
			action.Root.Interactable = false
			action.caption.TextTransparency = 0.3
		end
	end
end
return Page
