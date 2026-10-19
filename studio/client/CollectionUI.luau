-- Coleção, index, melhorias e loja compartilham dados; o servidor executa as ações.
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local Audio = require(script.Parent.AudioFeedback)
local View = require(script.Parent.CollectionView)
local Preview = require(script.Parent.ToolPlacementPreview)
local Pages = {
	Index = require(script.Parent.IndexPage),
	Melhorias = require(script.Parent.UpgradePage),
	Loja = require(script.Parent.ShopPage),
}
local UI = {}
UI.__index = UI
local TAB_NAMES = {"Bolsa", "Base"}
local function text(parent, message, height)
	local label = W.text(parent, "Texto", message, UDim2.new(1,-16,0,height or 42), UDim2.fromOffset(8,0),18)
	return label
end
local function button(parent, caption, callback, size, position)
	local skin = Button.new(parent,{name=caption,text=caption,textSize=17,size=size or UDim2.new(1,0,0,42),position=position or UDim2.new(),zIndex=24})
	skin.Root.Activated:Connect(callback)
	return skin
end
function UI.new(player,remote,hud,controller)
	local self=setmetatable({player=player,remote=remote,hud=hud,controller=controller,tab="Bolsa",selected=nil,bagSelected=nil},UI)
	self.shade=W.frame(hud.Surface,"FundoColecao",UDim2.fromScale(1,1),UDim2.new(),W.Style.UI.Ink)
	self.shade.BackgroundTransparency,self.shade.ZIndex,self.shade.Visible,self.shade.Active=0.25,21,false,true
	self.root=W.panel(hud.Surface,"Colecao",UDim2.fromOffset(620,500),UDim2.fromScale(0.5,0.5),W.Style.UI.Cyan)
	self.root.AnchorPoint,self.root.ZIndex,self.root.Visible=Vector2.new(0.5,0.5),22,false
	self.header=text(self.root,"COLEÇÃO",42)
	self.header.Size=UDim2.new(1,-72,0,40)
	self.close=button(self.root,"×",function() hud:CloseSheet() end,UDim2.fromOffset(44,40),UDim2.new(1,-52,0,6))
	self.tabs={}
	for i,name in ipairs(TAB_NAMES) do
		self.tabs[i]=button(self.root,name,function() self.tab=name; self.confirm=nil; self:Render() end,UDim2.new(1/#TAB_NAMES,-6,0,38),UDim2.new((i-1)/#TAB_NAMES,3,0,52))
	end
	local scroll=Instance.new("ScrollingFrame")
	scroll.Name,scroll.Size,scroll.Position="Lista",UDim2.new(1,-24,1,-144),UDim2.fromOffset(12,98)
	scroll.BackgroundTransparency,scroll.BorderSizePixel,scroll.ScrollBarThickness=1,0,5
	scroll.AutomaticCanvasSize,scroll.CanvasSize,scroll.Parent=Enum.AutomaticSize.Y,UDim2.new(),self.root
	local list=Instance.new("UIListLayout")
	list.Padding,list.SortOrder,list.Parent=UDim.new(0,8),Enum.SortOrder.LayoutOrder,scroll
	self.scroll=scroll
	self.footer=text(self.root,"Carregando progresso…",30)
	self.footer.Position=UDim2.new(0,8,1,-35)
	self.utilities={}
	self.preview=Preview.new(player)
	self.placementHint=text(hud.Surface,"",42)
	self.placementHint.AnchorPoint=Vector2.new(0.5,1)
	self.placementHint.ZIndex,self.placementHint.Visible=24,false
	for i,id in ipairs({"Isca","Armadilha","Pocao"}) do
		self.utilities[i]=button(hud.Surface,C.Items[id].Name,function() self:Select(id) end,UDim2.fromOffset(60,60))
	end
	self.exit=button(hud.Surface,"Sair do treino",function() remote:FireServer("StopTraining") end,UDim2.fromOffset(160,42),UDim2.new(0.5,-80,0.55,0))
	self.exit.Root.Visible=false
	self.cancel=button(hud.CapturePanel,"Soltar laço",function() remote:FireServer("CancelCapture") end,UDim2.fromOffset(112,30),UDim2.new(1,-112,0,-34))
	self.connections={}
	self.lastToolsUpdate=0
	table.insert(self.connections,UIS.InputBegan:Connect(function(input,processed)
		if processed then return end
		if input.KeyCode==Enum.KeyCode.I then self:Open("Index")
		elseif input.KeyCode==Enum.KeyCode.V then self:Open("Melhorias","Velocidade")
		elseif input.KeyCode==Enum.KeyCode.Two then self:Select("Isca")
		elseif input.KeyCode==Enum.KeyCode.Three then self:Select("Armadilha")
		elseif input.KeyCode==Enum.KeyCode.Four or input.KeyCode==Enum.KeyCode.ButtonX then self:Select("Pocao")
		elseif input.KeyCode==Enum.KeyCode.One then self.selected=nil
		elseif input.KeyCode==Enum.KeyCode.ButtonL1 then self:Select("Isca")
		elseif input.KeyCode==Enum.KeyCode.ButtonR1 then self:Select("Armadilha") end
	end))
	table.insert(self.connections,hud.Surface:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:Resize() end))
	table.insert(self.connections,player.CharacterAdded:Connect(function() self.selected=nil; self:Close() end))
	table.insert(self.connections,RunService.Heartbeat:Connect(function()
		if os.clock()-self.lastToolsUpdate<0.1 then return end
		self.lastToolsUpdate=os.clock()
		self:UpdateTools()
		if self.selected and not hud.sheetKind and not controller.capturing and not controller.flying and not player:GetAttribute("Treinando") then
			local center=UIS.TouchEnabled or UIS:GetLastInputType().Name:find("Gamepad")~=nil
			self.placementHint.Text=C.Items[self.selected].Name .. " • " .. self.preview:Update(self.selected,controller:_aimRay(center),self:Unavailable(self.selected))
			self.placementHint.Visible=true
		else self.preview:Hide(); self.placementHint.Visible=false end
		if self.root.Visible and self.data then
			local seconds=math.max(0,self.data.rotation.endsAt-math.floor(workspace:GetServerTimeNow()))
			self.footer.Text=self.tab=="Loja" and string.format("Reposição %02d:%02d • Ouro: %s",math.floor(seconds/60),seconds%60,tostring(self.data.profile.gold))
				or (self.data.temporary and "TESTE TEMPORÁRIO • " or "") .. "Ouro: " .. self.data.profile.gold
			self:RefreshValues()
			if self.tab=="Loja" and seconds==0 and os.clock()-(self.stockRequestedAt or 0)>1 then
				self.stockRequestedAt=os.clock(); remote:FireServer("RequestProfile")
			end
		end
	end))
	hud.Gui.Destroying:Connect(function()
		for _,connection in ipairs(self.connections) do connection:Disconnect() end
		self.preview:Destroy()
	end)
	self:Resize()
	return self
end
function UI:Resize()
	local size=self.hud.Surface.AbsoluteSize
	local nextSize=UDim2.fromOffset(math.min(650,math.max(240,size.X-24)),math.min(530,math.max(190,size.Y-24)))
	local resized=self.root.Size~=nextSize
	self.root.Size=nextSize
	local width=size.X<560 and 54 or (size.Y<430 and 56 or 68)
	local spacing=width+6
	local bottom=UIS.TouchEnabled and size.X<560 and 108 or 12
	self.placementHint.Size=UDim2.new(1,-24,0,42)
	self.placementHint.Position=UDim2.new(0.5,0,1,-bottom-width-8)
	self.hud.Slot.Root.Position=UDim2.new(0.5,-spacing*1.5,1,-bottom)
	self.hud.Slot.Root.Size=UDim2.fromOffset(width,width)
	for i,skin in ipairs(self.utilities) do
		skin.Root.AnchorPoint=Vector2.new(0.5,1)
		skin.Root.Size=UDim2.fromOffset(width,width)
		skin.Root.Position=UDim2.new(0.5,spacing*(i-1.5),1,-bottom)
	end
	for _,skin in ipairs(self.tabs) do skin.caption:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize=size.X<420 and 12 or 17 end
	if resized and self.root.Visible and self.data then self:Render() end
end
function UI:Open(tab,group)
	if self.controller.capturing or self.controller.flying then self.hud:Notice("Conclua a caça primeiro."); return end
	if self.player:GetAttribute("Treinando") then self.hud:Notice("Saia do treino para abrir o painel."); return end
	self.controller:_cancelCharge()
	self.hud:CloseSheet()
	self.hud.sheetKind="collection"
	self.tab=tab or "Bolsa"
	self.renderedTab=nil
	if group~=self.upgradeGroup then self.upgradeId=nil end
	self.upgradeGroup=group
	self.root.Visible,self.shade.Visible=true,true
	Audio.Play("Open")
	self:Render()
end
function UI:Close()
	self.root.Visible,self.shade.Visible=false,false
	self.confirm=nil
end
function UI:Send(action,id,extra)
	if not self.data then return end
	local args=extra or {}
	args.action,args.id,args.revision=action,id,self.data.profile.revision
	self.remote:FireServer("CollectionAction",args)
end
function UI:Select(id)
	if self.hud.sheetKind or self.player:GetAttribute("Treinando") or not self.data then return end
	if self.selected==id then self.selected=nil; self:UpdateTools(); return end
	local reason=self:Unavailable(id)
	if reason then self.hud:Notice(reason); return end
	if id=="Pocao" then self:Send("Use",id); return end
	if self.controller.capturing or self.controller.flying then return end
	self.controller:_cancelCharge()
	self.selected=self.selected==id and nil or id
	self.hud:Notice(self.selected and "Mire no chão e use Posicionar (clique / R2)." or "Laço selecionado.")
	self:UpdateTools()
end
function UI:Unavailable(id)
	if not self.data or self.player:GetAttribute("ProfileReady")~=true then return "Aguarde o progresso carregar." end
	if (self.data.profile.items[id] or 0)<=0 then return "Sem unidades • compre na loja." end
	local left=math.ceil((self.player:GetAttribute("Cooldown" .. id) or 0)-workspace:GetServerTimeNow())
	if left>0 then return "Recarregando • " .. left .. " s" end
	if id=="Pocao" and not self.controller.capturing then return "Use a poção durante uma captura." end
	if id~="Pocao" and (self.controller.capturing or self.controller.flying) then return "Conclua o lançamento primeiro." end
	return nil
end
function UI:Place(ray)
	if not self.selected or not ray then return end
	local unavailable=self:Unavailable(self.selected)
	if unavailable then self.hud:Notice(unavailable); return end
	local position,reason=self.preview:Resolve(ray)
	if position then
		self:Send("Use",self.selected,{position=position-Vector3.new(0,C.Placement.Height,0)})
	else self.hud:Notice(reason) end
end
function UI:UpdateTools()
	local p=self.data and self.data.profile
	self.exit.Root.Visible=self.player:GetAttribute("Treinando")==true
	self.hud.IndexSkin.Root.Visible=not self.controller.capturing and not self.exit.Root.Visible and not self.hud.sheetKind
	self.hud.SpeedSkin.Root.Visible=self.hud.IndexSkin.Root.Visible
	for i,id in ipairs({"Isca","Armadilha","Pocao"}) do
		local left=math.max(0,math.ceil((self.player:GetAttribute("Cooldown" .. id) or 0)-workspace:GetServerTimeNow()))
		local caption=(self.selected==id and "✓ " or "") .. C.Items[id].Name .. "\n×" .. (p and p.items[id] or 0) .. (left>0 and " • " .. left .. "s" or "")
		if self.utilities[i].caption.Text~=caption then self.utilities[i]:SetText(caption) end
		self.utilities[i].caption.TextTransparency=self:Unavailable(id) and 0.35 or 0
		if self.utilities[i].selected~=(self.selected==id) then self.utilities[i]:SetSelected(self.selected==id) end
		self.utilities[i].Root.Visible=not self.exit.Root.Visible and not self.hud.sheetKind
	end
	local throwText=self.selected and "Posicionar" or "Lançar"
	if self.hud.ThrowSkin.caption.Text~=throwText then self.hud.ThrowSkin:SetText(throwText) end
	if self.selected and not self.hud.sheetKind and not self.controller.capturing and not self.controller.flying and not self.exit.Root.Visible then
		self.hud.ThrowButton.Visible=UIS.TouchEnabled
		self.hud.Reticle.Visible=UIS.TouchEnabled
	else
		self.hud.ThrowButton.Visible=self.controller.equipped and UIS.TouchEnabled and not self.controller.capturing and not self.hud.sheetKind and not self.exit.Root.Visible
		self.hud.Reticle.Visible=self.hud.ThrowButton.Visible
	end
end
function UI:SetData(data)
	local changed=not View.Equal(View.Content(self.data,self.tab),View.Content(data,self.tab))
	self.data=data
	local chosen=self.bagSelected and data.profile.creatures[self.bagSelected]
	if not chosen or chosen.location~="bag" then self.bagSelected=nil end
	if self.confirm and not data.profile.creatures[self.confirm] then self.confirm=nil end
	if self.root.Visible then
		if changed then self:Render() else self:RefreshValues() end
	end
end
function UI:RefreshValues()
	if not self.data then return end
	self.header.Text=self.pageTitle or "COLEÇÃO"
	for _,refresh in ipairs(self.valueRefreshers or {}) do refresh() end
end
function UI:Text(message,height)
	return text(self.scroll,message,height)
end
function UI:InlineAction(key,caption,callback)
	return self:ActionButton(self.scroll,key,caption,callback,UDim2.new(1,-8,0,44),UDim2.new())
end
function UI:NearShop()
	local world=workspace:FindFirstChild("HuntACreature")
	local shop=world and world:FindFirstChild("Hub") and world.Hub:FindFirstChild("LojaDeCaca")
	local root=self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart")
	return root and shop and (root.Position-shop.Position).Magnitude<=C.Shop.Distance
end
function UI:UpgradeUnavailable(id)
	local def=C.Upgrades[id]
	local group=def and C.UpgradeGroups[def.Group]
	if not group then return "Melhoria indisponível" end
	local character=self.player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health<=0 then return "Aguarde seu caçador retornar" end
	if group.Anchor then
		local world=workspace:FindFirstChild("HuntACreature")
		local bases=world and world:FindFirstChild("Hub") and world.Hub:FindFirstChild("Bases")
		local base=bases and bases:FindFirstChild("Base" .. tostring(self.player:GetAttribute("BaseIndex")))
		local anchor=base and base:FindFirstChild(group.Anchor)
		if not anchor or (root.Position-anchor.Position).Magnitude>group.Distance then return group.Hint end
	end
end
function UI:ActionButton(parent,key,caption,callback,size,position)
	local skin=button(parent,caption,callback,size,position)
	skin.Root:SetAttribute("FocusKey",key)
	return skin
end
function UI:PurchaseButton(parent,key,label,reason,callback)
	local skin=self:ActionButton(parent,key,label,function()
		local blocked=reason()
		if blocked then self.hud:Notice(blocked) else callback() end
	end,UDim2.new(1,-12,0,40),UDim2.new(0,6,1,-46))
	table.insert(self.valueRefreshers,function()
		local blocked=reason()
		local caption=blocked or label
		if skin.caption.Text~=caption then skin:SetText(caption) end
		skin.caption.TextTransparency=blocked and 0.3 or 0
	end)
	return skin
end
function UI:Card(title,description,height)
	local measured=TextService:GetTextSize(description,16,W.Style.DisplayFont,Vector2.new(math.max(120,self.root.Size.X.Offset-56),10000))
	height=math.max(height or 160,math.ceil(measured.Y)+100)
	local card=W.panel(self.scroll,"Cartao",UDim2.new(1,-8,0,height),UDim2.new(),W.Style.UI.Cyan)
	local heading=text(card,title,38)
	heading.TextScaled=true
	local limit=Instance.new("UITextSizeConstraint")
	limit.MinTextSize,limit.MaxTextSize,limit.Parent=12,20,heading
	local body=text(card,description,height-94)
	body.Name="Descricao"
	body.Position,body.TextSize=UDim2.fromOffset(8,40),16
	body.TextYAlignment=Enum.TextYAlignment.Top
	return card
end
function UI:Render()
	local position=self.renderedTab==self.tab and self.scroll.CanvasPosition or Vector2.zero
	self.renderedTab=self.tab
	local selected=GuiService.SelectedObject
	local hadFocus=selected and selected:IsDescendantOf(self.scroll)
	local focusKey=hadFocus and selected:GetAttribute("FocusKey")
	self.valueRefreshers={}
	self.pageTitle="Coleção"
	for _,child in ipairs(self.scroll:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
	if not self.data then text(self.scroll,"Carregando progresso…",50); return end
	local p=self.data.profile
	local inventory=self.tab=="Bolsa" or self.tab=="Base"
	for i,skin in ipairs(self.tabs) do skin.Root.Visible=inventory; skin:SetSelected(TAB_NAMES[i]==self.tab) end
	local top=inventory and 98 or 54
	self.scroll.Position=UDim2.fromOffset(12,top)
	self.scroll.Size=UDim2.new(1,-24,1,-top-46)
	if self.tab=="Bolsa" or self.tab=="Base" then
		local location=self.tab=="Bolsa" and "bag" or "base"
		local items={}
		for _,item in pairs(p.creatures) do if item.location==location then table.insert(items,item) end end
		table.sort(items,function(a,b) return (a.slot or 0)==(b.slot or 0) and a.id<b.id or (a.slot or 0)<(b.slot or 0) end)
		text(self.scroll,self.tab .. ": " .. #items .. "/" .. C.Stat(p,self.tab=="Bolsa" and "Bolsa" or "Base"),32)
		self:InlineAction("OpenUpgrade:" .. self.tab,"Melhorar " .. self.tab:lower(),function() self:Open("Melhorias",self.tab) end)
		if self.bagSelected and location=="base" and p.creatures[self.bagSelected] then
			text(self.scroll,"Escolha quem sai da base para trocar com: " .. C.Name(p.creatures[self.bagSelected]),48)
		end
		if #items==0 then text(self.scroll,location=="bag" and "Capture uma criatura na ilha para começar." or "Selecione uma criatura na bolsa e instale aqui.",64) end
		for _,item in ipairs(items) do
			local card=self:Card(C.Name(item),string.format("%s • tamanho %.2f×\nRenda %d / %s s • venda %d ouro",item.rarity,item.size,C.Value(item,"Income"),tostring(C.IncomeSeconds),C.Value(item,"Sale")))
			self:ActionButton(card,"Sell:" .. item.id,self.confirm==item.id and "Confirmar venda" or "Vender",function()
				if self.confirm==item.id then self:Send("Sell",item.id); self.confirm=nil; self:Render()
				else self.confirm=item.id; self:Render() end
			end,UDim2.new(0.34,-8,0,40),UDim2.new(0,6,1,-46))
			if location=="bag" then
				self:ActionButton(card,"Install:" .. item.id,"Instalar",function() self:Send("Install",item.id) end,UDim2.new(0.32,-6,0,40),UDim2.new(0.34,0,1,-46))
				self:ActionButton(card,"Swap:" .. item.id,"Trocar",function() self.bagSelected=item.id; self.confirm=nil; self.tab="Base"; self:Render() end,UDim2.new(0.34,-6,0,40),UDim2.new(0.66,0,1,-46))
			else
				self:ActionButton(card,"Swap:" .. item.id,"Trocar com bolsa",function()
					if self.bagSelected then self:Send("Swap",self.bagSelected,{other=item.id})
					else self.hud:Notice("Na aba Bolsa, escolha Trocar em uma criatura.") end
				end,UDim2.new(0.66,-12,0,40),UDim2.new(0.34,6,1,-46))
			end
		end
	elseif Pages[self.tab] then
		Pages[self.tab].Render(self)
	end
	self.scroll.CanvasPosition=position
	self:RefreshValues()
	if hadFocus then
		local restored
		for _,child in ipairs(self.scroll:GetDescendants()) do
			if focusKey and child:IsA("GuiButton") and child:GetAttribute("FocusKey")==focusKey then restored=child; break end
		end
		local index=table.find(TAB_NAMES,self.tab) or 1
		GuiService.SelectedObject=restored or (inventory and self.tabs[index].Root or self.close.Root)
	end
end
return UI
