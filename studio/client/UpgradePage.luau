-- Uma compra melhora somente o ID selecionado. Grupos definem contexto/acesso.
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Page = {}
local function number(value)
	return string.format("%.2f",value):gsub("0+$",""):gsub("%.$","")
end
function Page.Render(ui)
	local group = C.UpgradeGroups[ui.upgradeGroup]
	if not group then ui:Text("Escolha uma melhoria na bolsa, na base ou no manequim.",60); return end
	ui.pageTitle = group.Name
	if ui.upgradeGroup=="Bolsa" or ui.upgradeGroup=="Base" then
		ui:InlineAction("BackToCollection","‹ Voltar à " .. ui.upgradeGroup:lower(),function() ui:Open(ui.upgradeGroup) end)
	end
	local ids = C.UpgradesIn(ui.upgradeGroup)
	if not table.find(ids,ui.upgradeId) then ui.upgradeId=ids[1] end
	if #ids>1 then
		ui:Text("Escolha o que deseja melhorar. Cada compra evolui apenas uma opção.",48)
		for _,id in ipairs(ids) do
			local skin=ui:InlineAction("ChooseUpgrade:" .. id,C.Upgrades[id].Name,function()
				ui.upgradeId=id; ui:Render()
			end)
			skin:SetSelected(id==ui.upgradeId)
		end
	end
	local id=ui.upgradeId
	if not id then ui:Text("Nenhuma melhoria cadastrada aqui.",48); return end
	local def=C.Upgrades[id]
	local p=ui.data.profile
	local preview=C.UpgradePreview(p,id)
	local description=def.Description .. "\n\nAtual: " .. number(preview.current) .. " " .. def.Unit
	if preview.next then description ..= "\nPróximo: " .. number(preview.next) .. " " .. def.Unit
	else description ..= "\nMelhoria concluída." end
	if def.Group=="Treino" then
		description ..= "\n\nResultado: +" .. number(C.TrainingGain(p)) .. " força / " .. C.TrainingSeconds .. " s"
		if preview.next then description ..= " → +" .. number(C.TrainingGain(p,id)) end
	end
	local card=ui:Card(def.Name .. " • nível " .. preview.level,description,def.Group=="Treino" and 270 or 220)
	if preview.cost then
		ui:PurchaseButton(card,"Upgrade:" .. id,"Melhorar • " .. preview.cost .. " ouro",function()
			local reason=ui:UpgradeUnavailable(id)
			if reason then return reason end
			if ui.data.profile.gold<preview.cost then return "Faltam " .. (preview.cost-ui.data.profile.gold) .. " ouro" end
		end,function() ui:Send("Upgrade",id) end)
	end
	if def.Group=="Treino" then
		ui:Text("Manequim = ganho básico. Eficiência = multiplicador. O treino continua sendo feito com seu laço.",64)
	end
end
return Page
