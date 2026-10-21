local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Rank = require(game.ReplicatedStorage.HACShared.HunterProgression)
local W = require(script.Parent.HUDWidgets)
local Kit = require(script.Parent.MenuKit)
local Art = require(script.Parent.ToolPortrait)
local Page = {}
function Page.Render(ui)
	ui.pageTitle = "Hunting Shop"
	ui.shopCategory = ui.shopCategory == "Lassos" and "Lassos" or "Tools"
	ui:Tabs(
		"ShopCategory",
		{ { id = "Tools", name = "Tools" }, { id = "Lassos", name = "Lassos" } },
		ui.shopCategory,
		function(id)
			ui.shopCategory = id
			ui:Render()
		end
	)
	local hero = Kit.Surface(
		ui.scroll,
		"CategoryBanner",
		UDim2.new(1, -2, 0, 90),
		UDim2.new(),
		Kit.Theme.Page("Loja").Accent:Lerp(Kit.Theme.Ink, 0.6)
	)
	hero.LayoutOrder = 1
	local icon = W.icon(hero, "Lasso", W.Style.Icons.Lasso, UDim2.fromOffset(74, 74), UDim2.fromOffset(10, 8))
	icon.ZIndex = hero.ZIndex + 1
	local title = Kit.Label(
		hero,
		"Headline",
		ui.shopCategory == "Lassos" and "Find your reach" or "Ready for the hunt",
		UDim2.new(1, -124, 0, 48),
		UDim2.fromOffset(100, 4),
		30,
		nil,
		Enum.TextXAlignment.Left
	)
	title.TextScaled = true
	local cap = Instance.new("UITextSizeConstraint")
	cap.MinTextSize, cap.MaxTextSize, cap.Parent = 18, 30, title
	Kit.Label(
		hero,
		"Subheading",
		ui.shopCategory == "Lassos" and "Range · charge · control" or "Lure. Slow. Capture.",
		UDim2.new(1, -124, 0, 34),
		UDim2.fromOffset(100, 49),
		17,
		Kit.Theme.Muted,
		Enum.TextXAlignment.Left
	)
	local ids = {}
	for _, id in ipairs(C.ShopIds()) do
		if C.Items[id].Category == ui.shopCategory then
			table.insert(ids, id)
		end
	end
	local grid = Kit.Grid(ui.scroll, #ids, ui.contentWidth, 234, 330, 2)
	for order, id in ipairs(ids) do
		local def = C.Items[id]
		local offer = ui.data.rotation.offers[id]
		local price, stock = offer and offer.price or def.Price, offer and offer.stock or 0
		local bought = C.Bought(ui.data.profile, ui.data.rotation, id)
		local owned = def.Permanent and ui.data.profile.owned[id]
		local requiredRank = def.RequiredHunterRank or 1
		local theme = Kit.Theme.Tools[id] or { Accent = W.Style.UI.Cyan, Tag = "GEAR" }
		local card = Kit.Surface(grid, "Offer_" .. id, UDim2.new(), UDim2.new(), Kit.Theme.Surface)
		card.LayoutOrder = order
		local stage = Kit.Surface(
			card,
			"ArtStage",
			UDim2.new(1, -16, 0, 146),
			UDim2.fromOffset(8, 8),
			theme.Accent:Lerp(Kit.Theme.Ink, 0.48)
		)
		Art.new(stage, id, UDim2.new(1, -8, 1, -8), UDim2.fromOffset(4, 4),
			Rank.Level(ui.data.profile.xp) < (def.RequiredHunterRank or 1))
		Kit.Badge(stage, "Type", theme.Tag, UDim2.fromOffset(82, 24), UDim2.fromOffset(6, 6), theme.Accent)
		Kit.Badge(
			stage,
			"Stock",
			owned and "OWNED" or stock - bought <= 0 and "SOLD OUT" or tostring(stock - bought) .. " LEFT",
			UDim2.fromOffset(96, 24),
			UDim2.new(1, -102, 1, -30),
			stock - bought > 0 and W.Style.UI.Green or Kit.Theme.Muted
		)
		Kit.Label(card, "Name", def.Name, UDim2.new(1, -16, 0, 34), UDim2.fromOffset(8, 158), 23)
		Kit.Label(
			card,
			"Description",
			def.Description,
			UDim2.new(1, -20, 0, 44),
			UDim2.fromOffset(10, 194),
			15,
			Kit.Theme.Muted
		)
		local stats
		if def.Permanent then
			local lasso = require(game.ReplicatedStorage.HACShared.CaptureConfig).Lassos[def.Name]
			stats = lasso and string.format("%d studs · %.1f s charge", lasso.MaximumRange, lasso.ChargeSeconds)
				or "Permanent"
		else
			stats = string.format(
				"%d s effect · Owned %d",
				def.EffectSeconds or def.Duration or 0,
				ui.data.profile.items[id] or 0
			)
		end
		Kit.Label(card, "Stats", stats .. (requiredRank > 1 and " · RANK " .. requiredRank or ""),
			UDim2.new(1, -16, 0, 28), UDim2.fromOffset(8, 239), 14, theme.Accent)
		local rotation = ui.data.rotation.id
		ui:PurchaseButton(card, "Buy:" .. id, "Buy · " .. price .. " gold", function()
			local current = ui.data.profile
			if Rank.Level(current.xp) < requiredRank then
				return "Requires Hunter Rank " .. requiredRank
			end
			if def.Permanent and current.owned[id] then
				return "Owned"
			end
			if workspace:GetServerTimeNow() >= ui.data.rotation.endsAt then
				return "Refreshing stock…"
			end
			if stock == 0 then
				return "Sold out"
			end
			if C.Bought(current, ui.data.rotation, id) >= stock then
				return "Purchase limit reached"
			end
			if not def.Permanent and (current.items[id] or 0) >= C.ItemCapacity(id) then
				return "Capacity reached"
			end
			if not ui:NearShop() then
				return "Move closer to the shop"
			end
			if current.gold < price then
				return "Need " .. (price - current.gold) .. " gold"
			end
		end, function()
			ui:Send("Buy", id, { rotation = rotation })
		end)
	end
end
return Page
