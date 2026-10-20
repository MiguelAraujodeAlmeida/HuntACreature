-- Lightweight Edit-only checks: no Play, no datastore reads/writes.
local cache={}
local function fresh(module)
 if cache[module] then return cache[module] end
 local fn,err=loadstring(module.Source,module:GetFullName());assert(fn,err)
 local env=setmetatable({script=module},{__index=getfenv()})
 env.require=function(target) return typeof(target)=="Instance" and fresh(target) or require(target) end
 setfenv(fn,env);local value=fn();cache[module]=value;return value
end
local Client=game.StarterPlayer.StarterPlayerScripts.HACClient
local Server=game.ServerScriptService.HACServer
local Data=fresh(Server.ProfileData)
local Config=fresh(Server.PersistenceConfig)
local C=fresh(game.ReplicatedStorage.HACShared.GameplayConfig)
local Kit=fresh(Client.MenuKit)
local UI=fresh(Client.CollectionUI)
local results={}
local function check(name,value) assert(value,name);table.insert(results,name) end
local sandbox=Instance.new("ScreenGui");sandbox.Name="HACMenuVerification";sandbox.Parent=game.ServerStorage
local ok,err=xpcall(function()
 check("Studio and live reset namespaces are distinct",Config.StoreName(true)~=Config.StoreName(false))
 check("Both namespaces have the explicit generation",Config.StoreName(true):find(Config.Generation,1,true) and Config.StoreName(false):find(Config.Generation,1,true))
 check("Old v1 names are not active",Config.StoreName(true)~="HAC_Profiles_Studio_v1" and Config.StoreName(false)~="HAC_Profiles_v1")
 check("Datastore name is within limit",#Config.StoreName(true)<=50)
 local p=Data.New()
 check("New profiles have zero progression",p.gold==0 and p.xp==0 and p.strength==0 and next(p.creatures)==nil and next(p.upgrades)==nil and next(p.discoveries)==nil)
 check("Starter equipment retained",p.owned.LacoTreino and p.items.Isca==1 and p.items.Armadilha==1 and p.items.Pocao==1)
 check("Settings start enabled",p.settings.Sound and p.settings.BaseCreatures)
 local window=Kit.Window(sandbox,function() end)
 local ui=setmetatable(window,UI)
 ui.player={};ui.hud={Notice=function() end};ui.data={profile=p,rotation=C.Rotation(os.time())}
 for _,tab in ipairs({"Criaturas","Venda","Index","Loja","Settings"}) do
  ui.tab=tab;ui:Render()
  check("Empty-profile menu builds: "..tab,#ui.scroll:GetChildren()>2 and ui.header.Text~="")
 end
 local item={id="preview-normal",species="Lumito",rarity="Comum",size=1,mutations={},location="bag"}
 check("Capture still records discovery",Data.Capture(p,item))
 check("Favoriting works",Data.Action(p,"SetFavorite",{id=item.id,value=true}))
 check("Server still rejects favorite sale",Data.Action(p,"Sell",{id=item.id})==false and p.creatures[item.id]~=nil)
 for _,tab in ipairs({"Criaturas","Venda","Index"}) do
  ui.tab=tab;ui:Render()
  check("Populated menu and detail build: "..tab,ui.detail.Visible and ui.detail:FindFirstChild("CreatureDetails")~=nil)
 end
 ui.tab="Loja";ui.shopCategory="Lassos";ui:Render()
 check("Lassos show owned equipment",ui.scroll:FindFirstChild("Offer_LacoTreino",true)~=nil)
 ui.tab="Index";ui.indexVariant="Dourado";ui:Render()
 check("Unknown variant remains silhouette",ui.detail.CreatureDetails:FindFirstChild("Name").Text=="???")
 -- Pure composition check at small container width; no device emulation.
 ui.root.Size=UDim2.fromOffset(390,600);ui:Render()
 check("Narrow layout stacks details in main scroll",not ui.detail.Visible and ui.scroll:FindFirstChild("SelectedDetails")~=nil)
end,debug.traceback)
sandbox:Destroy()
if not ok then error(err) end
return results