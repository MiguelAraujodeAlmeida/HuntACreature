-- Coleção, index, melhorias e loja compartilham dados; o servidor executa as ações.
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Kit = require(script.Parent.MenuKit)
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local W = require(script.Parent.HUDWidgets)
local Button = require(script.Parent.GlossyButton)
local Audio = require(script.Parent.AudioFeedback)
local View = require(script.Parent.CollectionView)
local Preview = require(script.Parent.ToolPlacementPreview)
local Pages = {
	Settings = require(script.Parent.SettingsPage),
	Index = require(script.Parent.IndexPage),
	HunterRank = require(script.Parent.HunterRankPage),
	Criaturas = require(script.Parent.CreaturePage),
	Venda = require(script.Parent.CreaturePage),
	Loja = require(script.Parent.ShopPage),
}
local UI = {}
UI.__index = UI
local function text(parent, message, height)
	local label = W.text(parent, "Texto", message, UDim2.new(1, -16, 0, height or 42), UDim2.fromOffset(8, 0), 18)
	return label
end
local function button(parent, caption, callback, size, position)
	local skin = Button.new(parent, {
		name = caption,
		text = caption,
		textSize = 17,
		size = size or UDim2.new(1, 0, 0, 42),
		position = position or UDim2.new(),
		zIndex = 24,
	})
	skin.Root.Activated:Connect(callback)
	return skin
end
function UI.new(player, remote, hud, controller)
	local self = setmetatable(
		{ player = player, remote = remote, hud = hud, controller = controller, tab = "Criaturas", selected = nil },
		UI
	)
	self.shade = W.frame(hud.Surface, "FundoColecao", UDim2.fromScale(1, 1), UDim2.new(), W.Style.UI.Ink)
	self.shade.BackgroundTransparency, self.shade.ZIndex, self.shade.Visible, self.shade.Active = 0.25, 21, false, true
	local window = Kit.Window(hud.Surface, function()
		hud:CloseSheet()
	end)
	for key, value in pairs(window) do
		self[key] = value
	end
	self.utilities = {}
	self.preview = Preview.new(player)
	self.placementHint = text(hud.Surface, "", 42)
	self.placementHint.AnchorPoint = Vector2.new(0.5, 1)
	self.placementHint.ZIndex, self.placementHint.Visible = 24, false
	self.potion = button(hud.CapturePanel, "Use potion", function()
		self:UsePotion()
	end, UDim2.fromOffset(140, 34), UDim2.new(0, 0, 0, -40))
	self.potion.Root.Visible = false
	self.exit = button(hud.Surface, "Leave training", function()
		remote:FireServer("StopTraining")
	end, UDim2.fromOffset(160, 42), UDim2.new(0.5, -80, 0.55, 0))
	self.exit.Root.Visible = false
	self.cancel = button(hud.CapturePanel, "Release", function()
		remote:FireServer("CancelCapture")
	end, UDim2.fromOffset(112, 30), UDim2.new(1, -112, 0, -34))
	self.connections = {}
	self.lastToolsUpdate = 0
	table.insert(
		self.connections,
		UIS.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.KeyCode == Enum.KeyCode.I then
				self:Open("Index")
			end
		end)
	)
	table.insert(
		self.connections,
		hud.Surface:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			self:Resize()
		end)
	)
	table.insert(
		self.connections,
		player.CharacterAdded:Connect(function()
			self.selected = nil
			self:Close()
		end)
	)
	table.insert(
		self.connections,
		RunService.Heartbeat:Connect(function()
			if os.clock() - self.lastToolsUpdate < 0.1 then
				return
			end
			self.lastToolsUpdate = os.clock()
			self:UpdateTools()
			if
				self.selected
				and not hud.sheetKind
				and not controller.capturing
				and not controller.flying
				and not player:GetAttribute("Treinando")
			then
				local center = UIS.TouchEnabled or UIS:GetLastInputType().Name:find("Gamepad") ~= nil
				self.placementHint.Text =
					self.preview:Update(self.selected, controller:_aimRay(center), self:Unavailable(self.selected))
				self.placementHint.Visible = self.placementHint.Text ~= ""
			else
				self.preview:Hide()
				self.placementHint.Visible = false
			end
			if self.root.Visible and self.data then
				local seconds = math.max(0, self.data.rotation.endsAt - math.floor(workspace:GetServerTimeNow()))
				self.footer.Text = self.tab == "Loja"
						and string.format(
							"Restock %02d:%02d • Gold: %s",
							math.floor(seconds / 60),
							seconds % 60,
							tostring(self.data.profile.gold)
						)
					or (self.data.temporary and "TEMPORARY TEST" or "")
				self:RefreshValues()
				if self.tab == "Loja" and seconds == 0 and os.clock() - (self.stockRequestedAt or 0) > 1 then
					self.stockRequestedAt = os.clock()
					remote:FireServer("RequestProfile")
				end
			end
		end)
	)
	hud.Gui.Destroying:Connect(function()
		for _, connection in ipairs(self.connections) do
			connection:Disconnect()
		end
		self.preview:Destroy()
	end)
	self.preferences = require(script.Parent.LocalPreferences).new(hud.Gui)
	self:Resize()
	return self
end
function UI:Resize()
	local size = self.hud.Surface.AbsoluteSize
	local theme = Kit.Theme.Page(self.tab)
	local nextSize = UDim2.fromOffset(
		math.min(theme.Width, math.max(240, size.X - 24)),
		math.min(theme.Height, math.max(190, size.Y - 24))
	)
	local resized = self.root.Size ~= nextSize
	self.root.Size = nextSize
	local width = size.X < 560 and 54 or (size.Y < 430 and 56 or 68)
	local spacing = width + 6
	local bottom = UIS.TouchEnabled and size.X < 560 and 108 or 12
	self.placementHint.Size = UDim2.new(1, -24, 0, 42)
	self.placementHint.Position = UDim2.new(0.5, 0, 1, -bottom - width - 8)
	self.hud.Slot.Root.Position = UDim2.new(0.5, -spacing * 1.5, 1, -bottom)
	self.hud.Slot.Root.Size = UDim2.fromOffset(width, width)
	if resized and self.root.Visible and self.data then
		self:Render()
	end
end
function UI:Open(tab, group)
	if not Pages[tab or "Criaturas"] then
		return
	end
	if (self.controller.capturing or self.controller.flying) and tab ~= "Settings" then
		self.hud:Notice("Finish the hunt first.")
		return
	end
	if self.player:GetAttribute("Treinando") and tab ~= "Settings" then
		self.hud:Notice("Leave training to open this menu.")
		return
	end
	self.controller:_cancelCharge()
	self.hud:CloseSheet()
	self.zonePage = nil
	self.hud.sheetKind = "collection"
	self.tab = tab or "Criaturas"
	self.renderedTab = nil
	if group ~= self.upgradeGroup then
		self.upgradeId = nil
	end
	self.upgradeGroup = group
	self:Resize()
	self.root.Visible, self.shade.Visible = true, true
	local hud = self.hud
	hud.BagSkin:SetSelected(self.tab == "Criaturas")
	hud.IndexSkin:SetSelected(self.tab == "Index")
	hud.Rank.Skin:SetSelected(self.tab == "HunterRank")
	hud.SettingsSkin:SetSelected(self.tab == "Settings")
	if not self.openScale then
		self.openScale = Instance.new("UIScale")
		self.openScale.Parent = self.root
	end
	if self.openTween then
		self.openTween:Cancel()
	end
	self.openScale.Scale = 0.94
	self.openTween =
		game:GetService("TweenService")
			:Create(self.openScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
	self.openTween:Play()
	Audio.Play("Open")
	self:Render()
end
function UI:Close()
	self.root.Visible, self.shade.Visible = false, false
	self.zonePage = nil
	if self.hud.sheetKind == "collection" then
		self.hud.sheetKind = nil
	end
	self.confirm = nil
	self.hud.BagSkin:SetSelected(false)
	self.hud.IndexSkin:SetSelected(false)
	self.hud.Rank.Skin:SetSelected(false)
	self.hud.SettingsSkin:SetSelected(false)
end
function UI:Send(action, id, extra)
	if not self.data then
		return
	end
	local args = extra or {}
	args.action, args.id, args.revision = action, id, self.data.profile.revision
	self.remote:FireServer("CollectionAction", args)
end
function UI:UsePotion()
	if self.hud.sheetKind then
		return
	end
	local reason = self:Unavailable("Pocao")
	if reason then
		self.hud:Notice(reason)
		return
	end
	self:Send("Use", "Pocao")
end
function UI:Unavailable(id)
	if not self.data or self.player:GetAttribute("ProfileReady") ~= true then
		return "Loading…"
	end
	if (self.data.profile.items[id] or 0) <= 0 then
		return "Out of stock."
	end
	local left = math.ceil((self.player:GetAttribute("Cooldown" .. id) or 0) - workspace:GetServerTimeNow())
	if left > 0 then
		return "Cooldown • " .. left .. " s"
	end
	if id == "Pocao" and not self.controller.capturing then
		return "Use the potion during a capture."
	end
	if id ~= "Pocao" and (self.controller.capturing or self.controller.flying) then
		return "Finish the throw first."
	end
	return nil
end
function UI:Place(ray)
	if not self.selected or not ray then
		return
	end
	local unavailable = self:Unavailable(self.selected)
	if unavailable then
		self.hud:Notice(unavailable)
		return
	end
	local position, reason = self.preview:Resolve(ray)
	if position then
		self:Send("Use", self.selected, { position = position - Vector3.new(0, C.Placement.Height, 0) })
	else
		self.hud:Notice(reason)
	end
end
function UI:UpdateTools()
	local p = self.data and self.data.profile
	self.exit.Root.Visible = self.player:GetAttribute("Treinando") == true
	self.hud.SettingsSkin.Root.Visible = not self.controller.capturing and not self.hud.sheetKind
	self.hud.IndexSkin.Root.Visible = not self.controller.capturing
		and not self.exit.Root.Visible
		and not self.hud.sheetKind
	self.hud.Rank.Root.Visible = self.hud.IndexSkin.Root.Visible
	local left = math.max(0, math.ceil((self.player:GetAttribute("CooldownPocao") or 0) - workspace:GetServerTimeNow()))
	self.potion.Root.Visible = self.controller.capturing
		and self.activeItem == "Pocao"
		and p ~= nil
		and (p.items.Pocao or 0) > 0
	self.potion:SetText(left > 0 and (left .. " s") or "Use potion")
	local throwText = self.selected and "Place" or "Throw"
	if self.hud.ThrowSkin.caption.Text ~= throwText then
		self.hud.ThrowSkin:SetText(throwText)
	end
	if
		self.selected
		and not self.hud.sheetKind
		and not self.controller.capturing
		and not self.controller.flying
		and not self.exit.Root.Visible
	then
		self.hud.ThrowButton.Visible = UIS.TouchEnabled
		self.hud.Reticle.Visible = UIS.TouchEnabled
	else
		self.hud.ThrowButton.Visible = self.controller.equipped
			and UIS.TouchEnabled
			and not self.controller.capturing
			and not self.hud.sheetKind
			and not self.exit.Root.Visible
		self.hud.Reticle.Visible = self.hud.ThrowButton.Visible
	end
end
function UI:SetData(data)
	local changed = not View.Equal(View.Content(self.data, self.tab), View.Content(data, self.tab))
	self.data = data
	if self.preferences then
		self.preferences:Apply(data.profile.settings)
	end
	if self.confirm and not data.profile.creatures[self.confirm] then
		self.confirm = nil
	end
	if self.root.Visible then
		if changed then
			self:Render()
		else
			self:RefreshValues()
		end
	end
end
function UI:RefreshValues()
	if not self.data then
		return
	end
	self.header.Text = self.pageTitle or "COLLECTION"
	for _, refresh in ipairs(self.valueRefreshers or {}) do
		refresh()
	end
end
function UI:Text(message, height)
	return text(self.scroll, message, height)
end
function UI:Tabs(key, options, selected, callback)
	local row = W.frame(self.scroll, key, UDim2.new(1, -2, 0, 46), UDim2.new())
	row.ZIndex, row.LayoutOrder = self.scroll.ZIndex, 0
	for i, option in ipairs(options) do
		local skin = Kit.Action(
			row,
			key .. ":" .. option.id,
			option.name,
			function()
				callback(option.id)
			end,
			UDim2.new(1 / #options, -6, 1, 0),
			UDim2.new((i - 1) / #options, 0, 0, 0),
			option.id == selected and Kit.Theme.Page(self.tab).Accent or Kit.Theme.Surface
		)
		skin.caption.TextTransparency = option.id == selected and 0 or 0.15
	end
	return row
end
function UI:InlineAction(key, caption, callback)
	return self:ActionButton(self.scroll, key, caption, callback, UDim2.new(1, -8, 0, 44), UDim2.new())
end
function UI:NearShop()
	local world = workspace:FindFirstChild("HuntACreature")
	local shop = world and world:FindFirstChild("Hub") and world.Hub:FindFirstChild("LojaDeCaca")
	local root = self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart")
	return root and shop and (root.Position - shop.Position).Magnitude <= C.Shop.Distance
end
function UI:ActionButton(parent, key, caption, callback, size, position)
	local skin = Kit.Action(parent, key, caption, callback, size, position)
	return skin
end
function UI:PurchaseButton(parent, key, label, reason, callback)
	local skin = self:ActionButton(parent, key, label, function()
		local blocked = reason()
		if blocked then
			self.hud:Notice(blocked)
		else
			callback()
		end
	end, UDim2.new(1, -12, 0, 40), UDim2.new(0, 6, 1, -46))
	table.insert(self.valueRefreshers, function()
		local blocked = reason()
		local caption = blocked or label
		if skin.caption.Text ~= caption then
			skin:SetText(caption)
		end
		skin.caption.TextTransparency = blocked and 0.3 or 0
	end)
	return skin
end
function UI:Render()
	local position = self.renderedTab == self.tab and self.scroll.CanvasPosition or Vector2.zero
	self.renderedTab = self.tab
	local selected = GuiService.SelectedObject
	local hadFocus = selected and (selected:IsDescendantOf(self.scroll) or selected:IsDescendantOf(self.detail))
	local focusKey = hadFocus and selected:GetAttribute("FocusKey")
	self.valueRefreshers = {}
	self.pageTitle = "Creatures"
	for _, host in ipairs({ self.scroll, self.detail }) do
		for _, child in ipairs(host:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end
	self.detail.CanvasPosition = Vector2.zero
	local theme = Kit.Theme.Page(self.tab)
	self.headerSurface.BackgroundColor3 = theme.Accent
	self.tag.Text = theme.Tag
	Kit.Layout(self, false)
	if not self.data then
		text(self.scroll, "Loading progress…", 50)
		return
	end
	if Pages[self.tab] then
		Pages[self.tab].Render(self)
	end
	self.scroll.CanvasPosition = position
	self:RefreshValues()
	if hadFocus then
		local restored
		for _, child in ipairs(self.root:GetDescendants()) do
			if focusKey and child:IsA("GuiButton") and child:GetAttribute("FocusKey") == focusKey then
				restored = child
				break
			end
		end
		GuiService.SelectedObject = restored or self.close.Root
	end
end
return UI
