local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Page = {}
function Page.Render(ui)
	ui.pageTitle="Loja de caça"
	ui:Text("Mesmo estoque inicial para todos. As compras usam somente a sua cota.",48)
	local categories,seen={"Todas"},{Todas=true}
	for _,id in ipairs(C.ShopIds()) do
		local category=C.Items[id].Category or "Outros"
		if not seen[category] then seen[category]=true; table.insert(categories,category) end
	end
	local categoryIndex=table.find(categories,ui.shopCategory) or 1
	ui.shopCategory=categories[categoryIndex]
	ui:InlineAction("ShopCategory","Categoria: " .. ui.shopCategory .. "  ›",function()
		ui.shopCategory=categories[categoryIndex % #categories + 1]; ui:Render()
	end)
	for _,id in ipairs(C.ShopIds()) do
		local def=C.Items[id]
		if ui.shopCategory~="Todas" and ui.shopCategory~=(def.Category or "Outros") then continue end
		local offer=ui.data.rotation.offers[id]
		local price=offer and offer.price or def.Price
		local stock=offer and offer.stock or 0
		local bought=C.Bought(ui.data.profile,ui.data.rotation,id)
		local owned=def.Permanent and ui.data.profile.owned[id]
		local state=owned and "Adquirido • permanente" or stock==0 and "Sem estoque nesta reposição"
			or string.format("Sua cota: %d restante(s) de %d",math.max(0,stock-bought),stock)
		local description=def.Description
		if not def.Permanent then
			local seconds=def.EffectSeconds or def.Duration
			description ..= "\n1 uso por unidade" .. (seconds and " • efeito: " .. seconds .. " s" or "")
			if def.Cooldown then description ..= " • recarga: " .. def.Cooldown .. " s" end
		end
		description ..= "\n" .. state .. "\nPreço: " .. price .. " ouro"
		local card=ui:Card(def.Name .. " • " .. (def.Category or "Outros"),description,206)
		local rotation=ui.data.rotation.id
		ui:PurchaseButton(card,"Buy:" .. id,"Comprar • " .. price .. " ouro",function()
			local current=ui.data.profile
			if def.Permanent and current.owned[id] then return "Adquirido" end
			if workspace:GetServerTimeNow()>=ui.data.rotation.endsAt then return "Atualizando estoque…" end
			if stock==0 then return "Sem estoque" end
			if C.Bought(current,ui.data.rotation,id)>=stock then return "Sua cota acabou" end
			if not def.Permanent and (current.items[id] or 0)>=C.ItemCapacity(id) then return "Limite de unidades atingido" end
			if not ui:NearShop() then return "Aproxime-se da loja no hub" end
			if current.gold<price then return "Faltam " .. (price-current.gold) .. " ouro" end
		end,function() ui:Send("Buy",id,{rotation=rotation}) end)
	end
end
return Page
