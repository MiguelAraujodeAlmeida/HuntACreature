local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local W = require(script.Parent.HUDWidgets)
local Kit = require(script.Parent.MenuKit)
local Cards = require(script.Parent.CreatureCards)
local Page = {}
function Page.Render(ui)
	local p, selling = ui.data.profile, ui.tab == "Venda"
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
	local counts = W.frame(ui.scroll, "Capacity", UDim2.new(1, -2, 0, 38), UDim2.new())
	counts.LayoutOrder, counts.ZIndex = 1, ui.scroll.ZIndex
	Kit.Badge(
		counts,
		"Equipped",
		string.format("Equipped %d/%d", base, C.Stat(p, "Base")),
		UDim2.new(0.5, -6, 1, 0),
		UDim2.new(),
		W.Style.UI.Green
	)
	Kit.Badge(
		counts,
		"Bag",
		string.format("Bag %d/%d", bag, C.Stat(p, "Bolsa")),
		UDim2.new(0.5, -6, 1, 0),
		UDim2.fromScale(0.5, 0),
		W.Style.UI.Cyan
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
		ui.creatureSelected = nil
		Kit.Empty(
			ui.scroll,
			"No creatures here",
			ui.creatureFilter and "Try another filter." or "Your companions will appear here."
		)
		return
	end
	local chosen
	for _, item in ipairs(items) do
		if item.id == ui.creatureSelected then
			chosen = item
		end
	end
	chosen = chosen or items[1]
	ui.creatureSelected = chosen.id
	local detail = Kit.Detail(ui)
	local grid = Kit.Grid(ui.scroll, #items, ui.contentWidth, 152, 184, 4)
	for i, item in ipairs(items) do
		local tile = Cards.Tile(grid, item, true, item.id == chosen.id, "Creature:" .. item.id, function()
			ui.creatureSelected = item.id
			ui.confirm = nil
			ui:Render()
		end, (item.location == "base" and "✓ " or "") .. C.Value(item, "Income") .. " gold/s")
		tile.LayoutOrder = i
	end
	local equipped = chosen.location == "base"
	Cards.Detail(detail, chosen, true, {
		status = string.format("%s · %.2f× size", equipped and "Equipped" or "In bag", chosen.size),
		statusColor = equipped and W.Style.UI.Green or W.Style.UI.Cyan,
	})
	local actions = W.frame(detail, "Actions", UDim2.new(1, -2, 0, 60), UDim2.new())
	actions.ZIndex = detail.ZIndex
	Kit.Action(actions, "Favorite:" .. chosen.id, chosen.favorite and "★" or "☆", function()
		ui.confirm = nil
		ui:Send("SetFavorite", chosen.id, { value = not chosen.favorite })
	end, UDim2.fromOffset(54, 54), UDim2.new(), chosen.favorite and W.Style.UI.Gold or Kit.Theme.Surface)
	local caption = equipped and "Unequip" or "Equip"
	if selling then
		caption = chosen.favorite and "★ Protected"
			or ((ui.confirm == chosen.id and "Confirm · " or "Sell · ") .. C.Value(chosen, "Sale") .. " gold")
	end
	local action = Kit.Action(actions, (selling and "Sell:" or "Equip:") .. chosen.id, caption, function()
		if selling then
			if chosen.favorite then
				return
			end
			if ui.confirm == chosen.id then
				ui:Send("Sell", chosen.id)
				ui.confirm = nil
			else
				ui.confirm = chosen.id
				ui:Render()
			end
		else
			ui:Send(equipped and "Unequip" or "Equip", chosen.id)
		end
	end, UDim2.new(1, -66, 0, 54), UDim2.fromOffset(66, 0), selling and W.Style.UI.Gold or W.Style.UI.Green)
	if selling and chosen.favorite then
		action.Root.Interactable = false
		action.caption.TextTransparency = 0.3
	end
	if selling and ui.confirm == chosen.id then
		local cancel = Kit.Action(detail, "CancelSale", "Cancel sale", function()
			ui.confirm = nil
			ui:Render()
		end, nil, nil, Kit.Theme.Surface)
		cancel.Root.LayoutOrder = 2
	end
end
return Page
