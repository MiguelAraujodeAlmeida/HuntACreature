local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
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
	for _, id in ipairs(C.ShopIds()) do
		local def = C.Items[id]
		if ui.shopCategory ~= def.Category then
			continue
		end
		local offer = ui.data.rotation.offers[id]
		local price = offer and offer.price or def.Price
		local stock = offer and offer.stock or 0
		local bought = C.Bought(ui.data.profile, ui.data.rotation, id)
		local owned = def.Permanent and ui.data.profile.owned[id]
		local state = owned and "Owned"
			or stock == 0 and "Sold out"
			or string.format("Stock: %d/%d", math.max(0, stock - bought), stock)
		local description = def.Description
		if not def.Permanent then
			local seconds = def.EffectSeconds or def.Duration
			description ..= (seconds and "\nDuration: " .. seconds .. " s" or "")
			if def.Cooldown then
				description ..= " • cooldown: " .. def.Cooldown .. " s"
			end
		end
		description ..= "\n" .. state
		if def.Permanent then
			local config = require(game.ReplicatedStorage.HACShared.CaptureConfig)
			local lasso = config.Lassos[def.Name]
			if lasso then
				description ..= string.format(
					"\nRange: %d studs • Full charge: %.1f s",
					lasso.MaximumRange,
					lasso.ChargeSeconds
				)
			end
		else
			description ..= "\nOwned: " .. tostring(ui.data.profile.items[id] or 0)
		end
		local card = ui:Card(def.Name, description, 206)
		if def.Permanent then
			local W = require(script.Parent.HUDWidgets)
			W.icon(card, "Lasso", W.Style.Icons.Lasso, UDim2.fromOffset(40, 40), UDim2.new(1, -48, 0, 0))
			card.Texto.Size = UDim2.new(1, -58, 0, 38)
		end
		local rotation = ui.data.rotation.id
		ui:PurchaseButton(card, "Buy:" .. id, "Buy • " .. price .. " gold", function()
			local current = ui.data.profile
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
