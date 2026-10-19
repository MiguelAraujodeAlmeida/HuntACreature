-- A descoberta é permanente; a posse atual é calculada separadamente.
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local W = require(script.Parent.HUDWidgets)
local Page = {}
function Page.Render(ui)
	ui.pageTitle="Index de criaturas"
	local p=ui.data.profile
	local ids,found,owned={},0,{}
	for _,item in pairs(p.creatures) do owned[item.species]=(owned[item.species] or 0)+1 end
	for _,id in ipairs(C.OrderedIds(C.Species)) do
		if p.discoveries[id] then found+=1 end
		if not ui.indexRarity or C.Species[id].Rarity==ui.indexRarity then table.insert(ids,id) end
	end
	table.sort(ids,function(a,b)
		local ar=table.find(C.Rarities,C.Species[a].Rarity) or math.huge
		local br=table.find(C.Rarities,C.Species[b].Rarity) or math.huge
		return ar==br and a<b or ar<br
	end)
	ui:Text("Descobertas: " .. found .. "/" .. #C.OrderedIds(C.Species) .. " • vender não apaga descobertas",48)
	ui:InlineAction("IndexRarity","Raridade: " .. (ui.indexRarity or "Todas") .. "  ›",function()
		local index=ui.indexRarity and table.find(C.Rarities,ui.indexRarity) or 0
		ui.indexRarity=C.Rarities[index+1]; ui.indexPage=1; ui:Render()
	end)
	local pages=math.max(1,math.ceil(#ids/C.Index.PageSize))
	ui.indexPage=math.clamp(ui.indexPage or 1,1,pages)
	if pages>1 then
		local row=W.frame(ui.scroll,"Paginacao",UDim2.new(1,-8,0,44),UDim2.new())
		ui:ActionButton(row,"IndexPrevious","‹",function() ui.indexPage=math.max(1,ui.indexPage-1); ui:Render() end,UDim2.new(0.2,0,1,0),UDim2.new())
		W.text(row,"Pagina",ui.indexPage .. " / " .. pages,UDim2.new(0.6,0,1,0),UDim2.new(0.2,0,0,0),18)
		ui:ActionButton(row,"IndexNext","›",function() ui.indexPage=math.min(pages,ui.indexPage+1); ui:Render() end,UDim2.new(0.2,0,1,0),UDim2.new(0.8,0,0,0))
	end
	if #ids==0 then ui:Text("Nenhuma espécie cadastrada nesta raridade ainda.",60) end
	for i=(ui.indexPage-1)*C.Index.PageSize+1,math.min(#ids,ui.indexPage*C.Index.PageSize) do
		local id=ids[i]
		local def=C.Species[id]
		local discovered=p.discoveries[id]
		local description=discovered and (def.Description or "Uma espécie registrada na sua coleção.") or "Capture esta espécie para revelar sua ficha."
		if discovered then
			description ..= "\n\nEspécie • " .. def.Rarity .. "\nExemplar padrão: " .. def.Sale .. " ouro • renda " .. def.Income .. " / " .. C.IncomeSeconds .. " s"
			description ..= "\nEm sua coleção agora: " .. (owned[id] or 0) .. "\nTamanho e mutações alteram cada exemplar."
		end
		local card=ui:Card(discovered and def.Name or "???",description,discovered and 235 or 140)
		card.Texto.Size=UDim2.new(1,-76,0,38)
		if def.Icon then
			local icon=W.icon(card,"Retrato",def.Icon,UDim2.fromOffset(50,50),UDim2.new(1,-60,0,6))
			icon.ImageColor3=discovered and Color3.new(1,1,1) or Color3.new(0,0,0)
		else
			W.text(card,"Estado",discovered and "✓" or "?",UDim2.fromOffset(40,38),UDim2.new(1,-50,0,2),24)
		end
	end
end
return Page
