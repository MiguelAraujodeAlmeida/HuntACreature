-- Verificação isolada em Edit: sem Players reais, RemoteEvent ou DataStore.
local root=Instance.new("Folder")
root.Name="HACInteractionsQA"
root.Parent=workspace
local module=game.StarterPlayer.StarterPlayerScripts.HACClient.UpgradeBoards:Clone()
module.Name="UpgradeBoardsQA"
module.Parent=game.StarterPlayer.StarterPlayerScripts.HACClient
local boards
local results={}
local function check(name, condition)
	assert(condition,name)
	table.insert(results,name)
end
local ok,err=xpcall(function()
	local bases=Instance.new("Folder"); bases.Parent=root
	local gui=Instance.new("Folder"); gui.Parent=root
	local character=Instance.new("Model"); character.Parent=root
	local hrp=Instance.new("Part"); hrp.Name="HumanoidRootPart"; hrp.Anchored=true; hrp.Position=Vector3.zero; hrp.Parent=character
	local attrs={BaseIndex=1}
	local player={Character=character}
	function player:GetAttribute(name) return attrs[name] end
	function player:FindFirstChildOfClass(name) return name=="PlayerGui" and gui or nil end
	local sent={}
	local ui={hud={Gui=gui},controller={},remote={}}
	function ui:Send(action,id) table.insert(sent,{action,id}) end
	function ui.remote:FireServer(action) table.insert(sent,{action}) end
	local BoardClass=require(module)
	boards=BoardClass.new(player,ui,bases)
	check("base ausente não bloqueia inicialização",next(boards.panels)==nil)
	local profile=require(game.ServerScriptService.HACServer.ProfileData).New()
	profile.gold=500
	boards:Update(profile)
	local base=Instance.new("Model"); base.Name="Base1"; base.Parent=bases
	boards:_sync()
	check("base sem pasta aguarda sem erro",next(boards.panels)==nil)
	local folder=Instance.new("Folder"); folder.Name="PlacasMelhorias"; folder.Parent=base
	local plate=Instance.new("Part"); plate.Name="Base"; plate.Anchored=true; plate.Position=Vector3.zero; plate.Parent=folder
	boards:_sync()
	check("peça sem atributo aguarda sem erro",next(boards.panels)==nil)
	plate:SetAttribute("UpgradeIds","Base,Bolsa,Velocidade")
	boards:_sync()
	local panel=boards.panels[plate]
	check("atributo tardio cria frente e verso",panel and #panel.faces==2)
	check("perfil anterior preenche nível e preço",panel.faces[1].rows[1].skin.caption.Text=="$ 40")
	check("botão de compra disponível",panel.faces[1].rows[1].skin.Root.Active)
	local before=#gui:GetChildren(); boards:_sync()
	check("passos repetidos não duplicam interfaces",#gui:GetChildren()==before)
	boards:_activate(panel,"Base")
	check("compra envia Upgrade e ID corretos",#sent==1 and sent[1][1]=="Upgrade" and sent[1][2]=="Base")
	boards:_activate(panel,"Base")
	check("clique duplo bloqueado",#sent==1)
	boards.nextClick=0; ui.controller.capturing=true
	boards:_activate(panel,"Base")
	check("captura bloqueia compra",#sent==1)
	ui.controller.capturing=false
	hrp.Position=Vector3.new(20,0,0); boards:_sync()
	check("placa permanece desenhada fora do alcance de compra",panel.faces[1].gui.Enabled and not panel.faces[1].rows[1].skin.Root.Active)
	boards:_activate(panel,"Base"); check("distância bloqueia envio",#sent==1)
	hrp.Position=Vector3.zero
	local train=plate:Clone(); train.Name="Treino"; train:SetAttribute("UpgradeIds","Treino,Multiplicador"); train.Parent=folder
	boards:_sync()
	local training=boards.panels[train]
	check("treino tem botão nas duas faces",training and training.faces[1].train and training.faces[2].train)
	boards:_activate(training,"Treinar")
	check("botão de treino envia comando correto",#sent==2 and sent[2][1]=="ToggleTraining")
	plate:Destroy(); boards:_sync()
	check("peça removida limpa interfaces",boards.panels[plate]==nil)
	local replacement=train:Clone(); replacement.Name="Base"; replacement:SetAttribute("UpgradeIds","Base,Bolsa,Velocidade"); replacement.Parent=folder
	boards:_sync()
	check("peça recriada recebe interface",boards.panels[replacement]~=nil)
	attrs.BaseIndex=2; boards:_sync()
	check("mudança de dono remove acesso antigo",next(boards.panels)==nil)
	boards:Destroy()
	check("limpeza final sem interfaces restantes",#gui:GetChildren()==0)
end,debug.traceback)
if boards then boards:Destroy() end
root:Destroy(); module:Destroy()
return game.HttpService:JSONEncode({passed=ok,checks=results,error=not ok and err or nil})
