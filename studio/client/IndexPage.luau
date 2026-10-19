-- Discovery history persists separately from current ownership.
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local W = require(script.Parent.HUDWidgets)
local Portrait = require(script.Parent.CreaturePortrait)
local Page = {}
function Page.Render(ui)
	ui.pageTitle = "Creature Index"
	local p, ids, found, owned = ui.data.profile, {}, 0, {}
	local variants = { { id = "All", name = "All" }, { id = "Normal", name = "Normal" } }
	for _, id in ipairs(C.OrderedIds(C.Mutations)) do
		table.insert(variants, { id = id, name = C.Mutations[id].Name })
	end
	ui.indexVariant = ui.indexVariant or "All"
	local function discovered(id)
		return ui.indexVariant == "All" and p.discoveries[id]
			or (p.variantDiscoveries or {})[id .. ":" .. ui.indexVariant]
	end
	for _, item in pairs(p.creatures) do
		if ui.indexVariant == "All" or C.VariantKey(item) == item.species .. ":" .. ui.indexVariant then
			owned[item.species] = (owned[item.species] or 0) + 1
		end
	end
	local all = C.OrderedIds(C.Species)
	for _, id in ipairs(all) do
		if discovered(id) then
			found += 1
		end
		if not ui.indexRarity or C.Species[id].Rarity == ui.indexRarity then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		local ar, br = table.find(C.Rarities, C.Species[a].Rarity), table.find(C.Rarities, C.Species[b].Rarity)
		return ar == br and a < b or ar < br
	end)
	ui:Tabs("Variant", variants, ui.indexVariant, function(id)
		ui.indexVariant = id
		ui.indexPage = 1
		ui.indexSelected = nil
		ui:Render()
	end)
	local progress = W.frame(ui.scroll, "DiscoveryProgress", UDim2.new(1, -8, 0, 52), UDim2.new())
	W.text(progress, "Count", string.format("%d / %d discovered", found, #all), UDim2.new(1, 0, 0, 26), UDim2.new(), 18)
	local track, fill = W.bar(progress, "Progress", UDim2.new(1, -16, 0, 12), UDim2.fromOffset(8, 32), W.Style.UI.Green)
	fill.Size = UDim2.fromScale(#all > 0 and found / #all or 0, 1)
	ui:InlineAction("Rarity", "Rarity: " .. (C.RarityNames[ui.indexRarity] or "All") .. "  ›", function()
		local index = ui.indexRarity and table.find(C.Rarities, ui.indexRarity) or 0
		ui.indexRarity = C.Rarities[index + 1]
		ui.indexPage = 1
		ui.indexSelected = nil
		ui:Render()
	end)
	local pages = math.max(1, math.ceil(#ids / C.Index.PageSize))
	ui.indexPage = math.clamp(ui.indexPage or 1, 1, pages)
	if pages > 1 then
		ui:Tabs(
			"Pages",
			{
				{ id = "prev", name = "‹" },
				{ id = "current", name = ui.indexPage .. " / " .. pages },
				{
					id = "next",
					name = "›",
				},
			},
			"current",
			function(id)
				ui.indexPage = math.clamp(ui.indexPage + (id == "next" and 1 or id == "prev" and -1 or 0), 1, pages)
				ui:Render()
			end
		)
	end
	if #ids == 0 then
		ui:Text("No creatures in this rarity", 48)
		return
	end
	local first = (ui.indexPage - 1) * C.Index.PageSize + 1
	local last = math.min(#ids, ui.indexPage * C.Index.PageSize)
	local columns = ui.root.Size.X.Offset < 440 and 2 or 3
	local grid = W.frame(
		ui.scroll,
		"DiscoveryGrid",
		UDim2.new(1, -8, 0, math.ceil((last - first + 1) / columns) * 180),
		UDim2.new()
	)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(1 / columns, -8, 0, 172)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	for i = first, last do
		local id, def = ids[i], C.Species[ids[i]]
		local known = discovered(id) == true
		local tile = W.frame(grid, "Entry_" .. id, UDim2.new(), UDim2.new(), W.Style.UI.Ink, 14)
		tile.LayoutOrder = i
		W.gradient(tile, known and Color3.fromRGB(25, 63, 99) or Color3.fromRGB(16, 26, 49), W.Style.UI.Ink)
		local rim = W.stroke(
			tile,
			ui.indexSelected == id and W.Style.UI.Gold or known and W.Style.UI.Cyan or Color3.fromRGB(56, 68, 91),
			2
		)
		local item = {
			species = id,
			mutations = (ui.indexVariant == "All" or ui.indexVariant == "Normal") and {} or { ui.indexVariant },
		}
		if ui.indexVariant == "All" or ui.indexVariant == "Normal" then
			item.mutations = {}
		end
		local portrait = Portrait.new(tile, item, known, UDim2.new(1, -12, 0, 114), UDim2.fromOffset(6, 0))
		W.text(tile, "Name", known and def.Name or "???", UDim2.new(1, -8, 0, 26), UDim2.fromOffset(4, 109), 18)
		W.text(
			tile,
			"Rarity",
			known and C.RarityNames[def.Rarity] or "Undiscovered",
			UDim2.new(1, -8, 0, 22),
			UDim2.fromOffset(4, 136),
			12,
			known and W.Style.UI.Gold or W.Style.UI.White
		)
		local click = Instance.new("TextButton")
		click.Name = "Details"
		click.Text = ""
		click.BackgroundTransparency = 1
		click.Size = UDim2.fromScale(1, 1)
		click.ZIndex = tile.ZIndex + 3
		click.Parent = tile
		click:SetAttribute("FocusKey", "Index:" .. id)
		local scale = Instance.new("UIScale")
		scale.Parent = tile
		local hoverTween
		local function hover(active)
			portrait:SetAttribute("Hovered", active)
			if hoverTween then
				hoverTween:Cancel()
			end
			hoverTween = game:GetService("TweenService")
				:Create(scale, TweenInfo.new(0.16), { Scale = active and 1.025 or 1 })
			hoverTween:Play()
			rim.Thickness = active and 3 or 2
		end
		click.MouseEnter:Connect(function()
			hover(true)
		end)
		click.MouseLeave:Connect(function()
			hover(false)
		end)
		click.SelectionGained:Connect(function()
			hover(true)
		end)
		click.SelectionLost:Connect(function()
			hover(false)
		end)
		tile.Destroying:Connect(function()
			if hoverTween then
				hoverTween:Cancel()
			end
		end)
		click.Activated:Connect(function()
			require(script.Parent.AudioFeedback).Play("Click")
			ui.indexSelected = id
			ui:Render()
		end)
	end
	local selected = ui.indexSelected or ids[first]
	if selected and C.Species[selected] then
		local def = C.Species[selected]
		local known = discovered(selected)
		local item = {
			species = selected,
			size = 1,
			mutations = (ui.indexVariant == "All" or ui.indexVariant == "Normal") and {} or { ui.indexVariant },
		}
		local details = known
				and string.format(
					"%s\n%d gold/s • %d XP/s • %d gold value\nStrength required: %d • Owned: %d",
					def.Description,
					C.Value(item, "Income"),
					C.Value(item, "XP"),
					C.Value(item, "Sale"),
					C.MinimumStrength(selected),
					owned[selected] or 0
				)
			or "Undiscovered"
		local card = ui:Card(known and C.Name(item) or "???", details, 180)
		card.Descricao.Size = UDim2.new(1, -16, 1, -48)
	end
end
return Page
