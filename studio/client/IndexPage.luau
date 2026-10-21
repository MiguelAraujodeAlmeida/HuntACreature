-- Discovery history is independent of currently owned creatures.
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local W = require(script.Parent.HUDWidgets)
local Kit = require(script.Parent.MenuKit)
local Cards = require(script.Parent.CreatureCards)
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
		if ui.indexVariant == "All" then
			return p.discoveries[id] == true
		end
		return (p.variantDiscoveries or {})[id .. ":" .. ui.indexVariant] == true
	end
	local function itemFor(id)
		return {
			species = id,
			rarity = C.Species[id].Rarity,
			size = 1,
			mutations = (ui.indexVariant == "All" or ui.indexVariant == "Normal") and {} or { ui.indexVariant },
		}
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
	local progress = Kit.Surface(ui.scroll, "DiscoveryProgress", UDim2.new(1, -2, 0, 78), UDim2.new(), Kit.Theme.Body)
	progress.LayoutOrder = 1
	Kit.Label(
		progress,
		"Count",
		string.format("%d / %d discovered", found, #all),
		UDim2.new(1, -180, 0, 38),
		UDim2.fromOffset(12, 2),
		22,
		nil,
		Enum.TextXAlignment.Left
	)
	Kit.Action(progress, "Rarity", C.RarityNames[ui.indexRarity] or "All rarities", function()
		local index = ui.indexRarity and table.find(C.Rarities, ui.indexRarity) or 0
		ui.indexRarity = C.Rarities[index + 1]
		ui.indexPage = 1
		ui.indexSelected = nil
		ui:Render()
	end, UDim2.fromOffset(150, 36), UDim2.new(1, -158, 0, 3), Kit.Theme.Surface)
	local track, fill =
		W.bar(progress, "Progress", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(12, 48), W.Style.UI.Green)
	track.ZIndex = progress.ZIndex + 2
	fill.Size = UDim2.fromScale(#all > 0 and found / #all or 0, 1)
	if #ids == 0 then
		Kit.Empty(ui.scroll, "No entries", "Try another rarity.")
		return
	end
	local pages = math.max(1, math.ceil(#ids / C.Index.PageSize))
	ui.indexPage = math.clamp(ui.indexPage or 1, 1, pages)
	local first = (ui.indexPage - 1) * C.Index.PageSize + 1
	local last = math.min(#ids, ui.indexPage * C.Index.PageSize)
	local chosen = ui.indexSelected
	if not chosen or not table.find(ids, chosen) then
		chosen = ids[first]
	end
	ui.indexSelected = chosen
	local detail = Kit.Detail(ui)
	Cards.Detail(
		detail,
		itemFor(chosen),
		discovered(chosen),
		{ index = true, status = discovered(chosen) and "Owned: " .. (owned[chosen] or 0) or "Not discovered yet" }
	)
	local grid = Kit.Grid(ui.scroll, last - first + 1, ui.contentWidth, 148, 184, 4)
	for i = first, last do
		local id = ids[i]
		local tile = Cards.Tile(grid, itemFor(id), discovered(id), chosen == id, "Index:" .. id, function()
			ui.indexSelected = id
			ui:Render()
		end)
		tile.LayoutOrder = i
	end
	if pages > 1 then
		local row = ui:Tabs(
			"Pages",
			{ { id = "prev", name = "‹" }, { id = "current", name = ui.indexPage .. " / " .. pages }, {
				id = "next",
				name = "›",
			} },
			"current",
			function(id)
				ui.indexPage = math.clamp(ui.indexPage + (id == "next" and 1 or id == "prev" and -1 or 0), 1, pages)
				ui.indexSelected = nil
				ui:Render()
			end
		)
		row.LayoutOrder = 5
	end
end
return Page
