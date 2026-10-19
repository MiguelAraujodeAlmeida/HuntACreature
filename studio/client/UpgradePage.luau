-- Uma compra melhora somente o ID selecionado. Grupos definem contexto/acesso.
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Page = {}
local function number(value)
	return string.format("%.2f",value):gsub("0+$",""):gsub("%.$","")
end
function Page.Render(ui)
	local group = C.UpgradeGroups[ui.upgradeGroup]
	if not group then ui:Text("Choose an upgrade at your base.",60); return end
	ui.pageTitle = group.Name
	if ui.upgradeGroup=="Bolsa" or ui.upgradeGroup=="Base" then
		ui:InlineAction("BackToCollection","‹ Back to " .. ui.upgradeGroup:lower(),function() ui:Open(ui.upgradeGroup) end)
	end
	local ids = C.UpgradesIn(ui.upgradeGroup)
	if not table.find(ids,ui.upgradeId) then ui.upgradeId=ids[1] end
	if #ids>1 then
		ui:Text("Choose an upgrade.",48)
		for _,id in ipairs(ids) do
			local skin=ui:InlineAction("ChooseUpgrade:" .. id,C.Upgrades[id].Name,function()
				ui.upgradeId=id; ui:Render()
			end)
			skin:SetSelected(id==ui.upgradeId)
		end
	end
	local id=ui.upgradeId
	if not id then ui:Text("No upgrades here.",48); return end
	local def=C.Upgrades[id]
	local p=ui.data.profile
	local preview=C.UpgradePreview(p,id)
	local description=def.Description .. "\n\nCurrent: " .. number(preview.current) .. " " .. def.Unit
	if preview.next then description ..= "\nNext: " .. number(preview.next) .. " " .. def.Unit
	else description ..= "\nUpgrade complete." end
	if def.Group=="Treino" then
		description ..= "\n\nResult: +" .. number(C.TrainingGain(p)) .. " strength / " .. C.TrainingSeconds .. " s"
		if preview.next then description ..= " → +" .. number(C.TrainingGain(p,id)) end
	end
	local card=ui:Card(def.Name .. " • level " .. preview.level,description,def.Group=="Treino" and 270 or 220)
	if preview.cost then
		ui:PurchaseButton(card,"Upgrade:" .. id,"Upgrade • " .. preview.cost .. " gold",function()
			local reason=ui:UpgradeUnavailable(id)
			if reason then return reason end
			if ui.data.profile.gold<preview.cost then return "Need " .. (preview.cost-ui.data.profile.gold) .. " gold" end
		end,function() ui:Send("Upgrade",id) end)
	end
	if def.Group=="Treino" then
		ui:Text("Improve your training dummy and efficiency.",64)
	end
end
return Page
